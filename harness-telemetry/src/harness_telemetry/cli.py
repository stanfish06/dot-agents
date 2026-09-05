from __future__ import annotations

from datetime import date, datetime
from pathlib import Path
from typing import Annotated

import duckdb
import typer
from rich.console import Console
from rich.table import Table

from . import parsers, store
from .models import Harness

app = typer.Typer(no_args_is_help=True, add_completion=False, help=__doc__)
report = typer.Typer(no_args_is_help=True, help="Query the ingested telemetry.")
app.add_typer(report, name="report")
console = Console()

DbOpt = Annotated[Path | None, typer.Option("--db", help="DuckDB file (default: XDG data dir).")]
HarnessOpt = Annotated[list[Harness] | None, typer.Option("--harness", "-H")]
DaysOpt = Annotated[int | None, typer.Option("--days", "-d", help="Only the last N days.")]
ProjectOpt = Annotated[str | None, typer.Option("--project", "-p", help="Substring of cwd.")]
LimitOpt = Annotated[int, typer.Option("--limit", "-n")]


def _db(db: Path | None) -> Path:
    return db or store.default_db_path()


def _print(cur: duckdb.DuckDBPyConnection, title: str | None = None) -> None:
    rows = cur.fetchall()
    table = Table(title=title, show_lines=False)
    for desc in cur.description or []:
        table.add_column(desc[0])
    for row in rows:
        table.add_row(*[_fmt(v) for v in row])
    console.print(table)


def _fmt(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, datetime):
        return value.astimezone().strftime("%Y-%m-%d %H:%M")
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, float):
        return f"{value:.1f}"
    return str(value)


@app.command()
def paths(db: DbOpt = None) -> None:
    """Show the database path and the session stores that ingest scans."""
    console.print(f"db: {_db(db)}")
    for harness, root in parsers.default_roots().items():
        state = "ok" if root.exists() else "missing"
        console.print(f"{harness.value:9} {root}  \\[{state}]")


@app.command()
def ingest(
    db: DbOpt = None,
    harness: HarnessOpt = None,
    force: Annotated[bool, typer.Option(help="Re-parse unchanged files too.")] = False,
) -> None:
    """Parse harness session stores into the DuckDB file. Re-runs only pick up changed files."""
    roots = parsers.default_roots()
    if harness:
        roots = {h: p for h, p in roots.items() if h in harness}
    con = store.connect(_db(db))
    counts: dict[Harness, list[int]] = {h: [0, 0, 0, 0] for h in roots}
    for h, path in parsers.discover(roots):
        c = counts[h]
        c[0] += 1
        if not force and store.source_unchanged(con, path):
            continue
        try:
            result = parsers.parse(h, path)
        except Exception as exc:
            console.print(f"[red]skip[/] {path}: {exc}")
            continue
        store.replace_source(con, h, path, result)
        c[1] += 1
        c[2] += len(result.sessions)
        c[3] += len(result.events)
    con.close()
    table = Table("harness", "files", "parsed", "sessions", "events", title="ingest")
    for h, c in counts.items():
        table.add_row(h.value, *map(str, c))
    console.print(table)


def _where(harness: HarnessOpt, days: DaysOpt, project: ProjectOpt) -> tuple[str, list[object]]:
    clauses, params = [], []
    if harness:
        clauses.append(f"e.harness in ({', '.join('?' * len(harness))})")
        params.extend(h.value for h in harness)
    if days:
        clauses.append("e.ts >= now() - to_days(?)")
        params.append(days)
    if project:
        clauses.append("s.cwd ilike ?")
        params.append(f"%{project}%")
    return (" where " + " and ".join(clauses)) if clauses else "", params


EVENTS_WITH_CWD = "select e.*, s.cwd from events e left join sessions s using (harness, session_id)"


@report.command()
def skills(
    db: DbOpt = None,
    harness: HarnessOpt = None,
    days: DaysOpt = None,
    project: ProjectOpt = None,
    limit: LimitOpt = 30,
) -> None:
    """Skill usage. detail=invoke is a native skill tool; detail=read is a SKILL.md file read."""
    where, params = _where(harness, days, project)
    con = store.connect(_db(db), read_only=True)
    _print(
        con.execute(
            f"""
            with ev as ({EVENTS_WITH_CWD}{where})
            select name as skill, count(*) as calls, count(distinct session_id) as sessions,
                   string_agg(distinct harness, ',' order by harness) as harnesses,
                   string_agg(distinct detail, ',') as how, max(ts) as last_used
            from ev where kind = 'skill'
            group by name order by calls desc, skill limit ?
            """,
            [*params, limit],
        ),
        "skills",
    )


@report.command()
def tools(
    db: DbOpt = None,
    harness: HarnessOpt = None,
    days: DaysOpt = None,
    project: ProjectOpt = None,
    limit: LimitOpt = 40,
) -> None:
    """Tool call counts per harness."""
    where, params = _where(harness, days, project)
    con = store.connect(_db(db), read_only=True)
    _print(
        con.execute(
            f"""
            with ev as ({EVENTS_WITH_CWD}{where})
            select harness, name as tool, count(*) as calls,
                   count(distinct session_id) as sessions, max(ts) as last_used
            from ev where kind = 'tool'
            group by harness, name order by calls desc, harness, tool limit ?
            """,
            [*params, limit],
        ),
        "tools",
    )


@report.command()
def sessions(
    db: DbOpt = None,
    harness: HarnessOpt = None,
    days: DaysOpt = None,
    project: ProjectOpt = None,
    limit: LimitOpt = 25,
) -> None:
    """Recent sessions with their prompt, tool and skill counts."""
    where, params = _where(harness, days, project)
    where = where.replace("e.harness", "s.harness").replace("e.ts", "s.started_at")
    con = store.connect(_db(db), read_only=True)
    _print(
        con.execute(
            f"""
            select s.harness, left(s.session_id, 8) as session, s.started_at,
                   regexp_extract(s.cwd, '[^/]+$') as project, s.model,
                   count(*) filter (e.kind = 'prompt') as prompts,
                   count(*) filter (e.kind = 'tool') as tools,
                   string_agg(distinct e.name, ',') filter (e.kind = 'skill') as skills,
                   s.input_tokens + s.cache_read_tokens as input_tok, s.output_tokens as output_tok
            from sessions s left join events e using (harness, session_id)
            {where}
            group by all order by s.started_at desc nulls last limit ?
            """,
            [*params, limit],
        ),
        "sessions",
    )


@report.command()
def summary(db: DbOpt = None, days: DaysOpt = None, project: ProjectOpt = None) -> None:
    """One row per harness: sessions, prompts, tool calls, skill calls, tokens."""
    where, params = _where(None, days, project)
    con = store.connect(_db(db), read_only=True)
    _print(
        con.execute(
            f"""
            with ev as ({EVENTS_WITH_CWD}{where}),
            agg as (
                select harness, count(distinct session_id) as sessions,
                       count(*) filter (kind = 'prompt') as prompts,
                       count(*) filter (kind = 'tool') as tool_calls,
                       count(*) filter (kind = 'skill') as skill_calls,
                       count(distinct name) filter (kind = 'skill') as distinct_skills,
                       min(ts)::date as first, max(ts)::date as last
                from ev group by harness),
            tok as (
                select s.harness, sum(s.input_tokens + s.cache_read_tokens) as input_tok,
                       sum(s.output_tokens) as output_tok
                from sessions s
                join (select distinct harness, session_id from ev) x using (harness, session_id)
                group by s.harness)
            select agg.*, tok.input_tok, tok.output_tok
            from agg left join tok using (harness) order by sessions desc
            """,
            params,
        ),
        "summary",
    )


@app.command()
def sql(query: str, db: DbOpt = None) -> None:
    """Run a SQL query against tables sessions, events, sources."""
    con = store.connect(_db(db), read_only=True)
    _print(con.execute(query))


if __name__ == "__main__":
    app()

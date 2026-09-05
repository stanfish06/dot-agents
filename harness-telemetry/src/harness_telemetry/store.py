from __future__ import annotations

import os
from datetime import UTC, datetime
from pathlib import Path

import duckdb

from .models import Harness, ParseResult

SCHEMA = """
create table if not exists sources (
    path varchar primary key, harness varchar, mtime_ns bigint, size bigint, ingested_at timestamptz
);
create table if not exists sessions (
    harness varchar, session_id varchar, source_path varchar,
    started_at timestamptz, ended_at timestamptz, cwd varchar, model varchar,
    client_version varchar,
    input_tokens bigint, output_tokens bigint, cache_read_tokens bigint
);
create table if not exists events (
    harness varchar, session_id varchar, ts timestamptz, kind varchar, name varchar,
    detail varchar, call_id varchar, source_path varchar
);
"""

SESSION_COLS = (
    "harness",
    "session_id",
    "source_path",
    "started_at",
    "ended_at",
    "cwd",
    "model",
    "client_version",
    "input_tokens",
    "output_tokens",
    "cache_read_tokens",
)
EVENT_COLS = ("harness", "session_id", "ts", "kind", "name", "detail", "call_id", "source_path")


def _insert(table: str, cols: tuple[str, ...]) -> str:
    return f"insert into {table} ({', '.join(cols)}) values ({', '.join('?' * len(cols))})"


def default_db_path() -> Path:
    if env := os.environ.get("DOT_AGENTS_TELEMETRY_DB"):
        return Path(env)
    data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    return data / "dot-agents" / "telemetry.duckdb"


def connect(path: Path, *, read_only: bool = False) -> duckdb.DuckDBPyConnection:
    path.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(path), read_only=read_only)
    if not read_only:
        con.execute(SCHEMA)
    return con


def source_unchanged(con: duckdb.DuckDBPyConnection, path: Path) -> bool:
    st = path.stat()
    row = con.execute("select mtime_ns, size from sources where path = ?", [str(path)]).fetchone()
    return row is not None and row[0] == st.st_mtime_ns and row[1] == st.st_size


def replace_source(
    con: duckdb.DuckDBPyConnection, harness: Harness, path: Path, result: ParseResult
) -> None:
    st = path.stat()
    key = str(path)
    con.begin()
    try:
        con.execute("delete from sessions where source_path = ?", [key])
        con.execute("delete from events where source_path = ?", [key])
        if result.sessions:
            con.executemany(
                _insert("sessions", SESSION_COLS),
                [tuple(getattr(s, c) for c in SESSION_COLS) for s in result.sessions],
            )
        if result.events:
            con.executemany(
                _insert("events", EVENT_COLS),
                [tuple(getattr(e, c) for c in EVENT_COLS) for e in result.events],
            )
        con.execute(
            "insert or replace into sources values (?, ?, ?, ?, ?)",
            [key, harness.value, st.st_mtime_ns, st.st_size, datetime.now(tz=UTC)],
        )
        con.commit()
    except Exception:
        con.rollback()
        raise

from __future__ import annotations

import json
import os
import re
import sqlite3
from collections.abc import Iterator
from pathlib import Path
from typing import Any

from .models import Event, EventKind, Harness, ParseResult, Session, parse_ts

SKILL_MD_RE = re.compile(r"/([A-Za-z0-9][A-Za-z0-9_.-]*)/SKILL\.md")
DETAIL_LEN = 200


def _summarize(value: Any) -> str | None:  # noqa: ANN401
    if value is None:
        return None
    if isinstance(value, dict):
        for key in ("command", "cmd", "skill", "name", "path", "file_path", "pattern", "query"):
            if isinstance(value.get(key), str):
                return value[key][:DETAIL_LEN]
        value = json.dumps(value, ensure_ascii=False)
    return str(value)[:DETAIL_LEN]


def _skill_reads(text: str) -> set[str]:
    return set(SKILL_MD_RE.findall(text))


def _jsonl(path: Path) -> Iterator[dict[str, Any]]:
    with path.open(encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(obj, dict):
                yield obj


class _Collector:
    def __init__(self, harness: Harness, source_path: Path) -> None:
        self.harness = harness
        self.source = str(source_path)
        self.sessions: dict[str, Session] = {}
        self.events: list[Event] = []

    def session(self, sid: str) -> Session:
        if sid not in self.sessions:
            self.sessions[sid] = Session(
                harness=self.harness, session_id=sid, source_path=self.source
            )
        return self.sessions[sid]

    def event(self, sid: str, ts: Any, kind: EventKind, name: str, **kw: Any) -> None:  # noqa: ANN401
        when = parse_ts(ts)
        self.session(sid).touch(when)
        self.events.append(
            Event(
                harness=self.harness,
                session_id=sid,
                ts=when,
                kind=kind,
                name=name,
                source_path=self.source,
                **kw,
            )
        )

    def skill_reads(self, sid: str, ts: Any, text: str) -> None:  # noqa: ANN401
        for name in sorted(_skill_reads(text)):
            self.event(sid, ts, EventKind.skill, name, detail="read")

    def result(self) -> ParseResult:
        return ParseResult(sessions=list(self.sessions.values()), events=self.events)


# --- Claude Code: ~/.claude/projects/<slug>/<session>.jsonl ------------------


def parse_claude(path: Path) -> ParseResult:
    col = _Collector(Harness.claude, path)
    seen_msgs: set[str] = set()
    for obj in _jsonl(path):
        sid = obj.get("sessionId") or path.stem
        kind = obj.get("type")
        if kind not in ("assistant", "user"):
            continue
        sess = col.session(sid)
        ts = obj.get("timestamp")
        sess.touch(parse_ts(ts))
        if obj.get("cwd"):
            sess.cwd = obj["cwd"]
        if obj.get("version"):
            sess.client_version = obj["version"]
        msg = obj.get("message") or {}
        content = msg.get("content")
        if kind == "assistant":
            if msg.get("model"):
                sess.model = msg["model"]
            # streaming writes one line per content block; count usage once per message id
            mid = str(msg.get("id") or id(msg))
            usage = msg.get("usage") or {}
            if usage and mid not in seen_msgs:
                seen_msgs.add(mid)
                sess.input_tokens += usage.get("input_tokens", 0) or 0
                sess.output_tokens += usage.get("output_tokens", 0) or 0
                sess.cache_read_tokens += usage.get("cache_read_input_tokens", 0) or 0
            for block in content if isinstance(content, list) else []:
                if block.get("type") != "tool_use":
                    continue
                name = block.get("name") or "?"
                inp = block.get("input") or {}
                col.event(
                    sid, ts, EventKind.tool, name, detail=_summarize(inp), call_id=block.get("id")
                )
                if name == "Skill" and isinstance(inp.get("skill"), str):
                    col.event(sid, ts, EventKind.skill, inp["skill"], detail="invoke")
        elif kind == "user" and not obj.get("isMeta"):
            is_text = isinstance(content, str) or (
                isinstance(content, list)
                and not any(b.get("type") == "tool_result" for b in content)
            )
            if is_text:
                col.event(sid, ts, EventKind.prompt, "user")
    return col.result()


# --- Codex: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl ---------------------

_ROLLOUT_ID_RE = re.compile(
    r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.jsonl$"
)


def parse_codex(path: Path) -> ParseResult:
    col = _Collector(Harness.codex, path)
    m = _ROLLOUT_ID_RE.search(path.name)
    sid = m.group(1) if m else path.stem
    sess = col.session(sid)
    for obj in _jsonl(path):
        ts = obj.get("timestamp")
        sess.touch(parse_ts(ts))
        top = obj.get("type")
        payload = obj.get("payload") or {}
        if top == "session_meta":
            sess.cwd = payload.get("cwd") or sess.cwd
            sess.client_version = payload.get("cli_version") or sess.client_version
        elif top == "turn_context":
            sess.model = payload.get("model") or sess.model
            sess.cwd = payload.get("cwd") or sess.cwd
        elif top == "response_item":
            ptype = payload.get("type")
            if ptype in ("function_call", "custom_tool_call"):
                raw = payload.get("arguments") if ptype == "function_call" else payload.get("input")
                text = raw if isinstance(raw, str) else json.dumps(raw or {})
                detail = None
                try:
                    detail = (
                        _summarize(json.loads(text)) if text.startswith("{") else text[:DETAIL_LEN]
                    )
                except json.JSONDecodeError:
                    detail = text[:DETAIL_LEN]
                col.event(
                    sid,
                    ts,
                    EventKind.tool,
                    payload.get("name") or "?",
                    detail=detail,
                    call_id=payload.get("call_id"),
                )
                col.skill_reads(sid, ts, text)
            elif ptype == "message" and payload.get("role") == "user":
                texts = [
                    c.get("text", "") for c in payload.get("content") or [] if isinstance(c, dict)
                ]
                # codex injects <environment_context>/<user_instructions> as user messages
                if texts and not texts[0].lstrip().startswith("<"):
                    col.event(sid, ts, EventKind.prompt, "user")
        elif top == "event_msg" and payload.get("type") == "token_count":
            total = (payload.get("info") or {}).get("total_token_usage") or {}
            if total:
                sess.input_tokens = total.get("input_tokens", 0) or 0
                sess.output_tokens = total.get("output_tokens", 0) or 0
                sess.cache_read_tokens = total.get("cached_input_tokens", 0) or 0
    return col.result()


# --- opencode / kilo: sqlite with session, message, part tables --------------


def parse_opencode_db(path: Path, harness: Harness) -> ParseResult:
    col = _Collector(harness, path)
    con = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        rows = con.execute(
            "select id, directory, time_created, time_updated, version, model,"
            " tokens_input, tokens_output, tokens_cache_read from session"
        ).fetchall()
        for sid, directory, created, updated, version, model, tin, tout, tcache in rows:
            sess = col.session(sid)
            sess.cwd = directory
            sess.touch(parse_ts(created))
            sess.touch(parse_ts(updated))
            sess.client_version = version
            sess.model = _model_name(model)
            sess.input_tokens = int(tin or 0)
            sess.output_tokens = int(tout or 0)
            sess.cache_read_tokens = int(tcache or 0)
        for sid, created, data in con.execute("select session_id, time_created, data from message"):
            msg = json.loads(data)
            sess = col.session(sid)
            if msg.get("role") == "user":
                col.event(sid, created, EventKind.prompt, "user")
            elif msg.get("role") == "assistant" and not sess.model:
                sess.model = _model_name(msg.get("model")) or msg.get("modelID")
        for sid, created, data in con.execute(
            "select session_id, time_created, data from part"
            " where json_extract(data, '$.type') = 'tool'"
        ):
            part = json.loads(data)
            name = part.get("tool") or "?"
            inp = (part.get("state") or {}).get("input") or {}
            col.event(
                sid,
                created,
                EventKind.tool,
                name,
                detail=_summarize(inp),
                call_id=part.get("callID"),
            )
            if name == "skill" and isinstance(inp.get("name"), str):
                col.event(sid, created, EventKind.skill, inp["name"], detail="invoke")
    finally:
        con.close()
    return col.result()


def _model_name(value: Any) -> str | None:  # noqa: ANN401
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            return value
    if isinstance(value, dict):
        provider, model = value.get("providerID"), value.get("modelID")
        return f"{provider}/{model}" if provider and model else model
    return None


# --- Pi: ~/.pi/agent/sessions/<cwd-slug>/<ts>_<id>.jsonl ---------------------


def parse_pi(path: Path) -> ParseResult:
    col = _Collector(Harness.pi, path)
    sid = path.stem.split("_")[-1]
    sess = col.session(sid)
    for obj in _jsonl(path):
        if obj.get("type") == "session":
            sid = obj.get("id") or sid
            sess = col.session(sid)
            sess.cwd = obj.get("cwd")
            sess.touch(parse_ts(obj.get("timestamp")))
            continue
        if obj.get("type") != "message":
            continue
        msg = obj.get("message") or {}
        ts = msg.get("timestamp") or msg.get("ts") or obj.get("timestamp")
        role = msg.get("role")
        if role == "user":
            col.event(sid, ts, EventKind.prompt, "user")
            continue
        if role != "assistant":
            continue
        if msg.get("model"):
            provider = msg.get("provider")
            sess.model = f"{provider}/{msg['model']}" if provider else msg["model"]
        usage = msg.get("usage") or {}
        sess.input_tokens += int(usage.get("input") or 0)
        sess.output_tokens += int(usage.get("output") or 0)
        sess.cache_read_tokens += int(usage.get("cacheRead") or 0)
        for block in msg.get("content") or []:
            if not isinstance(block, dict) or block.get("type") != "toolCall":
                continue
            args = block.get("arguments")
            col.event(
                sid,
                ts,
                EventKind.tool,
                block.get("name") or "?",
                detail=_summarize(args),
                call_id=block.get("id"),
            )
            col.skill_reads(sid, ts, json.dumps(args) if not isinstance(args, str) else args)
    return col.result()


# --- discovery ---------------------------------------------------------------


def default_roots() -> dict[Harness, Path]:
    home = Path.home()
    data = Path(os.environ.get("XDG_DATA_HOME", home / ".local" / "share"))
    return {
        Harness.claude: Path(os.environ.get("CLAUDE_CONFIG_DIR", home / ".claude")) / "projects",
        Harness.codex: Path(os.environ.get("CODEX_HOME", home / ".codex")) / "sessions",
        Harness.opencode: data / "opencode" / "opencode.db",
        Harness.kilo: data / "kilo" / "kilo.db",
        Harness.pi: home / ".pi" / "agent" / "sessions",
    }


def discover(roots: dict[Harness, Path]) -> Iterator[tuple[Harness, Path]]:
    for harness, root in roots.items():
        if not root.exists():
            continue
        if root.is_file():
            yield harness, root
        else:
            yield from ((harness, p) for p in sorted(root.rglob("*.jsonl")))


def parse(harness: Harness, path: Path) -> ParseResult:
    match harness:
        case Harness.claude:
            return parse_claude(path)
        case Harness.codex:
            return parse_codex(path)
        case Harness.opencode | Harness.kilo:
            return parse_opencode_db(path, harness)
        case Harness.pi:
            return parse_pi(path)

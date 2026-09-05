from __future__ import annotations

from datetime import UTC, datetime
from enum import StrEnum

from pydantic import BaseModel, Field


class Harness(StrEnum):
    claude = "claude"
    codex = "codex"
    opencode = "opencode"
    kilo = "kilo"
    pi = "pi"


class EventKind(StrEnum):
    tool = "tool"
    skill = "skill"
    prompt = "prompt"


class Event(BaseModel):
    harness: Harness
    session_id: str
    ts: datetime | None
    kind: EventKind
    name: str
    detail: str | None = None
    call_id: str | None = None
    source_path: str


class Session(BaseModel):
    harness: Harness
    session_id: str
    source_path: str
    started_at: datetime | None = None
    ended_at: datetime | None = None
    cwd: str | None = None
    model: str | None = None
    client_version: str | None = None
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0

    def touch(self, ts: datetime | None) -> None:
        if ts is None:
            return
        if self.started_at is None or ts < self.started_at:
            self.started_at = ts
        if self.ended_at is None or ts > self.ended_at:
            self.ended_at = ts


class ParseResult(BaseModel):
    sessions: list[Session] = Field(default_factory=list)
    events: list[Event] = Field(default_factory=list)


EPOCH_MILLIS_THRESHOLD = 1e11


def parse_ts(value: object) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        # harnesses store epoch millis; anything under the threshold is seconds
        seconds = value / 1000 if value > EPOCH_MILLIS_THRESHOLD else value
        return datetime.fromtimestamp(seconds, tz=UTC)
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            return None
    return None

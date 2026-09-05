# harness-telemetry

Reads the session logs that coding-agent harnesses write to disk and loads them
into one DuckDB file, then answers "which tools and skills does each harness
use" with SQL.

```bash
uv tool install --editable .      # or: ./scripts/install.sh from the repo root
harness-telemetry paths           # db path and the stores that will be scanned
harness-telemetry ingest          # incremental, ~10 s cold for ~250 MB of logs, <1 s warm
harness-telemetry report summary
harness-telemetry report skills --days 30
harness-telemetry report tools --harness claude
harness-telemetry report sessions --project APImanac --limit 10
harness-telemetry sql "select * from sources order by ingested_at desc limit 5"
```

## Tables

- `sessions` - one row per harness session: `harness`, `session_id`, `started_at`,
  `ended_at`, `cwd`, `model`, `client_version`, `input_tokens`, `output_tokens`,
  `cache_read_tokens`, `source_path`.
- `events` - one row per tool call, skill use, or user prompt: `harness`,
  `session_id`, `ts`, `kind` (`tool` | `skill` | `prompt`), `name`, `detail`,
  `call_id`, `source_path`. `detail` is the first 200 chars of the command or
  path for tools, and `invoke` or `read` for skills. Prompts store no text.
- `sources` - per source file: mtime and size, used to skip unchanged files on
  the next `ingest`. A changed file has its rows deleted and re-inserted.

## Parsers

One function per harness in `parsers.py`. Store roots come from
`CLAUDE_CONFIG_DIR`, `CODEX_HOME`, `XDG_DATA_HOME`, and `~/.pi`. The opencode
and Kilo parsers open the SQLite database read-only and read the `session`,
`message`, and `part` tables. Token totals come from each harness's own
accounting: per-message `usage` for Claude and Pi, the last cumulative
`token_count` event for Codex, and the `session` row for opencode and Kilo.

```bash
uv run ruff format . && uv run ruff check . && uv run ty check src/
```

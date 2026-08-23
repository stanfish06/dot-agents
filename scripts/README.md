# Scripts

Install, refresh, and validation helpers.

## Install

Run the master installer from the repo root:

```bash
./scripts/install.sh
```

Useful options:

```bash
./scripts/install.sh --dry-run
./scripts/install.sh --skip-skills
./scripts/install.sh --skip-config
./scripts/install.sh --skip-claude
./scripts/install.sh --skip-codex
./scripts/install.sh --skip-pi
./scripts/install.sh --skip-opencode
./scripts/install.sh --skip-kilo
./scripts/install.sh --skip-cursor
./scripts/install.sh --extras gstack
./scripts/install.sh --extras career
./scripts/install.sh --extras all
```

The installer initializes the `skills/` submodule, delegates skill installation
to `skills/install-skills.sh`, then symlinks selected Claude, Codex, Pi,
opencode, Kilo Code, and Cursor config into their homes. Existing non-matching targets are moved to a
timestamped `.backup-...` path unless `--force` is passed. Optional `gstack`
and `career-ops` installation is disabled by default and forwarded through
`--extras` when requested.

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
```

The installer initializes the `skills/` submodule, delegates skill installation
to `skills/install-skills.sh`, then symlinks selected Claude and Codex config
into `~/.claude` and `~/.codex`. Existing non-matching targets are moved to a
timestamped `.backup-...` path unless `--force` is passed.

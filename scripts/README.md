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
```

The installer initializes the `skills/` submodule, delegates skill installation
to `skills/install-skills.sh`, then symlinks selected Claude, Codex, and Pi
agent config into their homes. Existing non-matching targets are moved to a
timestamped `.backup-...` path unless `--force` is passed.

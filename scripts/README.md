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
./scripts/install.sh --skip-apimanac
./scripts/install.sh --extras gstack
./scripts/install.sh --extras career
./scripts/install.sh --extras all
```

The installer initializes the `skills/` submodule, delegates skill installation
to `skills/install-skills.sh`, then symlinks selected Claude, Codex, Pi,
opencode, Kilo Code, and Cursor config into their homes. It also writes the
APImanac `catalog_root`, fetches `skill/SKILL.md` from
`stanfish06/APImanac` into `apis/SKILL.md`, and links that file into each
harness `skills/apimanac/` directory. Existing non-matching targets are moved to a
timestamped `.backup-...` path unless `--force` is passed. Optional `gstack`
and `career-ops` installation is disabled by default and forwarded through
`--extras` when requested. Override the APImanac skill URL with
`APIMANAC_SKILL_URL` (default:
`https://raw.githubusercontent.com/stanfish06/APImanac/master/skill/SKILL.md`).

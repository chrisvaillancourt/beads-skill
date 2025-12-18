# Configuration Reference

bd has two types of configuration with different behaviors. Understanding this distinction is critical for team setups and git worktrees.

## Two Configuration Types

| Type | Storage | Shared via Git | Use For |
|------|---------|----------------|---------|
| **YAML settings** | `.beads/config.yaml` | Yes (if tracked) | Sync branch, daemon behavior, output format |
| **Database settings** | `.beads/beads.db` | No | Integrations (GitHub, Jira), personal preferences |

### YAML Settings (.beads/config.yaml)

These settings can be tracked in git and shared across the team:

```yaml
# .beads/config.yaml
sync-branch: "beads-sync"    # Branch for beads commits (critical for worktrees)
no-daemon: false             # Disable daemon entirely
no-auto-flush: false         # Disable auto-flush to JSONL
no-auto-import: false        # Disable auto-import from JSONL
json: false                  # Default JSON output
auto-start-daemon: true      # Auto-start daemon if not running
flush-debounce: "5s"         # Debounce interval for JSONL writes
actor: ""                    # Override author name for commits
```

**Key setting: `sync-branch`**

For team projects with git worktrees, `sync-branch` is essential:
- All bd metadata commits go to this branch (not your feature branch)
- Enables daemon to work correctly across all worktrees
- Prevents bd commits from polluting feature branch history

### Database Settings (.beads/beads.db)

These settings are stored in SQLite and do NOT sync via git:

```bash
# View database settings
bd config list

# Set database settings
bd config set github.org myorg
bd config set github.repo myrepo
bd config set jira.url https://mysite.atlassian.net/
bd config set sync.branch beads-sync
```

**Common database settings:**

| Setting | Purpose | Example |
|---------|---------|---------|
| `github.org` | GitHub organization | `acme-corp` |
| `github.repo` | GitHub repository name | `my-project` |
| `jira.url` | Jira instance URL | `https://mysite.atlassian.net/` |
| `sync.branch` | Sync branch (also in YAML) | `beads-sync` |

## sync-branch vs sync.branch

**Important**: Two settings exist with similar names:

1. **`sync-branch`** in `.beads/config.yaml` (YAML, takes precedence)
2. **`sync.branch`** in database (shown by `bd config list`)

**Recommendation**: Set both to the same value to avoid confusion:

```bash
# In config.yaml
sync-branch: "beads-sync"

# In database
bd config set sync.branch beads-sync
```

## Tracking config.yaml in Git

By default, `.beads/.gitignore` doesn't track `config.yaml`. For team projects, you should track it:

```gitignore
# .beads/.gitignore - add this line
!config.yaml
```

**Why track config.yaml?**
- Ensures `sync-branch` is consistent across all clones
- Team members get correct configuration automatically
- Prevents each person from needing to configure manually

## Setup for New Clones/Worktrees

Since database settings don't sync, each new clone or worktree needs configuration:

### Option 1: Manual Setup

```bash
bd config set github.org myorg
bd config set github.repo myrepo
bd config set jira.url https://mysite.atlassian.net/
```

### Option 2: Setup Script (Recommended)

Create `scripts/setup-bd.sh` in your project:

```bash
#!/usr/bin/env bash
set -e
echo "Configuring bd integrations..."
bd config set github.org myorg
bd config set github.repo myrepo
bd config set jira.url https://mysite.atlassian.net/
echo "Done. Run 'bd doctor' to verify."
```

### Option 3: Claude Code Automation (Best)

Use SessionStart hooks to automatically configure worktrees. See [BEADS-TEAM-SETUP.md](../../../templates/BEADS-TEAM-SETUP.md#automated-worktree-setup).

## Verifying Configuration

Check your setup with `bd doctor`:

```
$ bd doctor
✓ Installation: .beads/ directory found
✓ Git Hooks: All recommended hooks installed
✓ Sync Branch Hook Compatibility: Pre-push hook compatible
✓ Database: version 0.30.3
✓ Git Merge Driver: Correctly configured
✓ Sync Branch Config: Configured (beads-sync)
✓ Sync Branch Health: OK
```

Check specific settings:

```bash
# View all database settings
bd config list

# Check sync branch alignment
grep sync-branch .beads/config.yaml
bd config get sync.branch
```

## Git Worktree Considerations

Each git worktree has its own:
- `.beads/beads.db` (database - gitignored)
- `.git` file (points to main repo's `.git/worktrees/`)

All worktrees share:
- `.beads/issues.jsonl` (tracked in git)
- `.beads/config.yaml` (if tracked in git)
- Git hooks (if installed per-worktree)

**Critical for worktrees:**
1. `sync-branch` must be configured in config.yaml
2. Database must be initialized (`bd init --quiet`)
3. Integration settings must be configured (setup script)
4. Git hooks must be installed (`bd hooks install`)

## Troubleshooting Configuration

### "Database settings not syncing"

Database settings are intentionally local. Use a setup script to configure consistently.

### "sync-branch not working"

1. Check config.yaml has `sync-branch: "beads-sync"`
2. Verify the branch exists: `git branch -a | grep beads-sync`
3. Align database setting: `bd config set sync.branch beads-sync`

### "Integration settings empty in new worktree"

Run your setup script or manually configure:
```bash
./scripts/setup-bd.sh
# or
bd config set github.org myorg
bd config set github.repo myrepo
```

### "bd config list shows different value than config.yaml"

YAML settings take precedence. The database value may be stale or different. Align them:
```bash
bd config set sync.branch "$(grep sync-branch .beads/config.yaml | cut -d'"' -f2)"
```

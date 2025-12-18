# Beads Team Setup Template

Copy this file to your team repo and follow the setup steps.

**Using parallel agents with git worktrees?** See [BEADS-PARALLEL-AGENTS.md](BEADS-PARALLEL-AGENTS.md) after completing this setup.

## Initial Setup (One-Time, by Repo Owner)

### Step 1: Initialize beads

```bash
bd init --team
```

The wizard will:
- Ask if your main branch is protected
- Configure sync branch if needed (for protected main)
- Enable auto-sync (daemon commits/pushes)
- Create AGENTS.md with landing-the-plane instructions

### Step 2: Install hooks

```bash
bd hooks install
```

### Step 3: Apply v0.30.2 hook workaround

Edit `.git/hooks/post-checkout` line ~77:

```bash
# Change this:
if ! output=$(bd sync --import-only --no-git-history 2>&1); then

# To this:
if ! output=$(bd sync --import-only 2>&1); then
```

**Tracking:** [steveyegge/beads#608](https://github.com/steveyegge/beads/issues/608)

### Step 4: Track config.yaml in git

Modify `.beads/.gitignore` to track the config file:

```bash
echo '!config.yaml' >> .beads/.gitignore
```

**Why:** Ensures `sync-branch` setting is shared across all clones/worktrees.

### Step 5: Create integration setup script (optional)

For GitHub repos, integration settings are **auto-detected** from the git remote. No setup script needed!

For Jira integration or non-GitHub repos, create `scripts/setup-bd.sh`:

```bash
# Copy the template
cp /path/to/beads-skill/templates/setup-bd.sh scripts/
chmod +x scripts/setup-bd.sh

# Edit JIRA_URL if using Jira, then run
./scripts/setup-bd.sh
```

The script will:
- Auto-detect GitHub org/repo from `git remote get-url origin`
- Configure Jira if JIRA_URL is set
- Allow env var overrides: `GITHUB_ORG=foo GITHUB_REPO=bar ./scripts/setup-bd.sh`

**Why:** Integration settings (github.org, jira.url) are database-only. See [Configuration Types](#configuration-types) below.

### Step 6: Commit setup

```bash
git add .beads/ .gitattributes AGENTS.md scripts/setup-bd.sh
git commit -m "chore: initialize beads for team issue tracking"
git push
```

### If Main is Protected

If you answered "yes" to protected main, the wizard configures a sync branch.
You'll need to create and push it:

```bash
git checkout -b beads-sync
git push -u origin beads-sync
git checkout main
```

---

## Team Member Setup

Each team member runs once:

```bash
# 1. Global Claude Code hooks (if using Claude)
bd setup claude

# 2. Configure integrations (database-only settings)
./scripts/setup-bd.sh

# 3. Verify setup
bd doctor
```

### Expected bd doctor output

A healthy setup shows:

```
✓ Installation: .beads/ directory found
✓ Git Hooks: All recommended hooks installed
✓ Sync Branch Hook Compatibility: Pre-push hook compatible
✓ Database: version 0.30.3
✓ Git Merge Driver: Correctly configured
✓ Sync Branch Config: Configured (beads-sync)
✓ Sync Branch Health: OK
```

---

## Git Worktree Setup

For each new worktree:

```bash
# 1. Create worktree
git worktree add ../repo-worktree-name branch-name
cd ../repo-worktree-name

# 2. Initialize bd (worktrees need their own database)
bd init --quiet

# 3. Install hooks in this worktree
bd hooks install

# 4. Apply hook workaround (same as initial setup step 3)

# 5. Configure integrations
./scripts/setup-bd.sh
```

**IMPORTANT:** If NOT using sync-branch, disable the daemon in worktrees:
```bash
export BEADS_NO_DAEMON=1
```

With sync-branch configured (recommended), the daemon works correctly across worktrees.

### Smart bd wrapper (optional convenience)

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Smart bd wrapper - auto-detects worktrees and disables daemon
bd() {
  if [ -f .git ] 2>/dev/null || \
     [ "$(git rev-parse --git-dir 2>/dev/null)" != "$(git rev-parse --git-common-dir 2>/dev/null)" ]; then
    BEADS_NO_DAEMON=1 command bd "$@"
  else
    command bd "$@"
  fi
}
```

---

## Automated Worktree Setup (Claude Code)

Automate worktree initialization with Claude Code SessionStart hooks.

### Step 1: Create session setup script

Copy [session-setup.sh](session-setup.sh) to `scripts/session-setup.sh`:

```bash
cp /path/to/beads-skill/templates/session-setup.sh scripts/
chmod +x scripts/session-setup.sh
```

### Step 2: Add Claude Code hook

Create `.claude/settings.json` (or merge with existing):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/session-setup.sh"
          }
        ]
      }
    ]
  }
}
```

See [claude-settings.json](claude-settings.json) for the complete template.

### Step 3: Commit automation

```bash
git add scripts/session-setup.sh .claude/settings.json
git commit -m "chore: add bd automation for worktrees"
git push
```

**Result:** When Claude Code starts in a new worktree, it automatically:
1. Initializes bd database if missing
2. Configures integration settings if missing

---

## Configuration Types

bd has two types of configuration with different behaviors:

| Type | Storage | Syncs via Git | Examples |
|------|---------|---------------|----------|
| **YAML** | `.beads/config.yaml` | Yes (if tracked) | `sync-branch`, `no-daemon` |
| **Database** | `.beads/beads.db` | No | `github.org`, `jira.url` |

### Why this matters

- **YAML settings** (sync-branch) are shared when you track config.yaml
- **Database settings** (integrations) must be configured per-clone/worktree
- This is why we use `scripts/setup-bd.sh` for integrations

### sync-branch vs sync.branch

Two similar settings exist:
- `sync-branch` in config.yaml (YAML, takes precedence)
- `sync.branch` in database (shown by `bd config list`)

**Recommendation:** Align both:
```bash
bd config set sync.branch beads-sync
```

---

## AGENTS.md Section

`bd init --team` creates an AGENTS.md automatically. If you already have one, merge the content below:

```markdown
## Issue Tracking

This project uses [beads](https://github.com/steveyegge/beads) (`bd` command) for issue tracking.

### First Session
Run `bd onboard` to get oriented.

### Git Worktrees
**REQUIRED:** Disable daemon mode in worktrees (unless using sync-branch):
```bash
export BEADS_NO_DAEMON=1
```

### Session Start
```bash
bd ready --json              # Find available work
bd list --status in_progress # Check active work
bd show <id>                 # Read issue context
```

### During Work
```bash
bd create "Title" -p 2 --json           # Create issue
bd update <id> --status in_progress     # Claim work
bd update <id> --notes "Progress..."    # Update notes
bd close <id> --reason "Done"           # Complete work
```

### Session End (MANDATORY)
**Work is NOT complete until `git push` succeeds.**

```bash
# 1. Sync beads
bd sync

# 2. Push (resolve conflicts if needed)
git pull --rebase
git push

# 3. Verify
git status  # Must show "up to date with origin"
```

### Multi-Agent Conflicts
If `git push` fails:
```bash
git pull --rebase
# If .beads/issues.jsonl conflicts: keep both sides' changes
bd sync
git push  # Retry
```
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Find ready work | `bd ready --json` |
| Show issue | `bd show <id>` |
| Create issue | `bd create "Title" -p 2 --type task --json` |
| Claim work | `bd update <id> --status in_progress` |
| Update notes | `bd update <id> --notes "..."` |
| Close issue | `bd close <id> --reason "Done"` |
| Sync to git | `bd sync` |
| Check blocked | `bd blocked --json` |
| Health check | `bd doctor` |
| Initialize (non-interactive) | `bd init --quiet` |

## Priority Levels

| Priority | Meaning |
|----------|---------|
| 0 | Critical (security, data loss, build broken) |
| 1 | High (blocking work, major features) |
| 2 | Medium (default) |
| 3 | Low (polish, optimization) |
| 4 | Backlog (future ideas) |

## Issue Types

| Type | Use For |
|------|---------|
| `bug` | Defects |
| `feature` | New functionality |
| `task` | General work (default) |
| `epic` | Large work with subtasks |
| `chore` | Maintenance |

---

## Known Issues

### Post-checkout hook error (beads v0.30.2)

**Symptom:** Branch switching shows `unknown flag: --no-git-history`

**Fix:** Edit `.git/hooks/post-checkout` line ~77, remove `--no-git-history` flag.

**Tracking:** [steveyegge/beads#608](https://github.com/steveyegge/beads/issues/608)

### Post-checkout shows daemon warning in worktrees

**Symptom:** Hook suggests `BEADS_NO_DAEMON=1` even when sync-branch is configured.

**Status:** The message is outdated. With sync-branch configured, the daemon works correctly in worktrees. You can ignore this warning.

---

## Troubleshooting

**"Database locked" errors:**
```bash
bd sync --no-daemon
```

**Daemon issues in worktrees (without sync-branch):**
```bash
export BEADS_NO_DAEMON=1
```

**Out of sync after pull:**
```bash
bd sync --import-only
```

**Integration settings empty in new worktree:**
```bash
./scripts/setup-bd.sh
```

**Check system health:**
```bash
bd doctor
```

**Verify configuration alignment:**
```bash
# Check YAML setting
grep sync-branch .beads/config.yaml

# Check database setting
bd config get sync.branch
```

---

## Template Files

This directory includes templates you can copy to your project:

| Template | Purpose | Destination |
|----------|---------|-------------|
| [setup-bd.sh](setup-bd.sh) | Configure integration settings | `scripts/setup-bd.sh` |
| [session-setup.sh](session-setup.sh) | Claude Code SessionStart hook | `scripts/session-setup.sh` |
| [claude-settings.json](claude-settings.json) | Claude Code hook config | `.claude/settings.json` |

---

## See Also

- [BEADS-PARALLEL-AGENTS.md](BEADS-PARALLEL-AGENTS.md) - Parallel agent coordination
- [Configuration Reference](../skills/beads/references/CONFIGURATION.md) - Detailed configuration docs
- [beads repository](https://github.com/steveyegge/beads) - Official beads project

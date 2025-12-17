# Beads Team Setup Template

Copy this file to your team repo and follow the setup steps.

## Initial Setup (One-Time, by Repo Owner)

```bash
# 1. Initialize beads with team wizard
bd init --team
```

The wizard will:
- Ask if your main branch is protected
- Configure sync branch if needed (for protected main)
- Enable auto-sync (daemon commits/pushes)
- Create AGENTS.md with landing-the-plane instructions

```bash
# 2. Install hooks
bd hooks install

# 3. Apply v0.30.2 hook workaround
#    Edit .git/hooks/post-checkout line ~77
#    Change: bd sync --import-only --no-git-history
#    To:     bd sync --import-only

# 4. Commit setup
git add .beads/ .gitattributes AGENTS.md
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

## Team Member Setup

Each team member runs once:

```bash
# Global Claude Code hooks (if using Claude)
bd setup claude

# Verify
bd doctor
```

## Git Worktree Setup

For each new worktree:

```bash
# Create worktree
git worktree add ../repo-worktree-name branch-name
cd ../repo-worktree-name

# REQUIRED: Disable daemon (worktrees share database)
export BEADS_NO_DAEMON=1

# Install hooks in this worktree
bd hooks install

# Apply hook workaround (same as initial setup step 5)
```

**Add to shell profile for convenience:**
```bash
# ~/.zshrc or ~/.bashrc
alias bdw='BEADS_NO_DAEMON=1 bd'  # "bd worktree"
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
**REQUIRED:** Disable daemon mode in worktrees:
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

---

## Troubleshooting

**"Database locked" errors:**
```bash
bd sync --no-daemon
```

**Daemon issues in worktrees:**
```bash
export BEADS_NO_DAEMON=1
```

**Out of sync after pull:**
```bash
bd sync --import-only
```

**Check system health:**
```bash
bd doctor
```

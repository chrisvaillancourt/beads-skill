# Beads Parallel Agents + Git Worktrees Setup

For teams running multiple AI agents in parallel using git worktrees.

**Prerequisites:** Complete [BEADS-TEAM-SETUP.md](BEADS-TEAM-SETUP.md) first.

## Key Gotchas

| Issue | Cause | Solution |
|-------|-------|----------|
| Database locking | Worktrees share `.beads/` | Disable daemon |
| Issue race conditions | Two agents grab same issue | Claim before working |
| Sync conflicts | Simultaneous pushes to sync branch | Retry loop |
| Missing hooks | Hooks are per-worktree | Install in each worktree |
| Daemon bugs | [#609](https://github.com/steveyegge/beads/issues/609) | Disable daemon |
| Stranded work | Agent stops before push | Enforce landing protocol |

## Environment Setup

If you followed the main [README setup](../README.md#3-add-smart-bd-wrapper-global-one-time), the smart `bd` wrapper automatically detects worktrees and sets `BEADS_NO_DAEMON=1`. No additional configuration needed.

If you skipped that step, add to `~/.zshrc` (or `~/.bashrc`):

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

## Per-Worktree Setup

For each new worktree:

```bash
# Create worktree
git worktree add ../repo-feature-x feature-x
cd ../repo-feature-x

# Install hooks
bd hooks install

# Apply v0.30.2 hook workaround
# Edit .git/hooks/post-checkout line ~77
# Change: bd sync --import-only --no-git-history
# To:     bd sync --import-only
```

## Agent Session Workflow

### Start Session

```bash
git pull
bd sync --import-only           # Get latest issue state
bd ready --json                 # Find available work
bd update <id> --status in_progress  # CLAIM before working
```

(The smart wrapper handles `BEADS_NO_DAEMON=1` automatically)

**Important:** Always claim an issue before starting work. If another agent already claimed it, pick a different one.

### During Work

Sync periodically to avoid large merge conflicts:

```bash
bd sync
git pull --rebase
git push
```

Update notes at milestones:

```bash
bd update <id> --notes "COMPLETED: X, IN PROGRESS: Y, NEXT: Z"
```

### End Session (MANDATORY)

```bash
# 1. Update issue status
bd close <id> --reason "Done"   # Or update notes if not done

# 2. Sync and push (retry until success)
bd sync
while ! git push; do
    git pull --rebase
    # If .beads/issues.jsonl conflicts: keep both sides
    bd sync
done

# 3. Verify
git status  # Must show "up to date with origin"
```

**Rule:** No agent stops until `git push` succeeds.

## Handling JSONL Conflicts

When `git pull --rebase` has conflicts in `.beads/issues.jsonl`:

```bash
# Accept both versions (JSONL is append-friendly)
git checkout --theirs .beads/issues.jsonl
git add .beads/issues.jsonl
git rebase --continue
bd sync  # Re-export local state
```

Or use the merge driver (should be auto-configured):
```bash
bd merge %A %O %A %B
```

## Checklist

### One-Time Setup
```
[ ] Smart bd wrapper in ~/.zshrc (see README step 3)
```

### Per-Worktree Setup
```
[ ] bd hooks install
[ ] Hook v0.30.2 workaround applied
```

### Per-Session Start
```
[ ] git pull
[ ] bd sync --import-only
[ ] Claim issue before working
```

### Per-Session End
```
[ ] Issue status updated
[ ] bd sync
[ ] git push succeeded
[ ] git status shows "up to date"
```

## AGENTS.md Addition

Add to your repo's AGENTS.md:

```markdown
### Parallel Agent / Worktree Setup

**Environment:** Use the smart `bd` wrapper (see beads-plugin README) which auto-detects worktrees.

**Claiming work:** Run `bd update <id> --status in_progress` BEFORE starting work to avoid conflicts with other agents.

**Sync often:** Run `bd sync && git pull --rebase && git push` periodically during long sessions.

**Push required:** Session is NOT complete until `git push` succeeds. Retry until it does.
```

## Troubleshooting

**"Database is locked"**

If using the smart wrapper, this shouldn't happen. Verify the wrapper is loaded:
```bash
type bd  # Should show "bd is a shell function"
```

If not using the wrapper, manually disable daemon:
```bash
BEADS_NO_DAEMON=1 bd sync
```

**Agent claimed issue I was working on**
- Check if you claimed it first with `bd show <id>`
- If not, pick another issue or coordinate with the team

**Sync conflicts won't resolve**
```bash
# Nuclear option: re-import from JSONL
git checkout origin/beads-sync -- .beads/issues.jsonl
bd sync --import-only
```

**Worktree shows stale issues**
```bash
git pull
bd sync --import-only
```

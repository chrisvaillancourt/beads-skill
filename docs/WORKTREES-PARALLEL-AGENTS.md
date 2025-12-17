# Git Worktrees & Parallel Agents with Beads

A practical guide for using `bd` with git worktrees and running multiple parallel agents.

## Quick Overview

**Git worktrees** let you work on multiple branches simultaneously in separate directories, all sharing the same `.git` directory. **Parallel agents** are multiple AI assistants working on different issues concurrently.

Beads supports both patterns, but **requires specific configuration** to avoid conflicts.

## The Core Challenge

Git worktrees share the same `.git` directory and `.beads` database. The daemon doesn't know which branch each worktree has checked out, which can cause it to commit/push to the wrong branch.

**Solution**: Either disable the daemon OR use sync-branch configuration.

## Setup Option 1: Worktrees Without Daemon (Simple)

Best for: Solo developers, simple workflows

### Setup Steps

```bash
# 1. Disable daemon for all beads operations
export BEADS_NO_DAEMON=1

# 2. Initialize beads in main repository
cd /path/to/main/repo
bd init

# 3. Create your worktrees as usual
git worktree add ../feature-branch feature-branch
git worktree add ../bugfix bugfix

# 4. Work in any worktree
cd ../feature-branch
bd ready
bd create "Implement new feature"
bd sync  # Manual sync when ready
```

### Key Points

- Add `export BEADS_NO_DAEMON=1` to your shell profile
- All worktrees share the same `.beads` database automatically
- Must run `bd sync` manually to commit changes
- No auto-sync or background operations

## Setup Option 2: Worktrees With Sync-Branch (Advanced)

Best for: Teams, protected branches, auto-sync needs

### Setup Steps

```bash
# 1. Initialize with sync-branch
cd /path/to/main/repo
bd init --branch beads-metadata

# Or configure afterward:
bd config set sync.branch beads-metadata

# 2. Restart daemon to pick up config
bd daemon stop
bd daemon start

# 3. Create worktrees
git worktree add ../feature-branch feature-branch
git worktree add ../bugfix bugfix

# 4. Work in any worktree with daemon support
cd ../feature-branch
bd ready
bd create "Implement new feature"
# Changes auto-sync to beads-metadata branch
```

### What This Does

- Creates a lightweight worktree at `.git/beads-worktrees/beads-metadata/`
- Only contains `.beads/` directory (sparse checkout)
- Daemon commits issue changes to `beads-metadata` branch automatically
- Your working directory never changes branches
- Enables daemon functionality across all worktrees

### Merging Changes

```bash
# When ready to merge to main
git push origin beads-metadata

# If main is protected, create PR via GitHub/GitLab UI

# If you have direct access
bd sync --merge  # Merges with --no-ff for clear history
```

## Parallel Agents Setup

Multiple AI agents working on different issues concurrently.

### Configuration

```bash
# 1. Initialize beads (each agent workspace)
bd init --quiet  # Non-interactive for automation

# 2. Install git hooks (critical for sync)
./examples/git-hooks/install.sh

# 3. Optional: Configure agent assignments
bd config set user.name "agent-1"
```

### Agent Workflow

```bash
# Agent 1
bd ready --assignee agent-1
bd update bd-42 --status in_progress  # Claim work
bd create "Agent 1 discovered this issue"
bd sync

# Agent 2 (in different worktree or repo clone)
bd ready --assignee agent-2
bd update bd-43 --status in_progress  # Claim work
bd create "Agent 2 discovered this issue"
bd sync

# Coordinate via git
git pull --rebase
bd import  # Sync database with latest JSONL
```

### Preventing Conflicts

**Hash-based IDs** (v0.20.1+): Different issues get different IDs automatically, preventing collisions.

**Claim work explicitly**:
```bash
bd update <issue-id> --status in_progress --assignee agent-name
```

**Query by assignee**:
```bash
bd ready --assignee agent-1
bd list --assignee agent-2 --status in_progress
```

**Handle duplicates**:
```bash
bd duplicates  # Show potential duplicates
bd duplicates --auto-merge  # Auto-merge identical issues
bd merge bd-43 --into bd-42  # Manual merge
```

## Key Configuration

### Environment Variables

| Variable | Values | Default | Purpose |
|----------|--------|---------|---------|
| `BEADS_NO_DAEMON` | true/false | false | Disable daemon entirely |
| `BEADS_AUTO_START_DAEMON` | true/false | true | Auto-start daemon |
| `BEADS_DAEMON_MODE` | poll/events | poll | Sync operation mode |
| `BEADS_WATCHER_FALLBACK` | true/false | false | Fallback to polling if events fail |

### Daemon Settings

```bash
# View all running daemons
bd daemons list --json

# Check daemon health
bd daemons health --json

# View daemon logs
bd daemons logs . -n 100

# Stop specific daemon
bd daemons stop /path/to/workspace

# Kill all daemons
bd daemons killall --force
```

### Sync-Branch Settings

```bash
# Set sync branch
bd config set sync.branch beads-metadata

# Verify configuration
bd config get sync.branch

# Disable sync branch
bd config set sync.branch ""
```

## Common Pitfalls

### 1. "Branch already checked out" Error

**Cause**: Beads created a worktree for sync-branch that's holding the branch.

**Fix**:
```bash
rm -rf .git/beads-worktrees
rm -rf .git/worktrees/beads-*
git worktree prune

# Optional: disable sync-branch
bd config set sync.branch ""
```

### 2. Database Out of Sync

**Symptoms**: Changes from other agents/worktrees not visible.

**Fix**:
```bash
git pull
bd import  # Re-import JSONL to database
```

### 3. Agent Creates Duplicate Issues

**Cause**: Agent didn't check for existing issues first.

**Prevention**:
```bash
# Search before creating
bd list --json | grep "similar title"

# Label auto-generated work
bd create "Issue title" -l auto-generated
```

**Fix**:
```bash
bd duplicates --auto-merge
# or manually
bd merge bd-2 --into bd-1
```

### 4. Daemon Won't Stop in Worktrees

**Cause**: Worktree environment confuses daemon detection.

**Fix**:
```bash
# Use no-daemon mode
bd --no-daemon ready

# Or enable sandbox mode (auto-detected in v0.21.1+)
bd --sandbox ready
```

### 5. Changes Committed to Wrong Branch

**Cause**: Daemon active in worktree without sync-branch configured.

**Fix**:
```bash
# Disable daemon
export BEADS_NO_DAEMON=1

# Or configure sync-branch (see Setup Option 2)
bd config set sync.branch beads-metadata
```

## Troubleshooting

### View Worktrees

```bash
git worktree list
# Shows all worktrees and their branches
```

### Force Database Refresh

```bash
bd import --force
# Overwrites database with JSONL contents
```

### Verify Daemon Status

```bash
bd daemons list --json
bd daemons health --json
```

### Check Configuration

```bash
bd info --json
# Shows all config including sync-branch
```

### Enable Debug Logging

```bash
export BEADS_LOG_LEVEL=debug
bd ready
```

## Performance Notes

**Daemon Resources** (per workspace):
- Memory: ~30-35 MB
- CPU: <1% idle, 2-3% during active sync
- File descriptors: ~10 per daemon

**Event-Driven Mode** (experimental):
```bash
export BEADS_DAEMON_MODE=events
bd daemon restart
```

Benefits:
- <500ms latency (vs ~5000ms with polling)
- ~60% less CPU usage
- Instant reactivity via platform file watchers

## Best Practices

1. **Install Git Hooks**: Critical for keeping database and JSONL in sync
   ```bash
   ./examples/git-hooks/install.sh
   ```

2. **Claim Work Explicitly**: Prevents agents from stepping on each other
   ```bash
   bd update <id> --status in_progress --assignee agent-name
   ```

3. **Sync Frequently**: Especially before/after git operations
   ```bash
   bd sync  # Export database to JSONL and commit
   ```

4. **Import After Pulls**: Keep database current with remote changes
   ```bash
   git pull
   bd import
   ```

5. **Use Sync-Branch for Teams**: Enables auto-sync and daemon support
   ```bash
   bd config set sync.branch beads-metadata
   ```

6. **Label Agent Work**: Makes it easier to track and filter
   ```bash
   bd create "Issue" -l agent-generated -l agent-1
   ```

7. **Review Before Merging**: Check for conflicts and duplicates
   ```bash
   bd duplicates
   git diff beads-metadata
   ```

## Official Documentation

For more details, see:
- [WORKTREES.md](https://github.com/steveyegge/beads/blob/main/docs/WORKTREES.md) - Detailed worktree support
- [DAEMON.md](https://github.com/steveyegge/beads/blob/main/docs/DAEMON.md) - Daemon configuration and management
- [PROTECTED_BRANCHES.md](https://github.com/steveyegge/beads/blob/main/docs/PROTECTED_BRANCHES.md) - Sync-branch workflow
- [ADVANCED.md](https://github.com/steveyegge/beads/blob/main/docs/ADVANCED.md) - Multi-agent patterns
- [GIT_INTEGRATION.md](https://github.com/steveyegge/beads/blob/main/docs/GIT_INTEGRATION.md) - Git integration details
- [TROUBLESHOOTING.md](https://github.com/steveyegge/beads/blob/main/docs/TROUBLESHOOTING.md) - Common issues
- [FAQ.md](https://github.com/steveyegge/beads/blob/main/docs/FAQ.md) - Frequently asked questions

## Summary

**For simple worktree usage**:
```bash
export BEADS_NO_DAEMON=1
bd init
# Create worktrees and work normally
```

**For teams with protected branches**:
```bash
bd config set sync.branch beads-metadata
bd daemon restart
# Enjoy auto-sync across all worktrees
```

**For parallel agents**:
```bash
bd init --quiet
./examples/git-hooks/install.sh
# Agents claim work, sync via git
```

The key is understanding the daemon limitation with worktrees and choosing the right configuration for your workflow.

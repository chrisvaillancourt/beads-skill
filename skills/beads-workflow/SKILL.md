---
name: beads-workflow
description: Use when working in any project with .beads/ directory, at session start/end, creating/managing issues, or syncing work to git - enforces session close protocol, dependency direction, and core bd commands
---

# Beads Workflow

## Overview

Track work in beads (`bd`), not markdown TODOs or TodoWrite.

**Core principle:** Work is not done until synced and pushed.

**Agent convention:** Always use `--json` flag on bd commands for reliable parsing.

## Session Close Protocol

**CRITICAL: Before claiming "done" or "complete":**

```
[ ] git status              # Check what changed
[ ] git add <files>         # Stage code changes
[ ] bd sync                 # Commit beads changes
[ ] git commit -m "..."     # Commit code
[ ] bd sync                 # Commit any new beads changes
[ ] git push                # Push to remote
```

**Skipping this = losing work.**

## Dependency Direction

Dependencies express "needs" not "comes before".

**Cognitive trap:** Temporal language ("Phase 1 before Phase 2") inverts your thinking.

```bash
# WRONG (temporal): "Phase 1 comes before Phase 2"
bd dep add phase1 phase2

# CORRECT (requirement): "Phase 2 needs Phase 1"
bd dep add phase2 phase1
```

**Verify with `bd blocked`** - tasks should be blocked by their prerequisites.

## Quick Reference

| Action | Command |
|--------|---------|
| Find ready work | `bd ready --json` |
| Find stale work | `bd stale --days 30 --json` |
| Check system | `bd info --json` |
| Claim work | `bd update <id> --status=in_progress --json` |
| Complete work | `bd close <id> --reason="Done" --json` |
| Batch update | `bd update <id1> <id2> --status=in_progress --json` |
| Batch close | `bd close <id1> <id2> --reason="Done" --json` |
| Add dependency | `bd dep add <issue> <depends-on>` |
| Show blocked | `bd blocked --json` |
| Find duplicates | `bd duplicates --json` |
| Force sync | `bd sync` |

## Creating Issues

```bash
bd create "Title" --type=task --description="Why, what, how" --json
bd create "Title" --type=bug -p 1 -l backend,urgent --json
bd create "Title" --deps discovered-from:<parent-id> --json  # Link to parent
```

**Always include descriptions** - issues without context waste future time.

### Issue Types

| Type | Use Case |
|------|----------|
| `bug` | Defects requiring fix |
| `feature` | New functionality |
| `task` | General work (tests, docs, refactoring) |
| `epic` | Large features with subtasks |
| `chore` | Maintenance work |

### Priorities

| Priority | Meaning |
|----------|---------|
| `0` | Critical (security, data loss, build broken) |
| `1` | High (major features, blocking work) |
| `2` | Medium (default) |
| `3` | Low (polish, optimization) |
| `4` | Backlog (future ideas) |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Saying "done" without sync/push | Run full close protocol |
| `bd dep add A B` meaning "A before B" | Think "B needs A" instead |
| Using TodoWrite | Use `bd create` instead |
| Creating issues without descriptions | Always include `--description` |
| Forgetting discovered work link | Use `--deps discovered-from:<id>` |
| Omitting `--json` flag | Always use `--json` for agent operations |

## Red Flags - STOP

- About to say "complete" without running close protocol
- Using temporal language for dependencies ("first", "then", "before")
- Creating markdown TODOs or using TodoWrite
- Ending session without `bd sync` and `git push`

## Session Start

```bash
bd ready --json    # Find unblocked work
bd show <id> --json # Review issue details
```

## Git Worktrees

Daemon mode doesn't work with git worktrees. Use:

```bash
BEADS_NO_DAEMON=1 bd <command>
# Or
bd --no-daemon <command>
```

## When NOT to Use

- Projects without `.beads/` directory
- Quick questions that don't involve task tracking

## References

- [Setup Guide](docs/setup.md) - Installation and daemon configuration
- [CLI Reference](docs/cli-reference.md) - Complete command reference

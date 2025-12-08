---
name: beads-workflow
description: Use when working in any project with .beads/ directory, at session start/end, or when creating/managing issues - enforces session close protocol, dependency direction, and core bd commands
---

# Beads Workflow

## Overview

Track work in beads (`bd`), not markdown TODOs or TodoWrite.

**Core principle:** Work is not done until synced and pushed.

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
| Find ready work | `bd ready` |
| Claim work | `bd update <id> --status=in_progress` |
| Complete work | `bd close <id>` |
| Close multiple | `bd close <id1> <id2> ...` |
| Add dependency | `bd dep add <issue> <depends-on>` |
| Show blocked | `bd blocked` |
| Force sync | `bd sync` |

## Creating Issues

```bash
bd create "Title" --type=task --description="Why, what, how"
bd create "Title" --deps discovered-from:<parent-id>  # Link to parent
```

**Always include descriptions** - issues without context waste future time.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Saying "done" without sync/push | Run full close protocol |
| `bd dep add A B` meaning "A before B" | Think "B needs A" instead |
| Using TodoWrite | Use `bd create` instead |
| Creating issues without descriptions | Always include `--description` |
| Forgetting discovered work link | Use `--deps discovered-from:<id>` |

## Red Flags - STOP

- About to say "complete" without running close protocol
- Using temporal language for dependencies ("first", "then", "before")
- Creating markdown TODOs or using TodoWrite
- Ending session without `bd sync` and `git push`

## Session Start

```bash
bd ready           # Find unblocked work
bd show <id>       # Review issue details
```

## When NOT to Use

- Projects without `.beads/` directory
- Quick questions that don't involve task tracking

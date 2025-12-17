# Agent Instructions

## Project Overview

This is a **thin wrapper** around the [official beads skill](https://github.com/steveyegge/beads/tree/main/skills/beads) for Claude Code users who want the skill without MCP overhead.

## Repository Structure

```
.claude-plugin/
  plugin.json           # Plugin metadata with upstream version tracking
skills/
  beads/
    SKILL.md            # Official skill (mirrored from upstream)
    references/         # Reference docs (mirrored from upstream)
scripts/
  sync-upstream.sh      # Script to update from upstream
.beads/                 # Beads issue tracking for this project
```

## Updating from Upstream

### When to Update

Update this plugin when:
- Beads releases a new version (`brew upgrade bd`)
- You notice the skill content is outdated
- Upstream announces skill changes

### How to Update

```bash
# 1. Update local bd first (optional but recommended)
brew upgrade bd

# 2. Run sync script
./scripts/sync-upstream.sh

# 3. Review changes
git diff

# 4. Commit and push
git add .
git commit -m "chore: sync with beads vX.Y.Z"
git push
```

### What the Sync Script Does

| Step | Automated? | Details |
|------|------------|---------|
| Download SKILL.md | ✅ Yes | Overwrites local copy |
| Discover reference files | ✅ Yes | Uses GitHub API to find all files |
| Download reference files | ✅ Yes | Downloads all discovered files |
| Remove stale files | ✅ Yes | Deletes local files not in upstream |
| Update plugin.json version | ✅ Yes | Sets to local bd version |
| Commit changes | ❌ Manual | You review and commit |

### What Changes the Script Handles

| Change Type | Handled? | Notes |
|-------------|----------|-------|
| Content updates | ✅ | Files are overwritten |
| New files added upstream | ✅ | Auto-discovered via API |
| Files removed upstream | ✅ | Stale files deleted |
| Files renamed upstream | ✅ | Old name deleted, new name downloaded |
| New subdirectories | ❌ | Script only handles `references/` |
| Skill restructuring | ❌ | May need script updates |

### Edge Cases Requiring Manual Intervention

1. **Structural changes**: If upstream reorganizes (e.g., adds `references/advanced/`), update the script.

2. **GitHub API rate limiting**: Script falls back to hardcoded file list. If new files were added, they'll be missed. Re-run later or add to fallback list.

3. **Version mismatch**: Script uses local `bd version`. If you haven't upgraded bd but want latest skill, manually edit plugin.json version.

## What NOT to Do

- Don't modify `skills/beads/SKILL.md` directly - it will be overwritten on sync
- Don't add custom content to `skills/beads/references/` - same reason
- Don't manually edit plugin.json version - let the script handle it

## Git Workflow

```bash
# After syncing upstream
git add .
git commit -m "chore: sync with beads v0.X.Y"
git push
```

## Testing

```bash
./scripts/validate.sh    # Check plugin structure
./scripts/check-drift.sh # Check if upstream has changes
```

CI runs these automatically on push/PR.

## Requirements

The sync script requires:
- `curl` - for downloading files
- `jq` - for JSON parsing (`brew install jq`)
- `bd` - for version detection

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

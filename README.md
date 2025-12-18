# Beads Skill (No MCP)

Thin wrapper around the [official beads skill](https://github.com/steveyegge/beads/tree/main/skills/beads) for Claude Code users who want the comprehensive skill without the MCP server overhead.

## Why This Exists

The official beads plugin includes both a skill AND an MCP server. If you:

- Already have `bd` installed via Homebrew
- Want the comprehensive skill guidance
- Don't want MCP protocol overhead (~10-50k tokens vs ~1-2k for CLI)

This plugin provides just the skill.

## What's Included

| Content | Source |
|---------|--------|
| `skills/beads/SKILL.md` | [Official skill](https://github.com/steveyegge/beads/blob/main/skills/beads/SKILL.md) |
| `skills/beads/references/` | [Official references](https://github.com/steveyegge/beads/tree/main/skills/beads/references) + local additions |
| `templates/` | Team setup guides and automation scripts |

The skill covers:
- bd vs TodoWrite decision framework
- Compaction survival strategies
- Session start/end protocols
- Progress checkpointing triggers
- Field usage (notes, design, acceptance-criteria)
- Dependency patterns
- Issue creation guidelines
- Configuration types (YAML vs database)
- Integration setup automation

## Complete Setup Guide

### 1. Install beads CLI

```bash
brew tap steveyegge/beads
brew install bd
```

### 2. Install Claude Code hooks (global, one-time)

```bash
bd setup claude
```

This installs `SessionStart` and `PreCompact` hooks that run `bd prime` for dynamic context injection.

### 3. Add smart bd wrapper (global, one-time)

Add to `~/.zshrc` (or `~/.bashrc`):

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

This automatically handles both regular repos and git worktree setups - no manual configuration needed per-project.

### 4. Install this plugin

```bash
# Add the repo as a marketplace (one-time setup)
claude plugin marketplace add chrisvaillancourt/beads-skill

# Install the plugin
claude plugin install beads-skill
```

### 5. Initialize beads in your project

```bash
cd your-project
bd init --quiet
bd hooks install
```

### 6. (Optional) Configure sync branch for clean git history

For team projects or if you want beads commits separate from code commits:

```bash
# Configure beads to use a dedicated sync branch
bd config set sync.branch beads-sync

# Create the branch
git checkout -b beads-sync
git checkout main
```

### 7. Apply post-checkout hook workaround (v0.30.2 bug)

See [Known Issues](#known-issues) below.

## Known Issues

### Post-checkout hook error (beads v0.30.2)

**Issue:** [steveyegge/beads#608](https://github.com/steveyegge/beads/issues/608)

After `bd hooks install`, branch switching shows this error:
```
Warning: Failed to sync bd changes after checkout
Error: unknown flag: --no-git-history
```

**Workaround:** Edit `.git/hooks/post-checkout` and change line ~77 from:
```bash
if ! output=$(bd sync --import-only --no-git-history 2>&1); then
```
to:
```bash
if ! output=$(bd sync --import-only 2>&1); then
```

This is a local fix (`.git/hooks/` isn't tracked). When beads releases a fix, run `bd hooks install` to get the corrected version.

## Updating

This plugin mirrors the official beads skill. To update when beads releases new versions:

```bash
cd /path/to/beads-skill
./scripts/sync-upstream.sh
git add .
git commit -m "chore: sync with beads vX.Y.Z"
git push
```

## Upstream

- **Source:** https://github.com/steveyegge/beads/tree/main/skills/beads
- **Version:** 0.30.2
- **License:** MIT (same as upstream)

## Team Setup

For team repos, see [templates/BEADS-TEAM-SETUP.md](templates/BEADS-TEAM-SETUP.md).

For parallel agents with git worktrees, also see [templates/BEADS-PARALLEL-AGENTS.md](templates/BEADS-PARALLEL-AGENTS.md).

### Templates Included

| Template | Purpose |
|----------|---------|
| [templates/BEADS-TEAM-SETUP.md](templates/BEADS-TEAM-SETUP.md) | Complete team setup guide |
| [templates/BEADS-PARALLEL-AGENTS.md](templates/BEADS-PARALLEL-AGENTS.md) | Git worktrees + parallel agents |
| [templates/setup-bd.sh](templates/setup-bd.sh) | Configure integration settings (auto-detects GitHub) |
| [templates/session-setup.sh](templates/session-setup.sh) | Claude Code SessionStart hook (auto-detects GitHub) |
| [templates/claude-settings.json](templates/claude-settings.json) | Example Claude Code hook config |

### Automation with Claude Code Hooks

Automate bd initialization in git worktrees:

1. Copy templates to your project:
   ```bash
   cp /path/to/beads-skill/templates/session-setup.sh scripts/
   chmod +x scripts/session-setup.sh
   ```

2. Add Claude Code hook (`.claude/settings.json`):
   ```json
   {
     "hooks": {
       "SessionStart": [{
         "matcher": "startup",
         "hooks": [{"type": "command", "command": "./scripts/session-setup.sh"}]
       }]
     }
   }
   ```

Now when Claude Code starts in a new worktree, bd is automatically initialized and GitHub integration is auto-configured from the git remote. For Jira integration, also copy and configure `setup-bd.sh`.

## See Also

- [beads repo](https://github.com/steveyegge/beads) - The official beads project
- [bd setup claude](https://github.com/steveyegge/beads/blob/main/docs/INSTALLING.md) - Official hooks setup
- [beads MCP plugin](https://github.com/steveyegge/beads/tree/main/.claude-plugin) - Full plugin with MCP (if you want that)

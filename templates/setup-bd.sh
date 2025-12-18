#!/usr/bin/env bash
# =============================================================================
# setup-bd.sh - Configure bd Integration Settings
# =============================================================================
#
# PURPOSE:
#   Configure database-only integration settings that don't sync via git.
#   Run once per clone or worktree after `bd init`.
#
# WHY THIS IS NEEDED:
#   bd has two types of configuration:
#   1. YAML settings (.beads/config.yaml) - Synced via git
#   2. Database settings (.beads/beads.db) - NOT synced, per-clone/worktree
#
#   Integration settings (github.org, jira.url) are database-only.
#   Each new clone or worktree needs these configured locally.
#
# INSTALLATION:
#   1. Copy to your project: scripts/setup-bd.sh
#   2. Make executable: chmod +x scripts/setup-bd.sh
#   3. Edit the values below for your project
#   4. Run once: ./scripts/setup-bd.sh
#
# AUTOMATION:
#   Combine with session-setup.sh and Claude Code hooks for automatic
#   configuration when agents start in new worktrees.
#
# =============================================================================

set -e

# =============================================================================
# CONFIGURE THESE VALUES FOR YOUR PROJECT
# =============================================================================

# GitHub integration (for linking issues to PRs)
GITHUB_ORG="your-org"           # e.g., "acme-corp"
GITHUB_REPO="your-repo"         # e.g., "my-project"

# Jira integration (optional - comment out if not using Jira)
JIRA_URL="https://your-site.atlassian.net/"

# =============================================================================
# CONFIGURATION (no changes needed below)
# =============================================================================

echo "Configuring bd integrations..."

# GitHub settings
bd config set github.org "$GITHUB_ORG"
bd config set github.repo "$GITHUB_REPO"

# Jira settings (comment out if not using Jira)
if [ -n "$JIRA_URL" ]; then
    bd config set jira.url "$JIRA_URL"
fi

# Verify configuration
echo ""
echo "bd integrations configured:"
bd config list | grep -E "github\.|jira\." || echo "(no matching settings found)"

echo ""
echo "Done. Run 'bd doctor' to verify full setup."

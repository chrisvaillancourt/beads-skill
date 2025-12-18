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
#   3. (Optional) Edit JIRA_URL below if using Jira
#   4. Run once: ./scripts/setup-bd.sh
#
# AUTO-DETECTION:
#   GitHub org and repo are auto-detected from git remote.
#   Override by setting GITHUB_ORG/GITHUB_REPO environment variables.
#
# AUTOMATION:
#   Combine with session-setup.sh and Claude Code hooks for automatic
#   configuration when agents start in new worktrees.
#
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

# Jira integration (optional - set to empty string to skip)
JIRA_URL="https://your-site.atlassian.net/"
# JIRA_URL=""  # Uncomment to disable Jira integration

# =============================================================================
# AUTO-DETECTION (no changes needed below)
# =============================================================================

# Auto-detect GitHub org and repo from git remote (if not already set)
if [ -z "${GITHUB_ORG:-}" ] || [ -z "${GITHUB_REPO:-}" ]; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

    # Parse GitHub URL formats:
    #   SSH:   git@github.com:org/repo.git
    #   HTTPS: https://github.com/org/repo.git
    if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        GITHUB_ORG="${GITHUB_ORG:-${BASH_REMATCH[1]}}"
        GITHUB_REPO="${GITHUB_REPO:-${BASH_REMATCH[2]}}"
    fi
fi

# =============================================================================
# APPLY CONFIGURATION
# =============================================================================

echo "Configuring bd integrations..."

# GitHub settings
if [ -n "${GITHUB_ORG:-}" ] && [ -n "${GITHUB_REPO:-}" ]; then
    bd config set github.org "$GITHUB_ORG"
    bd config set github.repo "$GITHUB_REPO"
    echo "  GitHub: $GITHUB_ORG/$GITHUB_REPO (auto-detected from git remote)"
else
    echo "  GitHub: skipped (not a GitHub repo or couldn't detect)"
fi

# Jira settings
if [ -n "${JIRA_URL:-}" ] && [ "$JIRA_URL" != "https://your-site.atlassian.net/" ]; then
    bd config set jira.url "$JIRA_URL"
    echo "  Jira: $JIRA_URL"
else
    echo "  Jira: skipped (edit JIRA_URL in script to configure)"
fi

# Verify configuration
echo ""
echo "Current bd integrations:"
bd config list | grep -E "github\.|jira\." || echo "  (none configured)"

echo ""
echo "Done. Run 'bd doctor' to verify full setup."

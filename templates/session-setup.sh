#!/bin/bash
# =============================================================================
# session-setup.sh - Claude Code SessionStart Hook for bd (beads)
# =============================================================================
#
# PURPOSE:
#   Automatically initialize bd in git worktrees when Claude Code starts.
#   Ensures each worktree has a working bd database and configured integrations.
#
# INSTALLATION:
#   1. Copy this file to your project: scripts/session-setup.sh
#   2. Make executable: chmod +x scripts/session-setup.sh
#   3. Add Claude Code hook (see templates/claude-settings.json)
#
# WHAT IT DOES:
#   1. Checks if .beads/ directory exists (bd-enabled project)
#   2. Checks if bd CLI is installed
#   3. Initializes bd database if missing (common in new worktrees)
#   4. Configures integration settings if missing
#
# CUSTOMIZATION:
#   - Update the setup-bd.sh path if you place it elsewhere
#   - Add project-specific initialization as needed
#
# =============================================================================

set -e

# Use CLAUDE_PROJECT_DIR if set, otherwise current directory
cd "${CLAUDE_PROJECT_DIR:-.}"

# -----------------------------------------------------------------------------
# Check 1: Is this a bd-enabled project?
# -----------------------------------------------------------------------------
if [ ! -d .beads ]; then
    # Not a bd project - exit silently (this is normal for non-bd projects)
    exit 0
fi

# -----------------------------------------------------------------------------
# Check 2: Is bd CLI installed?
# -----------------------------------------------------------------------------
if ! command -v bd >/dev/null 2>&1; then
    echo "bd not installed - skipping setup"
    echo "Install with: brew tap steveyegge/beads && brew install bd"
    exit 0
fi

# -----------------------------------------------------------------------------
# Check 3: Does this worktree have a database?
# -----------------------------------------------------------------------------
# Each git worktree creates its own .beads/beads.db (gitignored)
# The JSONL files are shared via git, but the database is per-worktree
if [ ! -f .beads/beads.db ]; then
    echo "Initializing bd in worktree..."
    bd init --quiet
    echo "bd initialized"
fi

# -----------------------------------------------------------------------------
# Check 4: Are integrations configured?
# -----------------------------------------------------------------------------
# Integration settings (github.org, jira.url) are database-only.
# They don't sync via git and must be configured per-clone/worktree.
GITHUB_ORG=$(bd config get github.org 2>/dev/null || echo "")

if [ -z "$GITHUB_ORG" ] || [ "$GITHUB_ORG" = "github.org (not set)" ]; then
    # Try to auto-detect from git remote first
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        DETECTED_ORG="${BASH_REMATCH[1]}"
        DETECTED_REPO="${BASH_REMATCH[2]}"
        echo "Auto-configuring bd GitHub integration: $DETECTED_ORG/$DETECTED_REPO"
        bd config set github.org "$DETECTED_ORG"
        bd config set github.repo "$DETECTED_REPO"
    # Fall back to setup script for Jira and other settings
    elif [ -f ./scripts/setup-bd.sh ]; then
        echo "Configuring bd integrations..."
        ./scripts/setup-bd.sh
    elif [ -f ./setup-bd.sh ]; then
        echo "Configuring bd integrations..."
        ./setup-bd.sh
    else
        echo "Note: bd integrations not configured (not a GitHub repo or no setup script)."
    fi
fi

# Success - no output needed for normal operation
exit 0

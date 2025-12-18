#!/usr/bin/env bash
set -euo pipefail

# Check for drift between local skill and upstream
#
# Compares local SKILL.md with upstream to detect if we're out of sync.
# Used in CI to alert when upstream has changes we haven't synced.
#
# Note: This only checks upstream-sourced files. Local additions like
# CONFIGURATION.md are not checked (they don't exist upstream).
# See LOCAL_ADDITIONS in sync-upstream.sh for the list of local files.
#
# Exit codes:
#   0 - No drift detected (or couldn't check)
#   1 - Drift detected

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

UPSTREAM_URL="https://raw.githubusercontent.com/steveyegge/beads/main/skills/beads/SKILL.md"
LOCAL_SKILL="$PROJECT_ROOT/skills/beads/SKILL.md"

# Local additions - files we created that don't exist upstream (not checked for drift)
LOCAL_ADDITIONS=(
    "CONFIGURATION.md"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Checking for upstream drift..."

# Download upstream to temp file
UPSTREAM_TEMP=$(mktemp)
trap "rm -f $UPSTREAM_TEMP" EXIT

if ! curl -sfL "$UPSTREAM_URL" -o "$UPSTREAM_TEMP"; then
    echo -e "${YELLOW}⚠${NC} Could not fetch upstream (network error or rate limit)"
    echo "Skipping drift check"
    exit 0
fi

# Compare
if [ ! -f "$LOCAL_SKILL" ]; then
    echo -e "${RED}✗${NC} Local SKILL.md not found"
    exit 1
fi

if diff -q "$LOCAL_SKILL" "$UPSTREAM_TEMP" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} No drift detected - local SKILL.md matches upstream"
    if [ ${#LOCAL_ADDITIONS[@]} -gt 0 ]; then
        echo -e "  Note: ${#LOCAL_ADDITIONS[@]} local addition(s) not checked: ${LOCAL_ADDITIONS[*]}"
    fi
    exit 0
else
    echo -e "${YELLOW}⚠${NC} Drift detected - local differs from upstream"
    echo ""
    echo "Diff summary:"
    diff --brief "$LOCAL_SKILL" "$UPSTREAM_TEMP" || true
    echo ""
    echo "Lines changed:"
    diff "$LOCAL_SKILL" "$UPSTREAM_TEMP" | head -20 || true
    echo ""
    echo "To sync: ./scripts/sync-upstream.sh"

    # Exit with warning, not error - drift is informational
    # Change to 'exit 1' if you want CI to fail on drift
    exit 0
fi

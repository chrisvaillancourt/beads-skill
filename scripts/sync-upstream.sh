#!/usr/bin/env bash
set -euo pipefail

# Sync beads skill from upstream steveyegge/beads repo
#
# This script mirrors the official beads skill to this plugin.
# Run whenever beads releases a new version.
#
# What it does:
#   1. Fetches the list of reference files from GitHub API
#   2. Downloads SKILL.md and all reference files
#   3. Removes any local files that no longer exist upstream
#   4. Updates version in plugin.json
#
# Requirements:
#   - curl
#   - jq (for JSON parsing and plugin.json updates)
#   - bd (for version detection)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SKILL_DIR="$PROJECT_ROOT/skills/beads"
REFS_DIR="$SKILL_DIR/references"

UPSTREAM_BASE="https://raw.githubusercontent.com/steveyegge/beads/main/skills/beads"
UPSTREAM_API="https://api.github.com/repos/steveyegge/beads/contents/skills/beads/references"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

echo "========================================="
echo "Syncing beads skill from upstream"
echo "========================================="
echo ""

# Check requirements
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Install with: brew install jq"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed."
    exit 1
fi

# Get versions
LOCAL_BD_VERSION=$(bd version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
CURRENT_PLUGIN_VERSION=$(jq -r '.version // "unknown"' "$PROJECT_ROOT/.claude-plugin/plugin.json")

echo "Local bd version:     $LOCAL_BD_VERSION"
echo "Current plugin version: $CURRENT_PLUGIN_VERSION"
echo ""

# Create directories if needed
mkdir -p "$REFS_DIR"

# Download main skill file
echo "Downloading SKILL.md..."
if curl -sfL "$UPSTREAM_BASE/SKILL.md" -o "$SKILL_DIR/SKILL.md"; then
    log_info "SKILL.md ($(wc -l < "$SKILL_DIR/SKILL.md" | tr -d ' ') lines)"
else
    log_error "Failed to download SKILL.md"
    exit 1
fi

# Fetch list of reference files from GitHub API
echo ""
echo "Fetching reference file list from GitHub API..."
REFS_JSON=$(curl -sf "$UPSTREAM_API" || echo "[]")

if [ "$REFS_JSON" = "[]" ]; then
    log_warn "Could not fetch reference list from API, using fallback list"
    # Fallback to known files if API fails (rate limiting, etc.)
    UPSTREAM_REFS=("BOUNDARIES.md" "CLI_REFERENCE.md" "DEPENDENCIES.md" "ISSUE_CREATION.md" "RESUMABILITY.md" "STATIC_DATA.md" "WORKFLOWS.md")
else
    # Parse file names from API response
    mapfile -t UPSTREAM_REFS < <(echo "$REFS_JSON" | jq -r '.[] | select(.type == "file") | .name')
    log_info "Found ${#UPSTREAM_REFS[@]} reference files upstream"
fi

# Download reference files
echo ""
echo "Downloading reference files..."
DOWNLOADED=()
for ref in "${UPSTREAM_REFS[@]}"; do
    if curl -sfL "$UPSTREAM_BASE/references/$ref" -o "$REFS_DIR/$ref"; then
        log_info "$ref"
        DOWNLOADED+=("$ref")
    else
        log_error "Failed to download $ref"
    fi
done

# Remove local files that no longer exist upstream
echo ""
echo "Checking for stale files..."
STALE_COUNT=0
for local_file in "$REFS_DIR"/*.md; do
    [ -e "$local_file" ] || continue
    filename=$(basename "$local_file")
    found=false
    for upstream_ref in "${UPSTREAM_REFS[@]}"; do
        if [ "$filename" = "$upstream_ref" ]; then
            found=true
            break
        fi
    done
    if [ "$found" = false ]; then
        log_warn "Removing stale file: $filename"
        rm "$local_file"
        ((STALE_COUNT++))
    fi
done
if [ $STALE_COUNT -eq 0 ]; then
    log_info "No stale files found"
fi

# Update version in plugin.json and marketplace.json
echo ""
echo "Updating plugin.json and marketplace.json..."
tmp=$(mktemp)

# Update plugin.json - version and description with upstream version
jq --arg v "$LOCAL_BD_VERSION" '
  .version = $v |
  .description = "Beads skill mirror for Claude Code - issue tracking without MCP overhead. Mirrors steveyegge/beads skills/beads/ content (upstream version \($v))."
' "$PROJECT_ROOT/.claude-plugin/plugin.json" > "$tmp"
mv "$tmp" "$PROJECT_ROOT/.claude-plugin/plugin.json"
log_info "plugin.json version set to $LOCAL_BD_VERSION"

# Update marketplace.json - version in plugins array
tmp=$(mktemp)
jq --arg v "$LOCAL_BD_VERSION" '.plugins[0].version = $v' "$PROJECT_ROOT/.claude-plugin/marketplace.json" > "$tmp"
mv "$tmp" "$PROJECT_ROOT/.claude-plugin/marketplace.json"
log_info "marketplace.json version set to $LOCAL_BD_VERSION"

# Summary
echo ""
echo "========================================="
echo "Sync complete!"
echo "========================================="
echo ""
echo "  SKILL.md:    $(wc -l < "$SKILL_DIR/SKILL.md" | tr -d ' ') lines"
echo "  References:  ${#DOWNLOADED[@]} files"
echo "  Stale removed: $STALE_COUNT"
echo ""

# Show git diff summary
if command -v git &> /dev/null && [ -d "$PROJECT_ROOT/.git" ]; then
    echo "Changes detected:"
    git -C "$PROJECT_ROOT" diff --stat skills/ .claude-plugin/ 2>/dev/null || true
    echo ""
fi

echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit: git add . && git commit -m 'chore: sync with beads v$LOCAL_BD_VERSION'"
echo "  3. Push: git push"

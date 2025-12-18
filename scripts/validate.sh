#!/usr/bin/env bash
set -euo pipefail

# Validate plugin structure and content
#
# Checks:
#   1. plugin.json is valid JSON with required fields
#   2. SKILL.md exists and has valid front matter
#   3. All reference files exist
#   4. Links in SKILL.md to references are valid
#
# Exit codes:
#   0 - All validations passed
#   1 - Validation failed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_pass() { echo -e "${GREEN}✓${NC} $1"; }
log_fail() { echo -e "${RED}✗${NC} $1"; ERRORS=$((ERRORS+1)); }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; WARNINGS=$((WARNINGS+1)); }
log_info() { echo -e "  $1"; }

echo "========================================="
echo "Validating beads-skill plugin"
echo "========================================="
echo ""

# -----------------------------------------------------------------------------
# 0. Check version alignment (bd version vs plugin version)
# -----------------------------------------------------------------------------
echo "Checking version alignment..."

if command -v bd &> /dev/null; then
    LOCAL_BD_VERSION=$(bd version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
    PLUGIN_VERSION=$(jq -r '.version // ""' "$PROJECT_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "")

    if [ -n "$LOCAL_BD_VERSION" ] && [ -n "$PLUGIN_VERSION" ]; then
        if [ "$LOCAL_BD_VERSION" = "$PLUGIN_VERSION" ]; then
            log_pass "Plugin version matches bd version: $PLUGIN_VERSION"
        elif [ "$(printf '%s\n' "$PLUGIN_VERSION" "$LOCAL_BD_VERSION" | sort -V | head -1)" = "$PLUGIN_VERSION" ]; then
            # Plugin version is lower (behind)
            log_warn "Plugin version ($PLUGIN_VERSION) is behind bd version ($LOCAL_BD_VERSION)"
            log_info "Run ./scripts/sync-upstream.sh to update"
        else
            # Plugin version is higher (ahead) - unusual
            log_warn "Plugin version ($PLUGIN_VERSION) is ahead of bd version ($LOCAL_BD_VERSION)"
        fi
    else
        log_warn "Could not determine versions for comparison"
    fi
else
    log_warn "bd not installed, skipping version check"
fi

echo ""

# -----------------------------------------------------------------------------
# 1. Validate plugin.json
# -----------------------------------------------------------------------------
echo "Checking plugin.json..."

PLUGIN_JSON="$PROJECT_ROOT/.claude-plugin/plugin.json"

if [ ! -f "$PLUGIN_JSON" ]; then
    log_fail "plugin.json not found at $PLUGIN_JSON"
else
    # Check valid JSON
    if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
        log_fail "plugin.json is not valid JSON"
    else
        log_pass "plugin.json is valid JSON"

        # Check required fields
        for field in name version description; do
            value=$(jq -r ".$field // empty" "$PLUGIN_JSON")
            if [ -z "$value" ]; then
                log_fail "plugin.json missing required field: $field"
            else
                log_pass "plugin.json has $field: $value"
            fi
        done

    fi
fi

# -----------------------------------------------------------------------------
# 1b. Validate marketplace.json
# -----------------------------------------------------------------------------
echo ""
echo "Checking marketplace.json..."

MARKETPLACE_JSON="$PROJECT_ROOT/.claude-plugin/marketplace.json"

if [ ! -f "$MARKETPLACE_JSON" ]; then
    log_fail "marketplace.json not found at $MARKETPLACE_JSON"
else
    # Check valid JSON
    if ! jq empty "$MARKETPLACE_JSON" 2>/dev/null; then
        log_fail "marketplace.json is not valid JSON"
    else
        log_pass "marketplace.json is valid JSON"

        # Check required fields
        for field in name description; do
            value=$(jq -r ".$field // empty" "$MARKETPLACE_JSON")
            if [ -z "$value" ]; then
                log_fail "marketplace.json missing required field: $field"
            else
                log_pass "marketplace.json has $field"
            fi
        done

        # Check plugins array
        plugin_count=$(jq '.plugins | length' "$MARKETPLACE_JSON")
        if [ "$plugin_count" -eq 0 ]; then
            log_fail "marketplace.json has no plugins defined"
        else
            log_pass "marketplace.json has $plugin_count plugin(s)"
        fi

        # Check version consistency
        plugin_version=$(jq -r '.version // empty' "$PLUGIN_JSON")
        marketplace_plugin_version=$(jq -r '.plugins[0].version // empty' "$MARKETPLACE_JSON")
        if [ "$plugin_version" = "$marketplace_plugin_version" ]; then
            log_pass "Versions match: $plugin_version"
        else
            log_warn "Version mismatch: plugin.json=$plugin_version, marketplace.json=$marketplace_plugin_version"
        fi
    fi
fi

# -----------------------------------------------------------------------------
# 2. Validate SKILL.md
# -----------------------------------------------------------------------------
echo ""
echo "Checking SKILL.md..."

SKILL_MD="$PROJECT_ROOT/skills/beads/SKILL.md"

if [ ! -f "$SKILL_MD" ]; then
    log_fail "SKILL.md not found at $SKILL_MD"
else
    log_pass "SKILL.md exists"

    # Check file has content
    line_count=$(wc -l < "$SKILL_MD" | tr -d ' ')
    if [ "$line_count" -lt 100 ]; then
        log_warn "SKILL.md seems short ($line_count lines)"
    else
        log_pass "SKILL.md has $line_count lines"
    fi

    # Check front matter exists
    if head -1 "$SKILL_MD" | grep -q "^---"; then
        log_pass "SKILL.md has front matter"

        # Extract and validate front matter (between first and second ---)
        front_matter=$(awk '/^---$/{if(++n==2)exit}n==1' "$SKILL_MD")

        # Check for name field
        if echo "$front_matter" | grep -q "^name:"; then
            skill_name=$(echo "$front_matter" | grep "^name:" | sed 's/name:[[:space:]]*//')
            log_pass "SKILL.md has name: $skill_name"
        else
            log_fail "SKILL.md front matter missing 'name' field"
        fi

        # Check for description field
        if echo "$front_matter" | grep -q "^description:"; then
            log_pass "SKILL.md has description"
        else
            log_fail "SKILL.md front matter missing 'description' field"
        fi
    else
        log_fail "SKILL.md missing front matter (should start with ---)"
    fi
fi

# -----------------------------------------------------------------------------
# 3. Validate reference files
# -----------------------------------------------------------------------------
echo ""
echo "Checking reference files..."

REFS_DIR="$PROJECT_ROOT/skills/beads/references"

if [ ! -d "$REFS_DIR" ]; then
    log_fail "References directory not found at $REFS_DIR"
else
    ref_count=$(find "$REFS_DIR" -name "*.md" | wc -l | tr -d ' ')
    if [ "$ref_count" -eq 0 ]; then
        log_fail "No reference files found in $REFS_DIR"
    else
        log_pass "Found $ref_count reference files"

        # List each reference file
        for ref_file in "$REFS_DIR"/*.md; do
            [ -e "$ref_file" ] || continue
            filename=$(basename "$ref_file")
            file_lines=$(wc -l < "$ref_file" | tr -d ' ')
            if [ "$file_lines" -lt 10 ]; then
                log_warn "$filename seems short ($file_lines lines)"
            else
                log_pass "$filename ($file_lines lines)"
            fi
        done
    fi
fi

# -----------------------------------------------------------------------------
# 4. Validate internal links
# -----------------------------------------------------------------------------
echo ""
echo "Checking internal links in SKILL.md..."

if [ -f "$SKILL_MD" ]; then
    # Extract markdown links to references/ - capture just the path
    # Pattern: [text](references/FILE.md) or [text](references/FILE.md#anchor)
    links=$(grep -oE '\(references/[^)]+\)' "$SKILL_MD" 2>/dev/null | sed 's/[()]//g' | sed 's/#.*//' | sort -u || true)

    if [ -z "$links" ]; then
        log_warn "No links to references/ found in SKILL.md"
    else
        link_count=$(echo "$links" | wc -l | tr -d ' ')
        log_info "Found $link_count unique links to references/"

        # Check each link
        broken=0
        while IFS= read -r path; do
            [ -z "$path" ] && continue
            full_path="$PROJECT_ROOT/skills/beads/$path"

            if [ ! -f "$full_path" ]; then
                log_fail "Broken link: $path"
                ((broken++))
            fi
        done <<< "$links"

        if [ "$broken" -eq 0 ]; then
            log_pass "All internal links valid"
        fi
    fi
fi

# -----------------------------------------------------------------------------
# 5. Check for required files
# -----------------------------------------------------------------------------
echo ""
echo "Checking required project files..."

required_files=(
    "README.md"
    "AGENTS.md"
    "CLAUDE.md"
    "scripts/sync-upstream.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        log_pass "$file exists"
    else
        log_fail "$file missing"
    fi
done

# -----------------------------------------------------------------------------
# 6. Check template files
# -----------------------------------------------------------------------------
echo ""
echo "Checking template files..."

TEMPLATES_DIR="$PROJECT_ROOT/templates"

if [ ! -d "$TEMPLATES_DIR" ]; then
    log_fail "Templates directory not found at $TEMPLATES_DIR"
else
    # Required template files
    required_templates=(
        "BEADS-TEAM-SETUP.md"
        "BEADS-PARALLEL-AGENTS.md"
        "setup-bd.sh"
        "session-setup.sh"
        "claude-settings.json"
    )

    for template in "${required_templates[@]}"; do
        template_path="$TEMPLATES_DIR/$template"
        if [ -f "$template_path" ]; then
            # Check if shell scripts are executable
            if [[ "$template" == *.sh ]]; then
                if [ -x "$template_path" ]; then
                    log_pass "$template (executable)"
                else
                    log_warn "$template exists but not executable"
                fi
            else
                log_pass "$template"
            fi
        else
            log_fail "$template missing"
        fi
    done
fi

# -----------------------------------------------------------------------------
# 7. Check local additions (files we created, not from upstream)
# -----------------------------------------------------------------------------
echo ""
echo "Checking local additions..."

local_additions=(
    "skills/beads/references/CONFIGURATION.md"
)

for local_file in "${local_additions[@]}"; do
    if [ -f "$PROJECT_ROOT/$local_file" ]; then
        log_pass "$local_file (local addition)"
    else
        log_warn "$local_file missing (local addition, not from upstream)"
    fi
done

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}Validation passed!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}$WARNINGS warning(s)${NC}"
    fi
    exit 0
else
    echo -e "${RED}Validation failed: $ERRORS error(s)${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}$WARNINGS warning(s)${NC}"
    fi
    exit 1
fi

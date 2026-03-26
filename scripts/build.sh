#!/usr/bin/env bash
set -euo pipefail

# build.sh — Generates install/ files and README prompt table from prompts/ source files.
# Usage:
#   bash scripts/build.sh              # Full build (generate + validate)
#   bash scripts/build.sh --validate   # Validate only, no generation
#   bash scripts/build.sh --check      # Check if install/ and README are in sync (CI use)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROMPTS_DIR="$ROOT/prompts"
INSTALL_DIR="$ROOT/install"
README="$ROOT/README.md"
ERRORS=0

# --- Frontmatter parser ---
# Extracts a YAML frontmatter value from a prompt file.
# Usage: get_frontmatter "file.md" "field_name"
get_frontmatter() {
    local file="$1" field="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${field}:" | head -1 | sed "s/^${field}: *//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
}

# Extracts tags as a space-separated list (strips YAML array syntax).
get_tags() {
    local file="$1"
    get_frontmatter "$file" "tags" | tr -d '[]' | tr ',' '\n' | sed 's/^ *//' | sed 's/ *$//'
}

# --- Instruction block extractor ---
# Extracts content between the two --- markers in the body (after frontmatter).
# The frontmatter is between lines 1's --- and the closing ---.
# The instruction block is between the NEXT two --- markers after that.
extract_instruction_block() {
    local file="$1"
    awk '
    BEGIN { fm_open=0; fm_closed=0; block_open=0; block_closed=0 }
    /^---$/ {
        if (!fm_open) { fm_open=1; next }
        if (fm_open && !fm_closed) { fm_closed=1; next }
        if (fm_closed && !block_open) { block_open=1; next }
        if (block_open && !block_closed) { block_closed=1; next }
    }
    block_open && !block_closed { print }
    ' "$file"
}

# --- Validation ---
validate_prompt() {
    local file="$1"
    local filename basename slug category dir_category

    filename="$(basename "$file")"
    basename="${filename%.md}"
    dir_category="$(basename "$(dirname "$file")")"

    slug="$(get_frontmatter "$file" "slug")"
    category="$(get_frontmatter "$file" "category")"
    local title works_with severity one_liner
    title="$(get_frontmatter "$file" "title")"
    works_with="$(get_frontmatter "$file" "works_with")"
    severity="$(get_frontmatter "$file" "severity")"
    one_liner="$(get_frontmatter "$file" "one_liner")"

    # Required fields
    for field in title slug category works_with severity one_liner; do
        local val="${!field}"
        if [[ -z "$val" ]]; then
            echo "ERROR: $file — missing required field: $field"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Slug matches filename
    if [[ -n "$slug" && "$slug" != "$basename" ]]; then
        echo "ERROR: $file — slug '$slug' does not match filename '$basename'"
        ERRORS=$((ERRORS + 1))
    fi

    # Category matches directory
    if [[ -n "$category" && "$category" != "$dir_category" ]]; then
        echo "ERROR: $file — category '$category' does not match directory '$dir_category'"
        ERRORS=$((ERRORS + 1))
    fi

    # Instruction block exists
    local block
    block="$(extract_instruction_block "$file")"
    if [[ -z "$block" ]]; then
        echo "ERROR: $file — no instruction block found (need two --- markers in body)"
        ERRORS=$((ERRORS + 1))
    fi

    # one_liner length
    if [[ -n "$one_liner" && ${#one_liner} -gt 80 ]]; then
        echo "WARN: $file — one_liner exceeds 80 chars (${#one_liner})"
    fi
}

# --- Collect all prompt files ---
collect_prompts() {
    find "$PROMPTS_DIR" -name "*.md" -mindepth 2 -type f | sort
}

# --- Generate install files ---
generate_install() {
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    local tmpdir
    tmpdir="$(mktemp -d)"

    while IFS= read -r file; do
        local slug category
        slug="$(get_frontmatter "$file" "slug")"
        category="$(get_frontmatter "$file" "category")"

        # Extract instruction block
        local block
        block="$(extract_instruction_block "$file")"
        if [[ -z "$block" ]]; then
            echo "SKIP: $file — no instruction block"
            continue
        fi

        # Individual install file
        printf '%s\n' "$block" > "$INSTALL_DIR/${slug}.md"

        # Accumulate for all.md (append to temp file)
        if [[ -f "$tmpdir/all.md" ]]; then
            printf '\n\n%s\n' "$block" >> "$tmpdir/all.md"
        else
            printf '%s\n' "$block" > "$tmpdir/all.md"
        fi

        # Accumulate for category bundle (append to temp file per category)
        if [[ -f "$tmpdir/cat-${category}.md" ]]; then
            printf '\n\n%s\n' "$block" >> "$tmpdir/cat-${category}.md"
        else
            printf '%s\n' "$block" > "$tmpdir/cat-${category}.md"
        fi

        # Accumulate for essentials
        local tags
        tags="$(get_tags "$file")"
        if echo "$tags" | grep -q "^essential$"; then
            if [[ -f "$tmpdir/essentials.md" ]]; then
                printf '\n\n%s\n' "$block" >> "$tmpdir/essentials.md"
            else
                printf '%s\n' "$block" > "$tmpdir/essentials.md"
            fi
        fi

    done < <(collect_prompts)

    # Write bundle files from temp accumulation
    [[ -f "$tmpdir/all.md" ]] && cp "$tmpdir/all.md" "$INSTALL_DIR/all.md"
    [[ -f "$tmpdir/essentials.md" ]] && cp "$tmpdir/essentials.md" "$INSTALL_DIR/essentials.md"

    for catfile in "$tmpdir"/cat-*.md; do
        [[ -f "$catfile" ]] || continue
        local catname
        catname="$(basename "$catfile" .md)"
        catname="${catname#cat-}"
        cp "$catfile" "$INSTALL_DIR/${catname}.md"
    done

    rm -rf "$tmpdir"

    echo "Generated $(find "$INSTALL_DIR" -name "*.md" | wc -l | tr -d ' ') install files"
}

# --- Generate README table ---
generate_readme_table() {
    local table_file
    table_file="$(mktemp)"
    local current_category=""

    while IFS= read -r file; do
        local slug category title one_liner
        slug="$(get_frontmatter "$file" "slug")"
        category="$(get_frontmatter "$file" "category")"
        title="$(get_frontmatter "$file" "title")"
        one_liner="$(get_frontmatter "$file" "one_liner")"

        # Category header (title-cased)
        if [[ "$category" != "$current_category" ]]; then
            local display_cat
            display_cat="$(echo "$category" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')"
            [[ -s "$table_file" ]] && echo "" >> "$table_file"
            echo "" >> "$table_file"
            echo "### ${display_cat}" >> "$table_file"
            echo "" >> "$table_file"
            echo "| Prompt | What It Solves | Install |" >> "$table_file"
            echo "|--------|---------------|---------|" >> "$table_file"
            current_category="$category"
        fi

        echo "| [${title}](prompts/${category}/${slug}.md) | ${one_liner} | [install](install/${slug}.md) |" >> "$table_file"
    done < <(collect_prompts)

    # Replace content between markers in README using temp file approach
    if grep -q "<!-- PROMPT_TABLE_START -->" "$README" && grep -q "<!-- PROMPT_TABLE_END -->" "$README"; then
        local tmp="$README.tmp"
        local in_block=0
        while IFS= read -r line; do
            if [[ "$line" == *"<!-- PROMPT_TABLE_START -->"* ]]; then
                echo "$line" >> "$tmp"
                cat "$table_file" >> "$tmp"
                in_block=1
                continue
            fi
            if [[ "$line" == *"<!-- PROMPT_TABLE_END -->"* ]]; then
                in_block=0
            fi
            if [[ $in_block -eq 0 ]]; then
                echo "$line" >> "$tmp"
            fi
        done < "$README"
        mv "$tmp" "$README"
        echo "README prompt table updated"
    else
        echo "WARN: README missing PROMPT_TABLE_START/END markers — skipping table generation"
    fi

    rm -f "$table_file"
}

# --- Main ---
MODE="${1:-build}"

case "$MODE" in
    --validate|--validate-only)
        echo "Validating prompt files..."
        while IFS= read -r file; do
            validate_prompt "$file"
        done < <(collect_prompts)
        if [[ $ERRORS -gt 0 ]]; then
            echo "FAILED: $ERRORS validation errors"
            exit 1
        fi
        echo "All prompts valid"
        ;;
    --check)
        # Generate to temp, compare with existing
        TEMP_INSTALL="$(mktemp -d)"
        INSTALL_DIR="$TEMP_INSTALL" generate_install 2>/dev/null
        if diff -rq "$TEMP_INSTALL" "$ROOT/install" > /dev/null 2>&1; then
            echo "install/ is in sync"
        else
            echo "STALE: install/ is out of sync. Run 'make build' to regenerate."
            rm -rf "$TEMP_INSTALL"
            exit 1
        fi
        rm -rf "$TEMP_INSTALL"
        ;;
    build|*)
        echo "Validating..."
        while IFS= read -r file; do
            validate_prompt "$file"
        done < <(collect_prompts)
        if [[ $ERRORS -gt 0 ]]; then
            echo "FAILED: $ERRORS validation errors — fix before building"
            exit 1
        fi
        echo "Generating install files..."
        generate_install
        echo "Generating README table..."
        generate_readme_table
        echo "Build complete"
        ;;
esac

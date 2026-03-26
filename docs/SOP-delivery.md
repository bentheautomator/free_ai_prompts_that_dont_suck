# SOP: Prompt Delivery

Standard operating procedure for writing, validating, and shipping new prompts. This is the internal playbook — follow it every time.

## Prerequisites

- Repo cloned: `~/git/bentheautomator/free_ai_prompts_that_dont_suck`
- `make build` works (bash, awk, sed available)
- Push access to the repo

## Phase 1: Identify the Failure Mode

Every prompt starts with a real problem. Before writing anything:

1. **Name the failure.** One sentence: "AI does X when it should do Y."
2. **Confirm it's real.** Has this actually happened? To you? To someone you can cite? If it's hypothetical, stop — we don't ship vibes.
3. **Check for duplicates.** Run `make validate` and scan existing prompts. If the failure mode is already covered, strengthen the existing prompt instead.
4. **Pick the category.** Which directory does this belong in?

| Category | Failure Domain |
|----------|---------------|
| `code-safety` | Data loss, destructive actions, unauthorized changes |
| `code-quality` | Bad edits, pattern violations, hallucinated code |
| `instruction-following` | Skipping rules, ignoring processes |
| `git` | Unsafe git operations, bad commits |
| `communication` | Acting without telling you, silent changes |
| `context` | Hallucinated assumptions, unverified claims |
| `scope` | Over-engineering, feature creep, going off-task |

If none fit, create a new category directory. The build script discovers it automatically.

## Phase 2: Write the Prompt File

### File location
```
prompts/<category>/<slug>.md
```

Slug is lowercase-kebab-case, matches the filename exactly (without .md).

### Writing order

Write in this order — it prevents backtracking:

1. **Frontmatter first.** Forces you to crystallize the title, one-liner, severity, and tags before writing prose. If you can't write a clear `one_liner` under 80 chars, you don't understand the failure mode well enough yet.

2. **The Instruction block second.** This is the product — what people actually paste into their config. Write it standalone: no references to "as described above," no assumed context. It must work if someone reads nothing else.

3. **The Problem section third.** Now explain what goes wrong without this instruction. Be specific. Name the behavior, describe the consequence, explain why AI assistants do it by default.

4. **Why It Works fourth.** Name the mechanism. Not "it helps" — explain *what cognitive or behavioral pattern it exploits*. Three mechanisms that actually work:
   - **Naming the rationalization** — tell the AI what the bad thought looks like before it thinks it
   - **Reframing a concept** — redefine a word the AI misinterprets (e.g., "fast" means efficient, not fewer steps)
   - **Removing ambiguity** — eliminate the loophole the AI would exploit

5. **Origin last.** Real incident. Optional but strongly encouraged. Specificity builds credibility.

### Frontmatter reference

```yaml
---
title: Human Readable Title         # Exact title, used in README table
slug: human-readable-title           # Must match filename
category: code-safety                # Must match parent directory
tags: [universal, essential]         # essential = included in starter pack
works_with: all                      # all | [claude-code, cursor, windsurf]
severity: critical                   # critical | high | medium
one_liner: "What it prevents in <80 chars"
---
```

### Severity guide

| Severity | When to Use |
|----------|------------|
| `critical` | Can cause data loss, security issues, or hours of wasted work |
| `high` | Causes bugs, broken code, or significant friction |
| `medium` | Causes annoyance, inconsistency, or minor quality issues |

### Tags

- `universal` — works across all AI coding assistants
- `essential` — included in the starter pack (`install/essentials.md`)
- `foundational` — core behavior that other prompts build on
- Add domain tags as needed: `git`, `security`, `testing`, etc.

### Quality checklist (before moving to Phase 3)

- [ ] Frontmatter complete, all 7 fields present
- [ ] `slug` matches filename
- [ ] `category` matches directory
- [ ] `one_liner` under 80 characters
- [ ] Instruction block is between two `---` markers
- [ ] Instruction block is fully standalone (no "as mentioned above")
- [ ] At least one red flag pattern listed (thought patterns that precede the failure)
- [ ] Problem section names a specific, real behavior — not a vague concern
- [ ] Why It Works names a mechanism — not just "it helps"
- [ ] Tone is direct, practitioner-level, no hedging

## Phase 3: Build and Validate

```bash
# Validate frontmatter and structure
make validate

# Generate install/ files and README table
make build
```

Fix any errors. The build script catches:
- Missing frontmatter fields
- Slug/filename mismatches
- Category/directory mismatches
- Missing instruction blocks
- one_liner over 80 chars (warning)

### Verify generated output

After `make build`, spot-check:

1. **Individual install file exists:** `install/<slug>.md`
2. **Category bundle includes your prompt:** `install/<category>.md`
3. **Essentials bundle** (if tagged `essential`): `install/essentials.md`
4. **README table** has your prompt in the right category section

## Phase 4: Commit

One prompt per commit. Generated files go in the same commit.

```bash
# Stage the prompt and all generated files
git add prompts/<category>/<slug>.md install/ README.md

# Commit
git commit -m "docs(prompts): add <slug>

- <one sentence: what failure mode this prevents>
- Category: <category>, Severity: <severity>
- install/ and README regenerated via make build

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Batch delivery

When shipping multiple prompts in one session:

1. Write all prompts first (Phase 2 for each)
2. Run `make build` once after all prompts are written
3. One commit per prompt, or group by category if they're tightly related
4. Push after all commits

## Phase 5: Push and Verify

```bash
git push
```

After push, verify on GitHub:
- [ ] README table renders correctly with new prompt
- [ ] Prompt file renders correctly (frontmatter doesn't bleed into content)
- [ ] Raw install URL works: `https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/<slug>.md`

### Test the install flow

Paste this into a fresh AI session to verify the install works end-to-end:

```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/<slug>.md and show me its contents.
```

## Quick Reference: Full Delivery Pipeline

```
Identify failure mode
  → Check for duplicates
  → Pick category

Write prompt file
  → Frontmatter → Instruction block → Problem → Why It Works → Origin
  → Quality checklist pass

Build
  → make validate (fix errors)
  → make build (generate install/ + README)
  → Spot-check output

Commit
  → git add (prompt + install/ + README.md)
  → One prompt per commit
  → Conventional commit format

Push and verify
  → README renders
  → Raw URL works
  → Install flow works
```

## Anti-Patterns

| Don't | Why |
|-------|-----|
| Write the Problem section first | You'll write a blog post instead of an instruction |
| Skip the red flags section | Red flags are what actually prevent the behavior |
| Say "it helps" in Why It Works | Name the mechanism or don't bother |
| Hand-edit install/ files | They'll be overwritten by `make build` |
| Ship a prompt without a real origin story | Hypothetical prompts don't survive contact with reality |
| Commit install/ changes without source changes | Breaks the single-source-of-truth contract |
| Tag everything as `essential` | The starter pack should be 5-8 prompts, not 50 |

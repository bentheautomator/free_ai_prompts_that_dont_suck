# Free AI Prompts That Don't Suck — Project Rules

## What This Repo Is

A public collection of battle-tested system prompts for AI coding assistants. Every prompt solves a specific, documented failure mode. No vibes. No fluff.

## README Is the Product

The README is the storefront. Every prompt in `prompts/` MUST have a corresponding row in the README table. If a prompt exists but isn't in the table, nobody will find it.

### When Adding a New Prompt

1. Create the file in `prompts/<slug>.md`
2. **Immediately** add a row to the `## The Prompts` table in `README.md`
3. Format: `| [Title](prompts/<slug>.md) | One-sentence description of the failure mode it prevents |`
4. Keep the table alphabetically sorted by prompt name

### When Removing or Renaming a Prompt

1. Update or remove the README table row
2. Update any cross-references in other prompt files

### Never

- Add a prompt file without updating the README table
- Leave a broken link in the README table
- Add a prompt that doesn't follow the template (see below)

## Prompt File Template

Every file in `prompts/` must have:

```
# Title

> **Works with:** All AI coding assistants (or list specific ones)

> One-line description of what it prevents.

## The Problem         — What goes wrong without this instruction
## The Instruction     — Copy-paste block between horizontal rules (---)
## Why It Works        — What makes it effective (name the mechanism)
## Origin              — Real incident that created this rule (optional but encouraged)
```

## Tone

- Direct. No hedging.
- Written for practitioners, not beginners.
- If it's true and it's funny, say it.
- Evidence over vibes. Every prompt traces back to a real failure.

## Commits

- Conventional commits: `docs(prompts): add <name>` for new prompts
- One prompt per commit when possible
- README update goes in the same commit as the prompt it references

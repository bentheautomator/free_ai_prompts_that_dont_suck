# Free AI Prompts That Don't Suck

System prompts, instructions, and rules for AI coding assistants — Claude Code, Cursor, Windsurf, Copilot, Cline, Aider, and anything else that reads a system prompt — that actually solve real problems.

No fluff. No "be concise and helpful." These are battle-tested instructions born from thousands of hours of AI-assisted development where something went wrong, someone figured out why, and wrote a rule so it never happens again.

## Quick Install (Let Your AI Do It)

Paste this into your AI assistant. It will fetch the instructions and add them to your config:

**Install the essentials starter pack:**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/essentials.md and append its contents to my project instructions file.
```

**Install everything:**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/all.md and append its contents to my project instructions file.
```

**Install by category:**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/code-safety.md and append its contents to my project instructions file.
```

**Install a single prompt:**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/never-skip-instructions.md and append its contents to my project instructions file.
```

Your AI already knows where its own config file lives. It'll put the rules in the right place.

## Manual Install

If you prefer to copy-paste yourself, each file in `prompts/` has the full explanation with a clearly marked instruction block between horizontal rules. Each file in `install/` has just the instruction — ready to paste.

**Claude Code:** Copy into your `CLAUDE.md` (project-level) or `~/.claude/CLAUDE.md` (global).

**Cursor:** Copy into `.cursorrules` in your project root.

**Windsurf:** Copy into `.windsurfrules` in your project root.

**Copilot:** Copy into `.github/copilot-instructions.md`.

**Cline / Aider / Others:** Copy into whatever file your AI assistant reads for system instructions.

**Placement matters.** Put important rules near the top. AI models weight instructions at the beginning of their context more heavily than those buried at the bottom.

## The Prompts

<!-- PROMPT_TABLE_START -->

### Code Quality

| Prompt | What It Solves |
|--------|---------------|
| [Read Before Edit](prompts/code-quality/read-before-edit.md) | AI making blind edits based on assumptions instead of reading the file |


### Code Safety

| Prompt | What It Solves |
|--------|---------------|
| [Ask Before Deleting Code](prompts/code-safety/ask-before-deleting-code.md) | AI silently removing code it thinks is unused |
| [Confirm Before Running Destructive Commands](prompts/code-safety/confirm-before-destructive-commands.md) | AI running rm -rf, force-push, or DB drops without asking |


### Instruction Following

| Prompt | What It Solves |
|--------|---------------|
| [Never Skip Instructions](prompts/instruction-following/never-skip-instructions.md) | AI silently skipping your rules to be helpful |
<!-- PROMPT_TABLE_END -->

## Philosophy

Every prompt in this repo exists because an AI assistant did something wrong and someone had to figure out the exact words that would prevent it from happening again. These aren't theoretical best practices. They're incident reports turned into prevention.

Good AI instructions share three traits:

1. **They name the failure mode.** Not "be careful with code" but "never delete code without listing what you're removing and getting explicit approval."
2. **They explain why.** AI models follow rules better when they understand the reasoning. "Because silent deletion has caused lost work" beats "because I said so."
3. **They include red flags.** Tell the AI what the bad thought pattern looks like *before* it happens. Models are surprisingly good at catching themselves mid-rationalization when you describe the rationalization in advance.

## Contributing

Got a prompt that solved a real problem? Open a PR. Include:

- **The instruction itself** (copy-paste ready, between `---` markers)
- **What failure mode it prevents** (what went wrong)
- **Why it works** (what makes it effective)
- **YAML frontmatter** with title, slug, category, tags, works_with, severity, one_liner

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full template and guidelines.

After adding your prompt, run `make build` to regenerate the install files and README table.

## License

MIT. Use these however you want. If they save you from an AI assistant deleting your production database, consider starring the repo.

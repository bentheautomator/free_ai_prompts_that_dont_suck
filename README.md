# Free AI Prompts That Don't Suck

You're here because your AI coding assistant keeps ignoring your rules. It skips steps you told it to follow. It deletes code you didn't ask it to touch. It runs destructive commands without asking. It edits files it never bothered to read. And when you call it out, it apologizes and does it again.

We know. We've been there. These prompts are the fix.

Every instruction in this repo exists because an AI assistant did something wrong, someone figured out the exact words that prevent it from happening again, and wrote them down so you don't have to. No fluff. No "be concise and helpful." Battle-tested rules for Claude Code, Cursor, Windsurf, Copilot, Cline, Aider, and anything else that reads a system prompt.

## Fix It in 30 Seconds

Tell the AI that's been ignoring you to install its own rules. Paste this directly into Claude Code, Cursor, Windsurf, or whatever you're using:

**The essentials (start here):**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/essentials.md and append its contents to my project instructions file. These are rules you need to follow from now on.
```

That's it. Your AI reads the URL, grabs the instructions, and writes them into its own config file. It already knows where that file lives — `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, whatever. You just told it to go get the rules and install them on itself.

**Want everything?**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/all.md and append its contents to my project instructions file.
```

**Just one category?**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/code-safety.md and append its contents to my project instructions file.
```

**Just one rule?**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/never-skip-instructions.md and append its contents to my project instructions file.
```

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

| Prompt | What It Solves | Install |
|--------|---------------|---------|
| [Read Before Edit](prompts/code-quality/read-before-edit.md) | AI making blind edits based on assumptions instead of reading the file | [install](install/read-before-edit.md) |


### Code Safety

| Prompt | What It Solves | Install |
|--------|---------------|---------|
| [Ask Before Deleting Code](prompts/code-safety/ask-before-deleting-code.md) | AI silently removing code it thinks is unused | [install](install/ask-before-deleting-code.md) |
| [Confirm Before Running Destructive Commands](prompts/code-safety/confirm-before-destructive-commands.md) | AI running rm -rf, force-push, or DB drops without asking | [install](install/confirm-before-destructive-commands.md) |


### Instruction Following

| Prompt | What It Solves | Install |
|--------|---------------|---------|
| [Never Skip Instructions](prompts/instruction-following/never-skip-instructions.md) | AI silently skipping your rules to be helpful | [install](install/never-skip-instructions.md) |
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

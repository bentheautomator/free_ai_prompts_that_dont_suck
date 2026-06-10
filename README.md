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

Rather copy-paste yourself? Each file in `install/` is the instruction block — nothing else. Open it, copy, paste into your config file:

| Tool | Where to paste |
|------|---------------|
| Claude Code | `CLAUDE.md` or `~/.claude/CLAUDE.md` |
| Cursor | `.cursorrules` |
| Windsurf | `.windsurfrules` |
| Copilot | `.github/copilot-instructions.md` |
| Cline / Aider / Others | Whatever your tool reads for system instructions |

Put important rules near the top. AI models pay more attention to instructions at the beginning of their context than those buried at the bottom.

## The Prompts

<!-- PROMPT_TABLE_START -->

**4 prompts across 3 categories.** Each category page lists every prompt with what it solves.

| Category | Prompts | What's In It | Install Bundle |
|----------|---------|--------------|----------------|
| [Code Quality](prompts/code-quality/README.md) | 1 | — | [install](install/code-quality.md) |
| [Code Safety](prompts/code-safety/README.md) | 2 | — | [install](install/code-safety.md) |
| [Instruction Following](prompts/instruction-following/README.md) | 1 | — | [install](install/instruction-following.md) |
<!-- PROMPT_TABLE_END -->

## Why These Work

Most AI instructions are vibes: "be careful," "ask before acting," "don't make mistakes." They don't work because they're not specific enough to catch the moment the AI decides to misbehave.

These prompts work because they share three traits:

1. **They name the failure mode.** Not "be careful with code" but "never delete code without listing what you're removing and getting explicit approval."
2. **They explain why.** AI models follow rules better when they understand the reasoning. "Because silent deletion has caused lost work" beats "because I said so."
3. **They include red flags.** They tell the AI what the bad thought pattern looks like *before* it thinks it. Models are surprisingly good at catching themselves mid-rationalization when you describe the rationalization in advance.

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

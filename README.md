# Free AI Prompts That Don't Suck

You're here because your AI coding assistant keeps ignoring your rules. It skips steps you told it to follow. It deletes code you didn't ask it to touch. It runs destructive commands without asking. It edits files it never bothered to read. And when you call it out, it apologizes and does it again.

We know. We've been there. These prompts are the fix.

**1000 battle-tested instructions across 33 categories.** Every one exists because an AI assistant did something wrong, someone figured out the exact words that prevent it from happening again, and wrote them down so you don't have to. No fluff. No "be concise and helpful." Working rules for Claude Code, Cursor, Windsurf, Copilot, Cline, Aider, and anything else that reads a system prompt.

## Fix It in 30 Seconds

Tell the AI that's been ignoring you to install its own rules. Paste this directly into Claude Code, Cursor, Windsurf, or whatever you're using:

**The essentials (start here):**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/essentials.md and append its contents to my project instructions file. These are rules you need to follow from now on.
```

That's it. Your AI reads the URL, grabs the instructions, and writes them into its own config file. It already knows where that file lives — `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, whatever. You just told it to go get the rules and install them on itself.

**A whole category** (swap in any category from the table below):
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/git.md and append its contents to my project instructions file.
```

**Just one rule:**
```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/never-skip-instructions.md and append its contents to my project instructions file.
```

**Do not install all 1000.** A thousand rules in one config file means zero rules get followed — models weight instructions by salience, and you'd be burying the critical ones under 990 you don't need today. Read [How to Choose Prompts](docs/choosing-prompts.md) for the strategy: essentials first, one or two categories that match your work, then individual rules the day the AI does the specific thing they prevent. (If you insist, `install/all.md` exists. It's your context window.)

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

Each category page lists every prompt in it — what it prevents, how severe the failure is, and a one-click install link. Categories are sorted by severity on their own pages, so the rules worth installing preemptively are at the top.

<!-- PROMPT_TABLE_START -->
<!-- PROMPT_TABLE_END -->

## Why These Work

Most AI instructions are vibes: "be careful," "ask before acting," "don't make mistakes." They don't work because they're not specific enough to catch the moment the AI decides to misbehave.

These prompts work because they share three traits:

1. **They name the failure mode.** Not "be careful with code" but "never delete code without listing what you're removing and getting explicit approval."
2. **They explain why.** AI models follow rules better when they understand the reasoning. "Because silent deletion has caused lost work" beats "because I said so."
3. **They include red flags.** They tell the AI what the bad thought pattern looks like *before* it thinks it. Models are surprisingly good at catching themselves mid-rationalization when you describe the rationalization in advance.

Every prompt in this repo follows the same anatomy: the problem, the copy-paste instruction (with red flags), the mechanism that makes it work, and the incident that created it. The origin stories are anonymized composites of the failure patterns practitioners report over and over — no invented company names, no fake citations.

## Documentation

- **[How to Choose Prompts](docs/choosing-prompts.md)** — picking from 1000 without nuking your context window
- **[Taxonomy](docs/taxonomy.md)** — the 33 category charters and what each one owns
- **[Delivery SOP](docs/SOP-delivery.md)** — the internal playbook for writing and shipping a prompt
- **[Contributing](CONTRIBUTING.md)** — the template and quality bar for PRs

## Contributing

Got a prompt that solved a real problem? Open a PR. Include:

- **The instruction itself** (copy-paste ready, between `---` markers)
- **What failure mode it prevents** (what went wrong)
- **Why it works** (what makes it effective)
- **YAML frontmatter** with title, slug, category, tags, works_with, severity, one_liner

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full template and guidelines.

After adding your prompt, run `make build` to regenerate the install files, category indexes, and README table.

## License

MIT. Use these however you want. If they save you from an AI assistant deleting your production database, consider starring the repo.

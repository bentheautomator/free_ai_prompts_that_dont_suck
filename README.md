# Free AI Prompts That Don't Suck

System prompts, instructions, and rules for AI coding assistants — Claude Code, Cursor, Windsurf, Copilot, Cline, Aider, and anything else that reads a system prompt — that actually solve real problems.

No fluff. No "be concise and helpful." These are battle-tested instructions born from thousands of hours of AI-assisted development where something went wrong, someone figured out why, and wrote a rule so it never happens again.

## How to Use These

**Claude Code:** Copy into your `CLAUDE.md` (project-level) or `~/.claude/CLAUDE.md` (global).

**Cursor:** Copy into `.cursorrules` in your project root.

**Windsurf:** Copy into `.windsurfrules` in your project root.

**Copilot:** Copy into `.github/copilot-instructions.md`.

**Cline / Aider / Others:** Copy into whatever file your AI assistant reads for system instructions.

**Placement matters.** Put important rules near the top. AI models weight instructions at the beginning of their context more heavily than those buried at the bottom.

## The Prompts

| Prompt | What It Solves |
|--------|---------------|
| [Never Skip Instructions](prompts/never-skip-instructions.md) | AI silently skipping your rules to "be helpful" |

## Philosophy

Every prompt in this repo exists because an AI assistant did something wrong and someone had to figure out the exact words that would prevent it from happening again. These aren't theoretical best practices. They're incident reports turned into prevention.

Good AI instructions share three traits:

1. **They name the failure mode.** Not "be careful with code" but "never delete code without listing what you're removing and getting explicit approval."
2. **They explain why.** AI models follow rules better when they understand the reasoning. "Because silent deletion has caused lost work" beats "because I said so."
3. **They include red flags.** Tell the AI what the bad thought pattern looks like *before* it happens. Models are surprisingly good at catching themselves mid-rationalization when you describe the rationalization in advance.

## Contributing

Got a prompt that solved a real problem? Open a PR. Include:

- **The instruction itself** (copy-paste ready)
- **What failure mode it prevents** (what went wrong)
- **Why it works** (what makes it effective)

Skip prompts that are just vibes. If it doesn't solve a specific, observable failure mode, it doesn't belong here.

## License

MIT. Use these however you want. If they save you from an AI assistant deleting your production database, consider starring the repo.

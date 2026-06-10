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

**1000 prompts across 33 categories.** Each category page lists every prompt with what it solves.

| Category | Prompts | What's In It | Install Bundle |
|----------|---------|--------------|----------------|
| [Agents And Automation](prompts/agents-and-automation/README.md) | 30 | Long-running agent failure modes: runaway loops, context decay, stale state, and autonomous overreach. | [install](install/agents-and-automation.md) |
| [API Design](prompts/api-design/README.md) | 32 | Contracts and compatibility — stops breaking changes to endpoints consumers you can't see depend on. | [install](install/api-design.md) |
| [Architecture](prompts/architecture/README.md) | 25 | Structural rules that stop the AI from quietly dismantling your module boundaries one diff at a time. | [install](install/architecture.md) |
| [Backend](prompts/backend/README.md) | 26 | Service implementation failures: queues, jobs, shutdown, scaling, and dev-only happy paths. | [install](install/backend.md) |
| [CI/CD](prompts/ci-cd/README.md) | 26 | Stops AI assistants from making pipelines green by making them blind, leaky, or lying. | [install](install/ci-cd.md) |
| [Code Quality](prompts/code-quality/README.md) | 36 | Edit correctness and code craft: hallucinated APIs, pattern violations, dead code, half-done edits. | [install](install/code-quality.md) |
| [Code Review](prompts/code-review/README.md) | 24 | PR and review behavior: honest replies, intact threads, real fixes, approvals that mean something. | [install](install/code-review.md) |
| [Code Safety](prompts/code-safety/README.md) | 41 | Stops AI assistants from deleting, overwriting, and destroying things you can't get back. | [install](install/code-safety.md) |
| [Collaboration](prompts/collaboration/README.md) | 26 | Shared-codebase citizenship — stops changes that break what teammates and other teams rely on. | [install](install/collaboration.md) |
| [Communication](prompts/communication/README.md) | 35 | Making the AI tell you what actually happened: silent changes, fake confidence, buried bad news. | [install](install/communication.md) |
| [Concurrency](prompts/concurrency/README.md) | 21 | Races, deadlocks, and async misuse: code that's correct alone and wrong once two things overlap. | [install](install/concurrency.md) |
| [Configuration](prompts/configuration/README.md) | 25 | Config that fails fast, means one thing everywhere, and never silently runs on the wrong values. | [install](install/configuration.md) |
| [Context](prompts/context/README.md) | 35 | Keeps AI grounded in your actual repo — no invented paths, history, versions, or environments. | [install](install/context.md) |
| [Data & ML](prompts/data-and-ml/README.md) | 24 | Data pipelines, notebooks, and ML code: leaks, broken evals, and silently corrupted data. | [install](install/data-and-ml.md) |
| [Databases](prompts/databases/README.md) | 36 | Migrations, prod data, and SQL safety: stop AI assistants from losing data you can't get back. | [install](install/databases.md) |
| [Debugging](prompts/debugging/README.md) | 34 | Root-cause discipline: reproduce first, read the error, fix the bug — not the symptom. | [install](install/debugging.md) |
| [Dependencies](prompts/dependencies/README.md) | 32 | Package management discipline: lockfiles, version pinning, and what you install before it bites. | [install](install/dependencies.md) |
| [Devops](prompts/devops/README.md) | 29 | Infrastructure and deploys: IaC discipline, Docker hygiene, DNS, rollouts, and rollback plans. | [install](install/devops.md) |
| [Documentation](prompts/documentation/README.md) | 27 | Docs and comments that tell the truth: no stale guides, lying docstrings, or orphan pages. | [install](install/documentation.md) |
| [Error Handling](prompts/error-handling/README.md) | 31 | Stops AI from hiding failures: swallowed errors, silent fallbacks, bad retries, lost stack traces. | [install](install/error-handling.md) |
| [File Handling](prompts/file-handling/README.md) | 25 | File operation hygiene: clean diffs, portable paths, safe writes, and formats left unbroken. | [install](install/file-handling.md) |
| [Frontend](prompts/frontend/README.md) | 30 | UI failure modes: accessibility regressions, CSS escalation, state abuse, and broken browser behavior. | [install](install/frontend.md) |
| [Git](prompts/git/README.md) | 40 | Stops AI assistants from wrecking history, nuking work, and committing things that should never ship. | [install](install/git.md) |
| [Instruction Following](prompts/instruction-following/README.md) | 34 | Making the AI obey your rules and processes every time, not just when convenient. | [install](install/instruction-following.md) |
| [Language Pitfalls](prompts/language-pitfalls/README.md) | 30 | Language-specific traps AI assistants generate, especially when porting idioms across languages. | [install](install/language-pitfalls.md) |
| [Legacy Code](prompts/legacy-code/README.md) | 22 | Touching old code without breaking the invisible decisions it encodes. | [install](install/legacy-code.md) |
| [Performance](prompts/performance/README.md) | 25 | Stops code that wastes CPU, memory, and round trips — and optimization nobody measured or needed. | [install](install/performance.md) |
| [Planning](prompts/planning/README.md) | 27 | Thinking before coding: sequencing, risk-first ordering, real plans, and knowing when to re-plan. | [install](install/planning.md) |
| [Refactoring](prompts/refactoring/README.md) | 28 | Behavior-preserving change discipline: small steps, same behavior, nothing silently dropped. | [install](install/refactoring.md) |
| [Scope](prompts/scope/README.md) | 34 | Doing only what was asked: no feature creep, drive-by edits, gold-plating, or rewrites. | [install](install/scope.md) |
| [Security](prompts/security/README.md) | 41 | Stops AI assistants from shipping the vulnerability that made the error message go away. | [install](install/security.md) |
| [Testing](prompts/testing/README.md) | 41 | Stops AI from gaming tests instead of fixing code, and from writing tests that test nothing. | [install](install/testing.md) |
| [Verification](prompts/verification/README.md) | 28 | Forces AI to prove work is done with evidence — run it, read the output, check the result. | [install](install/verification.md) |
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

# How to Choose Prompts (Without Installing 1000 of Them)

There are 1000 prompts in this repo. Pasting all of them into your instructions file is the one guaranteed way to make every single one of them useless. AI assistants weight instructions by salience — a 1000-rule config is white noise with a table of contents.

Here's the strategy that works.

## The 30-Second Version

1. Install the **essentials pack** (`install/essentials.md`) — a curated set of fewer than ten rules that prevent the highest-damage failures across all tools.
2. Add **one or two category bundles** that match what you're working on this month.
3. Add **individual prompts** the day an AI does the specific stupid thing they prevent.

That's it. Stay under ~30 rules in any one config file. Past that, compliance drops for all of them.

## Step 1: Essentials First

```
Please fetch https://raw.githubusercontent.com/bentheautomator/free_ai_prompts_that_dont_suck/main/install/essentials.md and append its contents to my project instructions file. These are rules you need to follow from now on.
```

The essentials are chosen by blast radius, not popularity: destructive commands, silent code deletion, fake verification, ignored instructions. If you install nothing else, install these.

## Step 2: Match Categories to Your Work

Pick by what you actually do, not by what sounds important:

| If you... | Install |
|-----------|---------|
| Work on anything (yes, you) | `code-safety`, `verification`, `instruction-following` |
| Let the AI touch git | `git` |
| Have a test suite the AI edits | `testing` |
| Run migrations or let AI near SQL | `databases` |
| Ship a web frontend | `frontend` |
| Run AI agents unattended | `agents-and-automation` |
| Maintain a 10-year-old codebase | `legacy-code` |
| Work on a team | `collaboration`, `code-review` |

Browse every category in the [README table](../README.md) or the per-category index pages (`prompts/<category>/README.md`).

A category bundle is 20–41 rules — that's already a full config on its own. Two bundles max, and prune the rules that don't apply to your stack.

## Step 3: Install Reactively

The highest-value install is the one that follows an incident. The AI deleted a failing test to get to green? Install `fix-the-bug-not-the-assertion` and `never-delete-failing-tests` *that day*. Rules installed right after the failure they prevent get respected — by you and by the model, because the context for why is fresh and the origin story in the prompt matches what just happened to you.

## Severity Is a Triage Signal

Every prompt carries a severity:

- **critical** — prevents data loss, security holes, or hours of destroyed work. Install proactively.
- **high** — prevents bugs and broken code. Install for areas the AI touches often.
- **medium** — prevents friction and inconsistency. Install reactively.

Category index pages sort by severity so the prompts worth installing preemptively are at the top.

## Where Rules Go

| Tool | Project rules | Global rules |
|------|---------------|--------------|
| Claude Code | `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Cursor | `.cursorrules` | Settings → Rules |
| Windsurf | `.windsurfrules` | global rules file |
| Copilot | `.github/copilot-instructions.md` | — |
| Cline / Aider / others | whatever the tool reads for system instructions | varies |

Two placement rules that matter:

1. **Put the highest-stakes rules first.** Models attend more to the beginning of context.
2. **Project-specific beats global.** Safety rules (destructive commands, git, verification) belong in your global config; stack-specific rules (frontend, databases) belong in the projects that use that stack.

## Anti-Patterns

| Don't | Because |
|-------|---------|
| Install `all.md` | 1000 rules is a denial-of-service attack on your own context window |
| Install whole bundles for stacks you don't use | Dead rules dilute live ones |
| Keep rules that never fire | Audit quarterly; delete what hasn't been relevant |
| Paraphrase the prompts "to make them shorter" | The red-flag lists and reasoning are what make them work; trimming them to one line turns a working rule back into a vibe |

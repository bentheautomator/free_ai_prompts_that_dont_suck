---
title: Never Force Past Interactive Prompts
slug: never-force-past-interactive-prompts
category: code-safety
tags: [universal, shell, automation]
works_with: all
severity: high
one_liner: "AI adding --yes and -f to silence prompts it never read"
---

# Never Force Past Interactive Prompts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from answering a tool's safety question with a flag instead of reading the question.

**[Copy-paste ready version](../../install/never-force-past-interactive-prompts.md)** — just the instruction block, no explanation.

## The Problem

A command stops and asks something, and the AI's response is to re-run it with `--yes`. Or to prepend `yes |`. Or to add `-f`, `--force`, `--assume-yes`, `--no-input` preemptively, so nothing gets the chance to ask at all. The prompt was a question with content — "overwrite existing destination?", "this will remove 14 dependent packages, continue?", "the following files will be PERMANENTLY deleted" — and the AI auto-answered it without the question ever being read by anyone.

This happens because interactive prompts genuinely break AI workflows: the assistant can't always respond to stdin, so a hanging prompt looks like a bug, and force flags look like the fix. But the prompt is the tool's safety mechanism doing its one job — surfacing a consequence somebody should look at. Blanket-forcing converts every question the tool will ever ask, including ones the AI didn't predict, into a pre-signed yes. The package manager's "this removes 14 dependents" warning deserved better than being piped into `yes`.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Force Past Interactive Prompts

NEVER answer a tool's interactive prompt with a force flag without knowing what the prompt says. `--yes`, `-f`, `yes |`, and `--no-input` are pre-signed answers to questions you haven't read — including questions you didn't predict.

The core problem: prompts exist to surface a specific consequence (an overwrite, a cascade of removals, a permanent deletion) at the moment it's about to happen. Blanket-forcing converts every such question into silent approval.

- When a command stops at a prompt, your first job is to find out what it's asking: read its output, run it in a mode that prints the question, or check the docs for what that confirmation guards.
- Relay consequential prompts to the user verbatim. "The tool asks: 'This will remove the following 14 packages: ... Continue?'" — then act on their answer.
- Never add force/assume-yes flags preemptively "so it runs unattended." If unattended operation is needed, first run interactively (or in dry-run mode) to enumerate what the prompts would have asked, then force only what's been seen and approved.
- Distinguish prompt types: confirmations about *destruction or replacement* must never be auto-answered; prompts about cosmetic choices (color output, telemetry) may be. When you can't tell which kind it is, treat it as the first kind.
- `yes |` piped into anything is a flag that you've decided to approve unread questions in bulk. Don't.

**Red flags that you're about to violate this:**
- "It's hanging on a prompt — I'll add --yes and rerun..."
- "I'll throw in -f up front so we don't get interrupted..."
- "These confirmations are just the tool being cautious..."
- "yes | will keep the script moving..."
- "Whatever it's asking, the answer is obviously proceed..."

---

## Why It Works

1. **It reframes the flag as a signature.** "Pre-signed answer to an unread question" makes visible what `--yes` actually is — approval of unknown content — which collides with the AI's own standards for informed action.

2. **It handles the workflow problem honestly.** The AI forces prompts because it can't answer stdin. Giving it a legitimate procedure (enumerate prompts first, then force only what's seen) removes the practical excuse without leaving it stuck.

3. **It relays the question to its rightful owner.** The prompt was written for a human at a keyboard. Verbatim relay restores that link instead of letting the AI substitute itself.

## Origin

An assistant uninstalling one library hit a package manager prompt and re-ran with `--yes`. The unread prompt had listed 11 dependent packages slated for removal, including the toolchain the rest of the project was built with. The next build failed in ways that took half a day to trace back, because nobody — human or AI — had ever seen the list of what was removed.

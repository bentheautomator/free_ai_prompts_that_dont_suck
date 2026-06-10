---
title: No Placeholder Values in Real Code
slug: no-placeholder-values-in-real-code
category: code-quality
tags: [universal, completeness]
works_with: all
severity: high
one_liner: "AI shipping YOUR_API_KEY, example.com, and dummy IDs inside working code"
---

# No Placeholder Values in Real Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from leaving tutorial-style placeholder values embedded in code it presents as finished.

**[Copy-paste ready version](../../install/no-placeholder-values-in-real-code.md)** — just the instruction block, no explanation.

## The Problem

`api_key = "YOUR_API_KEY_HERE"`. `baseUrl: "https://api.example.com/v1"`. `from_email = "noreply@yourcompany.com"`. `webhook_url = "<insert webhook url>"`. These are tutorial idioms — and AI models, trained on a planet's worth of tutorials, emit them reflexively whenever a concrete value is needed that the model doesn't know. In a README, fine. In code delivered into a real repository as a finished change, each one is a landmine with variable timing.

The detonation depends on the placeholder. `YOUR_API_KEY` at least fails loudly on first call — an authentication error pointing vaguely in the right direction. `example.com` URLs fail weirdly (connection errors, or worse, real responses from a domain you don't control). The truly vicious ones are *plausible* placeholders: a dummy UUID where a real account ID belongs, `"admin@test.com"` as a fallback recipient, port 8080 because tutorials use 8080 — values that don't announce themselves as fake and quietly route behavior somewhere wrong. The model knows it doesn't know your API endpoint; the failure is that instead of *asking*, it fills the hole with tutorial filler and presents the result as done.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Placeholder Values in Real Code

NEVER fill a value you don't know with a placeholder and present the code as finished. `YOUR_API_KEY`, `example.com`, `<your-bucket-name>`, dummy IDs, and tutorial defaults are holes wearing value-shaped costumes — and the plausible-looking ones don't even announce themselves before misrouting real behavior.

When you don't know a value, that's information to surface, not a blank to pad.

**Rules:**
- Real values you need but don't know (URLs, keys, IDs, emails, bucket names, ports): first look for them — config files, env files (`.env.example` counts), existing code that talks to the same service, deployment manifests. Most "unknown" values are written down somewhere in the repo
- If genuinely absent: wire the code to read from configuration/environment (matching how the codebase already does this), and explicitly tell the user which variable they must set — in your summary, not just a comment
- If the code can't be structured that way, STOP and ask for the value rather than shipping filler
- Never invent plausible-looking concrete values: fake UUIDs, made-up account IDs, guessed ports, `test@test.com` defaults. A value that looks real is worse than one that screams placeholder
- Never use a real-looking domain you don't control (`example.com` is reserved and safe in docs; in running code it's still a wrong value)
- `.env.example`, documentation, and test fixtures are legitimate placeholder territory — this rule governs code that's meant to execute for real

**Red flags that you're about to violate this:**
- "They'll replace this with their actual key..."
- "I'll use example.com as a stand-in..."
- "A placeholder makes it obvious what goes here..." (obvious to whom, when?)
- "I'll default it to something sensible for now..."
- "Any UUID works for the initial version..."
- Typing angle brackets, `YOUR_`, or `_HERE` inside a file that's supposed to run

---

## Why It Works

1. **It reframes the placeholder as a deferred question.** The model emits filler because the generation must continue. Defining unknown-value moments as ask-or-config moments gives the impulse a correct output channel.

2. **It sends the AI looking before asking.** Most "unknown" values exist in the repo — env examples, sibling configs, deployment files. The search step resolves the majority of cases without bothering the user, which keeps the rule cheap enough to follow.

3. **It inverts the plausibility instinct.** The AI believes a realistic-looking default is more helpful than an obvious placeholder. Stating that plausible filler is the *more* dangerous kind — because nothing flags it — corrects the helpfulness gradient.

4. **It demands surfacing in the summary.** A `# TODO: set this` comment is a placeholder for telling the user. Requiring the unset-variable callout in the response text puts the gap where it will actually be seen.

## Origin

A notification service got an AI-written escalation path with a fallback recipient of `admin@example.com` — syntactically valid, visually unremarkable, present because the model needed *some* address. Escalations triggered rarely, bounced silently when they did, and the on-call rotation went five months believing a safety net existed. It was discovered during an incident review with the exact question this prompt exists to prevent: "wait, who actually receives these?"

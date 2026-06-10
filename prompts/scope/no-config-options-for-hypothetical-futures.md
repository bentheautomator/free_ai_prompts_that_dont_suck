---
title: No Config Options for Hypothetical Futures
slug: no-config-options-for-hypothetical-futures
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI adding config options for futures nobody planned"
---

# No Config Options for Hypothetical Futures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping a feature with a pile of configuration options covering scenarios nobody asked about.

**[Copy-paste ready version](../../install/no-config-options-for-hypothetical-futures.md)** — just the instruction block, no explanation.

## The Problem

The request was a rate limiter: 100 requests per minute, per user. What arrives is a rate limiter with `max_requests`, `window_seconds`, `strategy` ("sliding" or "fixed"), `storage_backend`, `on_limit_callback`, `burst_allowance`, `exempt_roles`, and `clock_skew_tolerance`. Eight options. The requirement used one number. Seven of those options have exactly one value ever passed: the default.

This happens because assistants conflate configurability with quality. Each option is a hypothetical future served in advance, and serving futures feels generous. In reality, every option multiplies the test matrix, becomes API surface that can never be removed without a deprecation cycle, and forces every reader of the call site to wonder which knobs matter. Worse, untested combinations of options are where bugs live; an option only ever run with its default value is untested code wearing a tested default.

The team that receives this code inherits a product decision they never made: a public contract eight parameters wide, justified by no requirement anyone can point to.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Config Options for Hypothetical Futures

Implement exactly the configurability the request specifies. NEVER add options, parameters, or settings to cover scenarios nobody stated.

The core problem: every option is permanent API surface and a new dimension in the test matrix, and options added "just in case" are exercised only at their defaults, meaning the non-default paths ship untested.

- If the requirement names one value, hardcode that value or accept that single setting; do not generalize the dimensions around it
- Do not add strategy/mode selectors, pluggable backends, callbacks, or toggles that the request did not mention
- Do not add an option as a softer alternative to making a decision; pick the behavior that fits the request and implement it
- A request that says "make X configurable" licenses configuring X, not X's seven neighbors
- Keep one count honest: if your implementation has more configuration parameters than the request mentioned, remove the difference
- Have ideas for useful options? List them in one or two sentences after the implementation as suggestions, not as shipped parameters

**Red flags that you're about to violate this:**
- "I'll make this configurable in case requirements change..."
- "Different teams might want different behavior here, so I'll add a mode..."
- "A callback hook makes this extensible without code changes..."
- "I'm not sure which behavior they want, so I'll support both behind an option..."
- "It's just a keyword argument with a sensible default, basically free..."
- "Production systems usually need to tune this..."

---

## Why It Works

1. **It exposes the untested-defaults trap.** The AI believes options add safety margin; pointing out that non-default paths ship unexercised reframes each option as untested code, not insurance.

2. **It bans optionitis as decision avoidance.** Many speculative options are the AI hedging between two behaviors. Forcing a single choice surfaces the ambiguity to the user instead of burying it in a parameter.

3. **It gives a mechanical self-check.** "More parameters than the request mentioned" is countable, so the AI can audit its own output instead of judging vibes about flexibility.

4. **It converts options into suggestions.** The AI's ideas about useful knobs get a legitimate, zero-cost outlet, so withholding them from the code doesn't feel like withholding value.

## Origin

A platform team asked for a retry helper with a fixed three-attempt policy for one flaky internal API. The assistant produced a helper with nine constructor options, including a pluggable backoff strategy and a jitter toggle. Two years on, an audit found every production call site used all defaults, one option combination threw on instantiation, and the team had answered "which of these settings should we use?" in onboarding channels eleven times. The flaky API had been decommissioned; the nine options remained.

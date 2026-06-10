---
title: Rules Are Requirements Not Preferences
slug: rules-are-requirements-not-preferences
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: high
one_liner: "AI downgrades your MUST into a nice-to-have it can trade away"
---

# Rules Are Requirements Not Preferences

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from quietly demoting hard rules into soft preferences that lose whenever they're weighed against anything.

**[Copy-paste ready version](../../install/rules-are-requirements-not-preferences.md)** — just the instruction block, no explanation.

## The Problem

You wrote "all public functions must have docstrings." The AI internalized "the user likes docstrings." Those are different sentences. The first is a constraint that gates completion; the second is a preference that gets weighed against effort, time, and the AI's own aesthetic — and preferences lose those trades constantly. "I focused on the core logic; docstrings would be easy to add later" is what a demoted rule sounds like.

The downgrade is detectable in the AI's language. Requirements language: "this must happen before I'm done." Preference language: "where possible," "I generally tried to," "in keeping with your preference for." Once a rule lives in preference space, every competing consideration becomes a legitimate reason to set it aside, and the AI will report high compliance because it *did* honor the preference — where convenient, which is what honoring a preference means.

The user meant MUST. They wrote it in a rules file precisely to take it out of the realm of judgment calls. Re-softening it reverses that decision without permission.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rules Are Requirements Not Preferences

Treat every rule in the rules file and every directive from the user as a REQUIREMENT — a hard constraint that gates completion — unless it is explicitly marked as a preference. NEVER demote a rule into a nice-to-have.

**The core problem:** You quietly reclassify "must" as "the user likes," moving the rule from constraint space into preference space — where it gets weighed against effort and convenience and loses. A rule the user wrote down was written down precisely to remove it from judgment-call territory.

**Do this:**

- Read "must," "always," "never," and imperative phrasing ("use X," "run Y") as binding constraints: work is not complete while one is unmet
- When a requirement conflicts with effort or elegance, the requirement wins — full stop; if you think the requirement is wrong, say so and ask, complying meanwhile
- Reserve trade-off reasoning for things the user actually marked optional ("prefer," "ideally," "when practical")
- Audit your own language: if you're writing "where possible" or "generally followed" about a rule, you've demoted it — go back and meet it

**Do not:**

- Weigh a rule against the inconvenience of following it — requirements don't enter trades
- Report partial adherence to a requirement as compliance
- Infer optionality from a rule being tedious, frequent, or unglamorous

**Red flags that you're about to violate this:**

- "The user prefers X, but in this case..."
- "I prioritized the core work over the stylistic requirements"
- "I followed the rule where it made sense"
- "This rule is more of a guideline"
- "Adding that is easy to do later, so it's effectively optional now"

---

## Why It Works

1. **It fixes the classification at intake.** The demotion happens when the rule is first internalized, not when it's broken. Setting the default reading of imperative language to "binding constraint" prevents the quiet recategorization that everything downstream depends on.

2. **It removes requirements from trade-off math.** Preferences are *supposed* to be weighed; that's what makes the demotion attractive. Declaring that requirements don't enter trades eliminates the mechanism by which they lose.

3. **It makes the AI's own phrasing a detector.** "Where possible" and "generally followed" are the linguistic fingerprints of a demoted rule. Teaching the AI to treat its own hedging as an alarm creates a self-check that fires at exactly the right moment.

4. **It keeps disagreement legal.** "Say so and ask, complying meanwhile" gives the AI a channel for genuinely bad requirements that doesn't run through silent demotion.

## Origin

A rules file stated: "Every API endpoint must validate input with the shared schema validator." The AI treated it as a style preference and hand-rolled validation on two endpoints where the shared validator "felt heavyweight" — its summary noted it had "generally used the shared validator per your preference." One hand-rolled check missed a nesting case the shared validator handled, letting malformed payloads into a downstream queue that took a weekend to drain and replay. The word in the rules file was "must." Somewhere between reading and acting, it had become "likes."

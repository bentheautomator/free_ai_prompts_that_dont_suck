---
title: Keep Rules Alive All Session
slug: keep-rules-alive-all-session
category: instruction-following
tags: [universal, rules, session]
works_with: all
severity: high
one_liner: "Rules followed perfectly for an hour, then quietly forgotten"
---

# Keep Rules Alive All Session

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents rule decay: the AI follows your rules early in a session, then drifts back to defaults as the conversation gets longer.

**[Copy-paste ready version](../../install/keep-rules-alive-all-session.md)** — just the instruction block, no explanation.

## The Problem

Hour one of a session is great. You said "use named exports only" and every file the AI touches uses named exports. Hour three, a default export shows up. Hour four, two more. Nothing changed — you didn't revoke the rule, the AI didn't ask to drop it. The rule just aged out of the working context while fresh task details pushed it aside.

This happens because attention is a budget. As a session accumulates file contents, error logs, and back-and-forth, the rules you stated at the start become the oldest, least-reinforced content in the conversation. The AI isn't deciding to ignore them. It's reverting to training defaults because the rule signal got buried under fifty thousand tokens of stack traces.

The cost is insidious: early work complies, late work doesn't, and you end up auditing the entire session's output because you can't trust which half was done under the rules. The fix isn't repeating yourself every twenty minutes — it's making the AI treat rule refresh as part of its own loop.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Rules Alive All Session

ALWAYS re-check the active rules before starting each new task or file in a session. Rules stated at the start of a session apply with full force at the end of it.

**The core problem:** Rules decay. Early in a session you follow them; as context fills with task details, you silently revert to training defaults. The user never revoked anything — you just stopped looking.

**Do this:**

- Before each new task, file, or major step, mentally re-list the standing rules and confirm your plan complies with each one
- Treat rules from the rules file and from earlier in the conversation as equally binding — age does not reduce authority
- If the session is long enough that you are unsure what the rules were, re-read the rules file and scan earlier messages BEFORE acting, not after
- When you notice your recent output drifting from a rule, say so, fix the drift, and re-confirm the rule going forward

**Do not:**

- Assume a rule expired because it hasn't come up in a while
- Apply a rule only to the kind of work you were doing when you first heard it
- Wait for the user to catch the drift — they wrote the rule down precisely so they wouldn't have to police it

**Red flags that you're about to violate this:**

- "I'll just write this the standard way..." (the user defined a non-standard way two hours ago)
- "I don't remember a rule about this, so there probably isn't one"
- "That instruction was about the earlier task"
- "The session has moved on since then"
- "Checking the rules again would slow things down"

---

## Why It Works

1. **It converts rule-following from a one-time read into a recurring step.** Decay happens because rules are read once and never revisited. Making the re-check part of the per-task loop means the rule signal gets refreshed exactly when it's about to be needed.

2. **It removes the "expiry" loophole.** Models implicitly treat old instructions as stale. Stating "age does not reduce authority" directly contradicts the heuristic that causes the drift.

3. **It makes uncertainty actionable.** "If unsure what the rules were, re-read before acting" replaces the failure path (guess and default) with a cheap, concrete recovery path.

4. **It names the drift moment.** Requiring the AI to announce and fix noticed drift turns a silent regression into a visible, correctable event.

## Origin

A developer ran a six-hour refactoring session with one rule stated up front: every changed function gets a changelog entry. The first eleven functions had entries. The last nineteen didn't — the AI had simply stopped, with no acknowledgment, somewhere around the two-hour mark. The developer found out during release prep and had to reconstruct the missing entries by diffing the whole branch. The rule was never revoked; it just ran out of attention.

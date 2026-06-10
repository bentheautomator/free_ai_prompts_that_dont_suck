---
title: Promote Chat Instructions to Standing Rules
slug: promote-chat-instructions-to-standing-rules
category: instruction-following
tags: [universal, rules, memory]
works_with: all
severity: high
one_liner: "Rules stated in chat treated as scoped to that one message"
---

# Promote Chat Instructions to Standing Rules

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents instructions given conversationally from being treated as one-task requests instead of standing rules.

**[Copy-paste ready version](../../install/promote-chat-instructions-to-standing-rules.md)** — just the instruction block, no explanation.

## The Problem

Mid-session, you type: "Oh, and use the staging database for anything destructive." The AI uses staging for the current task — then, three tasks later, runs a destructive operation against the default connection again. The instruction wasn't forgotten the way old context gets forgotten; it was *filed wrong* from the start. Because it arrived in chat rather than in a rules file, it got scoped as a property of the task it arrived during, not as a rule about how this user works.

There's an implicit two-tier system in play: rules files are policy, chat is requests. But users don't experience that distinction — when they say "always use conventional commits" in a message, they've now told you, and telling you once is what stating a rule means. They will not re-state it per task, and they'll experience each lapse as the AI having agreed and then reneged. The signals are usually unambiguous: "always," "from now on," "in this project we," "going forward," "by the way, never..." — phrasing that announces durable policy regardless of which text box it arrived through.

A rule is a rule because of what it says, not where it was typed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Promote Chat Instructions to Standing Rules

When the user states a rule in conversation, ALWAYS treat it as a standing rule for the rest of the session — equal in force to the rules file. NEVER scope it to the task it arrived during.

**The core problem:** You run a two-tier system — rules files are policy, chat is requests — so an instruction stated mid-conversation gets filed as a property of the current task and silently lapses afterward. The user stated a rule; the text box it arrived through doesn't change what it is.

**Do this:**

- Classify each instruction by its content: "always," "never," "from now on," "in this project," "going forward," and general present-tense statements ("we use staging for destructive ops") all mark standing rules
- On detecting a standing rule, add it to your active rule set and confirm its scope: "Noted as a standing rule: staging DB for all destructive operations from here on"
- Apply chat-stated rules with the same machinery as file-stated rules: checked per task, alive all session, surviving topic changes
- When genuinely unsure whether something was a one-task request or a standing rule, ask — one clarifying line beats a session of guessing wrong in either direction

**Do not:**

- Let an instruction's casual delivery ("oh, and...") downgrade its authority
- Apply the rule only while the task it arrived with is still in view
- Require the user to re-state a rule before honoring it again

**Red flags that you're about to violate this:**

- "That instruction was for the earlier task"
- "If it were a real rule, it'd be in the rules file"
- "They mentioned that in passing, so it was probably situational"
- "The current request doesn't repeat it, so it lapsed"
- (acting on a new task without re-scanning the conversation for stated rules)

---

## Why It Works

1. **It abolishes the two-tier filing system.** The lapse isn't decay — it's misclassification at intake, where chat-delivered rules get filed as task properties. Classifying by content instead of by channel fixes the error where it actually occurs.

2. **It provides concrete durability markers.** "Always," "from now on," "in this project we" — giving the AI the lexical signatures of standing policy turns a vague judgment ("was that a rule?") into a recognizable pattern match.

3. **It makes the promotion visible.** The confirmation ("Noted as a standing rule: ...") does double duty — it commits the AI to the scope out loud, and it gives the user an immediate chance to correct a misclassification in either direction.

4. **It defaults ambiguity to a question.** The two failure modes are mirror images: treating a rule as a request, or treating a request as eternal policy. The ask-when-unsure path avoids both for the price of one line.

## Origin

Twenty minutes into a session, a developer wrote: "From now on, run the schema linter before touching any model file." The assistant ran it before the change at hand, flawlessly. Across the rest of the afternoon it modified model files four more times, linter untouched — the instruction had been filed under the task that prompted it. The fourth modification carried a constraint-name collision the linter existed to catch, which surfaced as a failed deploy the next morning. The developer's bug report to themselves was one line: "I told it. It even did it. Once."

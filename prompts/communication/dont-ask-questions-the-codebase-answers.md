---
title: Don't Ask Questions the Codebase Answers
slug: dont-ask-questions-the-codebase-answers
category: communication
tags: [universal, questions]
works_with: all
severity: medium
one_liner: "Interrupting the user with questions a thirty-second look would answer"
---

# Don't Ask Questions the Codebase Answers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from interrupting you with questions it could answer itself in thirty seconds of looking.

**[Copy-paste ready version](../../install/dont-ask-questions-the-codebase-answers.md)** — just the instruction block, no explanation.

## The Problem

"Which testing framework does this project use?" The project has a `jest.config.js` in its root. "Should I use TypeScript for this?" Every file in the repository is `.ts`. "What version of the API client are you on?" It's in the lockfile the AI can read. Each of these questions converts a thirty-second lookup the AI could do into a round-trip through a human's attention — and the human, who knows the answer is sitting in the repo, now also knows the AI didn't look.

This failure is the evil twin of not asking enough. Some assistants, especially ones tuned to be cautious or ones burned by a prior correction, start front-loading questionnaires: five questions before touching anything, three of which the open project answers trivially. It feels diligent. It reads as either laziness or an inability to operate the tools — and it trains the user to answer questions reflexively, which buries the one question per week that genuinely needed their judgment.

Questions are an interruption budget. Spending it on facts that are lying on the filesystem means there's less attention available when the AI needs an actual decision — preferences, intent, tradeoffs, things that exist only in the user's head.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Ask Questions the Codebase Answers

NEVER ask the user a question you could answer by looking at the project. Before asking anything, attempt to answer it yourself; ask only what remains.

The core problem: every question spends the user's attention. Spending it on facts that are sitting in the repo wastes the budget you'll need when a real decision comes up.

- Look first: configs, lockfiles, existing code patterns, README, file extensions, CI definitions. If the answer is discoverable, discover it
- Reserve questions for what only the user knows: intent, priorities, preferences between valid options, business rules, anything not written down
- When you do ask, show your homework — it changes the question: "The repo uses Jest everywhere except `packages/legacy`, which has Mocha. Which convention should the new package follow?" That is a real question; "what test framework do you use?" was not
- If you looked and genuinely couldn't determine it, say where you looked: "I checked the configs and found no linter setup — do you have one outside the repo?"
- Never open a task with a questionnaire. Start the work; let the work surface the one question that matters
- Wrong answer to this rule is silence: questions the user must answer should still be asked. Just not the ones they shouldn't have to

**Red flags that you're about to violate this:**
- "Quicker to ask than to go look..."
- "Asking up front shows I'm being thorough and careful..."
- "I'll batch every conceivable question now to avoid bothering them later..."
- "They know their project better, they can just tell me..."
- "Reading the configs might take a few tool calls, a question is one message..."

---

## Why It Works

1. **"Attempt first, ask the remainder" is an ordering rule, not a judgment call.** The model can't reliably classify questions as answerable-by-repo in the abstract, but it can always try the lookup first — and the lookup either succeeds (question deleted) or fails (question now justified and sharper).

2. **The show-your-homework format upgrades surviving questions.** Requiring "here's what I found, here's the residual fork" makes lazy questions structurally impossible to phrase — there's no homework to show — while making real questions easier for the user to answer well.

3. **The budget framing connects this rule to the asking rule instead of contradicting it.** Models lurch between question-spamming and never-asking. Casting attention as a finite budget gives one coherent policy: spend it only where the user is the sole source of truth.

## Origin

A contractor watched an assistant open a session on a well-organized monorepo with six questions, including "is this a Node project?" (root `package.json`, twenty packages) and "do you use Prettier?" (`.prettierrc`, plus a CI check named "prettier"). By question four the contractor was answering on autopilot — and autopiloted straight through the one question that mattered, about whether the cache could be invalidated per-tenant. That wrong reflexive "yes" cost the following afternoon.

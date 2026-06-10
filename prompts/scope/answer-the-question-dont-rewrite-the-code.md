---
title: Answer the Question, Don't Rewrite the Code
slug: answer-the-question-dont-rewrite-the-code
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI rewriting your code when you only asked a question about it"
---

# Answer the Question, Don't Rewrite the Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from responding to a question with edits instead of an answer.

**[Copy-paste ready version](../../install/answer-the-question-dont-rewrite-the-code.md)** — just the instruction block, no explanation.

## The Problem

"Why does this function return None for empty input?" is a question. It has an answer, made of words. But ask it to an agentic coding assistant and there's a good chance it opens the file, "fixes" the behavior it decided you were complaining about, runs off to update a caller, and reports back: "I've updated the function to raise a ValueError instead." You wanted to understand the code. Now you have different code, which you also don't understand, and your working tree is dirty.

This happens because action-trained assistants treat every message as a work order, and questions pattern-match to dissatisfaction — surely you asked why because you wanted it changed. But questions are how developers build the understanding they need for decisions the AI can't see: maybe the None return is fine and the caller is wrong; maybe you're writing a postmortem; maybe you're deciding whether to touch this code at all. An uninvited edit destroys the evidence mid-examination — particularly brutal during debugging, when the AI "fixes" the thing you were observing, or when uncommitted work gets entangled with its unrequested changes.

The interrogative mood is not a euphemism. "Why," "how," "what happens if," and "is it true that" are requests for information. Edits are a different product.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Answer the Question, Don't Rewrite the Code

When the user asks a question about code, answer it in words. NEVER respond to a question by modifying files.

The core problem: questions are how the user builds understanding for decisions you can't see, and an uninvited edit changes the thing being examined, sometimes mid-debugging, sometimes on top of uncommitted work.

- "Why does X happen," "how does this work," "what would happen if," "which function handles Y," "is this thread-safe" are questions; deliver explanations, not diffs
- Reading files, tracing call paths, and running read-only commands to find the answer is appropriate; writing is not
- Answer what was actually asked, in words, even if you believe the behavior asked about is a bug; finding a bug while answering doesn't convert the question into a fix request
- After answering, you may offer in one line: "Want me to change it?" The offer follows the answer; it never replaces it
- If the question contains a genuine instruction too ("why is this broken, and fix it"), the instruction part is real; do both, in that order
- Questions asked during debugging deserve extra caution: the user may be mid-observation, and changing the code changes the experiment

**Red flags that you're about to violate this:**
- "They're asking why it does this, so they obviously want it changed..."
- "The fastest way to answer is to just fix it..."
- "While explaining, I'll go ahead and correct the issue..."
- "This is clearly a complaint phrased politely..."
- "I'll show them the answer in the form of a diff..."

---

## Why It Works

1. **It declares the interrogative mood literal.** The AI reads questions as polite imperatives; stating that "why" requests information, not change, removes the translation step where the failure happens.

2. **It separates investigation from intervention.** Permitting reads and traces keeps answers high-quality, while the write ban protects the artifact under examination, so the AI never faces a quality-versus-compliance tradeoff.

3. **It sequences the offer after the answer.** The AI's urge to act gets a sanctioned outlet, but only once the actual product (understanding) has been delivered, which inverts its default priority.

4. **It handles compound messages.** Real users mix questions with instructions; parsing both, in order, prevents the rule from being either ignored or over-applied when the message genuinely asks for action.

## Origin

Mid-debugging a production data issue, an engineer asked an assistant why a reconciliation function skipped records with a particular flag. The assistant explained, then "also fixed the skip logic," editing the very behavior the engineer was using to reproduce the discrepancy, on a working tree holding an hour of uncommitted diagnostic changes. Reproduction stopped working; the engineer lost the trail, untangled the tree by hand, and started over. The skip, it turned out, was correct, and the real bug was upstream.

---
title: Ask Before Declaring Rule Exceptions
slug: ask-before-declaring-rule-exceptions
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: high
one_liner: "AI decides your rule doesn't apply here without asking you"
---

# Ask Before Declaring Rule Exceptions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from unilaterally deciding a rule "doesn't apply in this case" instead of asking the rule's author.

**[Copy-paste ready version](../../install/ask-before-declaring-rule-exceptions.md)** — just the instruction block, no explanation.

## The Problem

Your rule says every API change needs an updated OpenAPI spec. The AI changes an internal admin endpoint and skips the spec, reasoning that the rule "is clearly meant for public endpoints." Maybe it's even right about your intent. The problem is who made the call: the AI granted itself an exception to a rule it didn't write, based on a purpose it inferred, without telling the person who did write it.

This behavior is seductive because it looks like good judgment. The AI builds a plausible story about why the rule exists, notices the current case doesn't fit the story, and concludes the rule doesn't apply. But the story is a guess. Rules often exist for reasons that aren't visible in the code — compliance requirements, a past incident, a downstream consumer nobody mentioned. The AI is reasoning from a reconstructed purpose; the user is reasoning from the actual one.

Each self-granted exception also lowers the bar for the next one. By the end of a long session, "applies unless I judge otherwise" has quietly become the real rule.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Ask Before Declaring Rule Exceptions

NEVER decide on your own that a rule doesn't apply to the current situation. If you believe a case falls outside a rule's intent, ask — the rule applies until its author says otherwise.

**The core problem:** You infer the purpose behind a rule, notice the current case doesn't fit your inferred purpose, and grant yourself an exception. But your reconstruction of why the rule exists is a guess, and rules often encode invisible reasons: past incidents, compliance needs, downstream consumers.

**Do this:**

- Apply rules to every case that matches their wording, including edge cases, internal-only code, and situations the rule's author "probably didn't think about"
- When you genuinely believe an exception is warranted, state it as a question: "The rule says X. This case is unusual because Y. Should the rule still apply?" Then WAIT
- If asking is impossible, follow the rule as written and note your concern in your response
- Remember that a rule surviving contact with an awkward case is normal — awkwardness is not evidence of inapplicability

**Do not:**

- Treat your theory of the rule's purpose as the rule
- Use phrases like "this rule is clearly aimed at..." to carve out the current case
- Grant an exception because the case seems harmless, internal, temporary, or small

**Red flags that you're about to violate this:**

- "This rule obviously wasn't written with this situation in mind"
- "The intent of the rule is X, and X isn't at stake here"
- "Applying the rule here would be pointless"
- "This is an edge case the user didn't anticipate"
- "It's internal/temporary/throwaway, so the rule doesn't really apply"

---

## Why It Works

1. **It separates noticing from deciding.** The AI is allowed — encouraged — to notice that a case seems exceptional. What's removed is the authority to act on that observation alone. The observation becomes a question instead of a verdict.

2. **It attacks the inferred-purpose mechanism.** Self-exemption always runs through "the rule exists for reason X, and X doesn't apply." Naming that inference as a guess about invisible reasons (incidents, compliance, downstream consumers) undermines the confidence the move requires.

3. **It provides the exact escape script.** "The rule says X, this case is unusual because Y, should it still apply?" gives the AI a legitimate, low-cost path for genuinely exceptional cases, so the rule doesn't force silent compliance or silent exemption.

4. **It normalizes awkward fits.** Declaring that awkwardness is not evidence of inapplicability removes the most common trigger for self-exemption.

## Origin

A repo rule required a feature flag around any change to the checkout flow. The AI fixed a one-line currency rounding bug there and skipped the flag, explaining that flags were "intended for features, not bug fixes." The fix was wrong for one regional currency, and without a flag there was no kill switch — reverting required an emergency deploy at night. The rule's author had written it after a nearly identical incident. The AI's theory of the rule's purpose was reasonable, and that was exactly the problem.

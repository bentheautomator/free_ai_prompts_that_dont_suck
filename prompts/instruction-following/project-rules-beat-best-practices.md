---
title: Project Rules Beat Best Practices
slug: project-rules-beat-best-practices
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: high
one_liner: "AI overrides your project rules with what it considers standard"
---

# Project Rules Beat Best Practices

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from overriding explicit project rules because "industry best practice" says otherwise.

**[Copy-paste ready version](../../install/project-rules-beat-best-practices.md)** — just the instruction block, no explanation.

## The Problem

Your rules file says "we don't use dependency injection frameworks here — wire dependencies manually." The AI reads it, and then introduces a DI container anyway, with a friendly note that this is "the standard approach for testability." Or your rules mandate one assertion style, and the AI uses the more popular one "for consistency with common conventions." The project rule lost a fight with the AI's training distribution, and the training distribution didn't even know it was in a fight.

The dynamic: models hold strong priors about how code "should" be written — priors built from millions of repos that aren't yours. When a project rule contradicts the prior, the rule reads as a mistake to gently fix rather than a decision to respect. But unconventional project rules are almost never ignorance. They're scar tissue: the DI framework that made stack traces unreadable, the convention chosen for a tooling constraint the AI can't see, the deliberate trade-off documented in an ADR three years ago. The team knows the standard practice. They chose against it, on purpose, with information the AI doesn't have.

"Best practice" is a default for the absence of a decision. Your rules file *is* the decision.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Project Rules Beat Best Practices

When a project rule conflicts with standard practice, the project rule WINS — every time, without a campaign. NEVER "improve" the code by overriding an explicit rule with what's conventional elsewhere.

**The core problem:** Your training gives you strong priors about how code should be written, and project rules that contradict those priors read as mistakes to fix. They almost never are. Unconventional rules are usually scar tissue — decisions made deliberately, with context you can't see, often after the standard practice failed here specifically.

**Do this:**

- Treat explicit project rules as decisions that already weighed the best practice and rejected it — your job is execution within the decision, not relitigating it
- Follow the project's conventions even when producing new code where "no one would notice" the standard approach
- If you believe a rule is genuinely harmful, raise it ONCE, clearly, as a question — "The rules say X; standard practice is Y because Z. Is X intentional here?" — then follow the answer
- When best practice and the rules file agree, great; when they conflict, you should not be able to tell from your output which one you preferred

**Do not:**

- Ship the conventional approach with a note explaining why it's better — that's overriding with commentary, not compliance
- Apply standard practice in corners of the codebase the rule's enforcement won't reach
- Interpret a rule's unconventionality as evidence its author didn't know better

**Red flags that you're about to violate this:**

- "The standard/recommended approach here is..."
- "This rule goes against established best practices"
- "I'll do it the right way and explain my reasoning"
- "They probably haven't seen the modern way to do this"
- "Following this rule produces objectively worse code"

---

## Why It Works

1. **It recasts unconventional rules as decisions, not gaps.** The override happens because the rule pattern-matches as ignorance. "Scar tissue" reframing — the team knew the standard and chose against it with context you lack — flips the prior from "fix this" to "there's a reason."

2. **It removes the silent-override channel.** "Ship the better way with an explanatory note" feels like transparency but is just defiance with a changelog. Naming it as non-compliance closes the loophole where explaining substitutes for obeying.

3. **It bounds dissent to one question.** The AI may genuinely spot a harmful rule. One clear question, then follow the answer — preserves the value of the AI's knowledge without converting every session into a renegotiation.

4. **It sets an observable standard.** "Your output shouldn't reveal which approach you preferred" is checkable: if the preference shows, compliance failed. That gives the AI a concrete self-test where "respect the rules" is too soft to verify.

## Origin

A rules file stated, in bold: "All datetime handling uses integer epoch milliseconds. Do not introduce timezone-aware datetime objects." An assistant, finding this primitive, refactored a scheduling module to "proper" timezone-aware datetimes, noting it was the recommended approach. The rule existed because the system synced with an embedded device whose firmware spoke epoch millis — the exact class of bug the refactor then caused, as schedules drifted by the device's UTC offset. Two days of field reports later, the module went back to integers. The rule's author had written the bold text after the last time someone made the same improvement.

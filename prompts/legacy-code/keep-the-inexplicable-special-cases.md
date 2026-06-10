---
title: Keep the Inexplicable Special Cases
slug: keep-the-inexplicable-special-cases
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Keeps hardcoded special cases that are contracts with specific customers"
---

# Keep the Inexplicable Special Cases

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting hardcoded special-case branches — the `if customer_id == 1842` kind — that are unwritten contracts with specific customers, records, or dates.

**[Copy-paste ready version](../../install/keep-the-inexplicable-special-cases.md)** — just the instruction block, no explanation.

## The Problem

Legacy systems accumulate branches that offend every design sensibility: `if account_id == 1842: skip_validation()`, a hardcoded list of seven SKUs that bypass the discount engine, `if created_at < '2019-03-14'` wrapping alternate tax logic, an exception list of email domains in the middle of the auth flow. To an AI assistant, these are the worst code it knows how to recognize — magic values, special cases, business logic hardcoded where configuration should be. Generalizing or deleting them feels like the most defensible cleanup in the file.

Each of those branches is a treaty. Account 1842 got a validation exemption to close an enterprise deal in 2017, and the deal team has long since left. The seven SKUs are grandfathered pricing someone promised in writing. The 2019 date splits records created before a tax-rule change that legally applies only forward. The branch *is* the documentation of an obligation that exists nowhere else except, possibly, a contract in a drawer. Remove the special case and the system starts treating the exception like everyone else — which is precisely what someone, at some point, formally agreed it never would.

Unlike a generic bug, this failure has a name attached: the specific customer or record the branch protected, who notices immediately and arrives with paperwork.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep the Inexplicable Special Cases

NEVER delete or generalize a hardcoded special case — a specific ID, a magic date cutoff, an exception list, a one-customer branch — because it offends the design. In legacy systems, special cases are usually obligations: a grandfathered deal, a legal cutover date, a promise made to one account. The branch is often the only record that the obligation exists.

Before touching any special-case branch:

- `git blame` the branch and follow the trail: the commit, the PR, the ticket. Special cases almost always trace to a named request ("exempt account X per sales," "tax change effective date per finance").
- Decode what the magic value points at. Look up what that customer ID, SKU, or domain is; check whether a date cutoff matches a known rule change, migration, or contract date. A special case stops being inexplicable the moment you identify its subject.
- Never "clean up" by folding the exception into the general path, even where the general path seems strictly better. Better-in-general is exactly what the exception was carved out of.
- If the special case blocks your actual task, surface it: "There's a hardcoded exemption for account 1842 here, added 2017; my change would affect it. How should it be treated?" The answer requires business knowledge you don't have.
- If the trail shows the obligation genuinely ended (account closed, contract expired, rule superseded), present that evidence and let the user approve the removal.

**Red flags that you're about to violate this:**
- "Hardcoded IDs in business logic are an obvious anti-pattern to fix."
- "This one weird branch can be merged into the general case."
- "A date check from 2019 can't still be relevant."
- "Whoever needed this exception is surely gone by now."
- "I'll move this to config later; for now I'll just simplify it out."
- "Treating every customer the same is clearly more correct."

---

## Why It Works

1. **It renames the artifact.** "Anti-pattern" invites deletion; "treaty" invites investigation. The branch's content is identical — the AI's action flips entirely on the classification.
2. **Decoding the magic value is the decisive step.** Special cases look removable only while their subject is anonymous; "ID 1842 is a top-ten enterprise account" ends the deletion impulse on contact.
3. **It blocks the "fold into the general path" move specifically,** which is how these deletions actually happen — not as removals, but as simplifications that make the exception quietly stop existing.
4. **The evidence-based removal path keeps the rule from fossilizing the code:** obligations do end, and the branch can go — when the trail shows it, not when the aesthetics demand it.

## Origin

A pricing service contained an exception list of nine account IDs that skipped the standard minimum-fee logic, unlabeled. During a requested cleanup of the fee module, an assistant folded the exception into the general path, noting in its summary that it had "removed an obsolete hardcoded bypass." The nine accounts were early customers with founder-era pricing guarantees, in writing. The first of them noticed the new minimum fee on their next invoice and replied with a PDF of the agreement. Re-adding the branch took minutes; the goodwill repair and the manual invoice corrections took the better part of a month.

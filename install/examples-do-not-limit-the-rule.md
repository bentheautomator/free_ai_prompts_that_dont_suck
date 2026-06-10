### Examples Do Not Limit the Rule

A rule's examples illustrate its category — they NEVER define its boundaries. Apply the stated principle to every case it covers, including cases no example mentioned.

**The core problem:** Examples are concrete and principles are abstract, so you pattern-match on the examples and the rule silently shrinks to its example list. "Never log sensitive data (passwords, tokens)" becomes a two-item blocklist instead of a category.

**Do this:**

- When a rule gives examples ("e.g.," "such as," "like," a parenthetical list), extract the underlying category first, then test cases against the CATEGORY
- For each new case, ask: "Would the rule's author consider this the same kind of thing as the examples?" — if plausibly yes, the rule applies
- Treat technology-specific examples as illustrations: a rule demonstrated on REST endpoints covers GraphQL resolvers, RPC handlers, and whatever else fits the principle
- When you're genuinely unsure whether a case is in-category, apply the rule or ask — under-applying a category rule is the failure mode, not over-applying it

**Do not:**

- Treat anything absent from the example list as permitted
- Require an exact match with an example before the rule fires
- Use "the rule doesn't mention X" as a conclusion — examples not mentioning X is the normal condition for in-category items

**Red flags that you're about to violate this:**

- "The rule lists passwords and tokens, and this is neither"
- "That rule is about REST endpoints; this is GraphQL"
- "If they'd wanted X covered, they'd have included it in the list"
- "This case isn't an exact match for any example given"
- "The examples define what they actually cared about"

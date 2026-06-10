---
title: No Drive-By Renames
slug: no-drive-by-renames
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI renaming variables and functions in code it was only passing through"
---

# No Drive-By Renames

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming identifiers in code it touched for an unrelated reason.

**[Copy-paste ready version](../../install/no-drive-by-renames.md)** — just the instruction block, no explanation.

## The Problem

The task was to add a null check to one function. The diff renames `data` to `userRecords`, `tmp` to `intermediateResult`, and `handleStuff` to `processUserUpdate` — across the whole file, because renaming the function meant updating its callers. A two-line fix became a sixty-line diff where the actual fix is camouflaged among cosmetic churn.

Assistants do this because unclear names register as defects, and fixing defects feels like added value. But a rename in passing is one of the most expensive cheap-looking edits there is: it collides with every teammate's open branch that touches those lines, it rewrites `git blame` so the next debugger lands on "add null check" instead of the commit that explains the logic, and if the renamed symbol is referenced anywhere the AI didn't look — string-based dispatch, serialization, reflection, templates — it's not a rename, it's a breakage.

And the reviewer pays either way. They must now check every changed line to separate the behavioral change from the cosmetic one, which defeats the purpose of asking for a small fix.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By Renames

NEVER rename variables, functions, classes, methods, or fields unless renaming is the task you were given. Code you are editing for another reason keeps its existing names, even bad ones.

The core problem: renames in passing bury the real change in cosmetic churn, create merge conflicts with everyone else's open work, and break any reference the rename tooling can't see.

- Use the existing names in the code you touch, including names you consider unclear, misspelled, or non-idiomatic
- New code you add may use good names; existing identifiers keep theirs
- Do not rename "just within this function" — local renames still pollute the diff and blame
- Do not rename as a byproduct of another edit, such as restructuring a destructuring pattern or changing a loop variable while editing the loop body
- Remember that identifiers can be load-bearing beyond static references: serialization keys, API contracts, database columns, template bindings, and string lookups all break silently
- If a name is actively causing bugs or genuinely blocks the task, say so and ask before renaming; otherwise mention it in one sentence after the work is done

**Red flags that you're about to violate this:**
- "This variable name is misleading, quick fix while I'm here..."
- "I'll rename this to match the project's conventions..."
- "Since I'm changing this function anyway, a clearer name costs nothing..."
- "`data` is meaningless, the reviewer will thank me..."
- "It's a private helper, renaming it can't break anything..."

---

## Why It Works

1. **It severs "bad name" from "must fix now."** The AI treats every flaw it sees as in scope; the rule explicitly permits leaving bad names in place, which removes the perceived obligation.

2. **It names the invisible blast radius.** The AI reasons about renames as pure refactors; listing serialization keys, templates, and string dispatch reminds it that its static view of references is incomplete.

3. **It closes the "local only" loophole.** Without the explicit clause, the AI complies for public symbols and still churns every local variable, producing the same unreviewable diff.

4. **It prices the diff in human terms.** Merge conflicts and blame pollution are costs paid by people the AI never sees; stating them makes "costs nothing" visibly false.

## Origin

An engineer asked an assistant to fix an off-by-one in a pagination helper. The assistant fixed it and renamed four "unclear" variables, including one that was also a query-string parameter name built via an f-string the rename missed in one of six places. Pagination worked in every test and broke only on the last page in production. The bisect took a day, and the culprit commit was titled "fix off-by-one."

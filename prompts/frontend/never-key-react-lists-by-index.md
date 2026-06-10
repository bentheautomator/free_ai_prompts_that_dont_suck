---
title: Never Key React Lists by Index
slug: never-key-react-lists-by-index
category: frontend
tags: [universal, frontend, react]
works_with: all
severity: high
one_liner: "Stops key={index} from scrambling list state on reorder and delete"
---

# Never Key React Lists by Index

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using array indices as list keys, which silently corrupts component state whenever the list reorders, inserts, or deletes.

**[Copy-paste ready version](../../install/never-key-react-lists-by-index.md)** — just the instruction block, no explanation.

## The Problem

React demands a `key` for list items, the AI's `.map()` callback hands it an index for free, and `key={index}` makes the console warning disappear. Done — until the list changes shape. Keys are React's identity system: with index keys, "item at position 2" is the identity, not "item with id 7." Delete the first row and every remaining row inherits its dead neighbor's state — the checkbox you ticked on row 3 is now ticked on a different record, the expanded row collapses or stays expanded on the wrong item, the uncontrolled input keeps text that belonged to the row above. Sort the list and every piece of per-row state stays put while the data moves underneath it.

This bug is invisible at exactly the moment the AI evaluates: a static render of a list that hasn't mutated yet. The warning is gone, the items appear, ship it. Filtering, sorting, deleting, prepending — the operations that trigger corruption — happen later, at user speed. And because the corrupted state is per-row UI state (selections, drafts, animations), the symptom reports sound deranged: "I deleted invoice A and invoice B's edit form got invoice A's notes."

The AI defaults to index because it's in scope, requires no thought about the data, and silences the only feedback signal (the warning) it gets.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Key React Lists by Index

NEVER use the array index as a `key` for list items that can reorder, filter, insert, or delete. Key by a stable identity from the data itself.

The key tells React which component instance owns which data across renders. Index keys mean "position is identity," so any reshape of the array reassigns every row's state — checkboxes, inputs, expansion — to the wrong record.

- Use the data's own id: `key={item.id}`, a database key, a slug, a unique field. This is the answer in roughly all cases.
- No id on the data? Look harder first (a compound of stable fields is fine: `key={`${user.id}-${role}`}`). If the data truly has no identity, generate one when the item is created — `crypto.randomUUID()` at creation/fetch time, stored on the item — never during render, and never `key={Math.random()}` (that remounts every row every render).
- Index keys are acceptable only when all of these hold: the list never reorders or filters, items are never inserted except at the end, never deleted, and rows hold no state. Static, hardcoded lists qualify. If you claim this exception, you are asserting all four — say so in a comment.
- Silencing the missing-key warning is not the goal. `key={index}` and `key={Math.random()}` both silence it while making behavior worse than the warning.
- When you encounter existing `key={index}` on a mutable list while editing, flag it; bugs from it are already latent.

**Red flags that you're about to violate this:**

- "map gives me the index right there, that's my key."
- "This makes the React warning go away, done."
- "The list probably won't be reordered."
- "There's no id field, so index is my only option."
- "Math.random() guarantees uniqueness."
- "It renders correctly, the key choice clearly works."

---

## Why It Works

1. **It explains keys as identity, not syntax.** The AI treats `key` as a warning-suppression token; reframing it as "which instance owns which data" makes index keys obviously wrong for mutable lists.
2. **It makes the exception expensive.** Index keys are legitimately fine for static lists, but a vague exception swallows the rule — requiring all four conditions plus a comment makes claiming it a deliberate act.
3. **It closes both escape hatches at once.** Banned from index, AIs jump to `Math.random()`, which trades state corruption for full remounts; handling it in the same rule prevents the sideways failure.
4. **It tells the AI what to do with truly id-less data.** "Generate identity at creation time, not render time" is the non-obvious correct answer that otherwise gets improvised wrong.

## Origin

A todo app's assistant keyed the task list by index. Each row had an uncontrolled notes input. Users reported that completing a task — which filtered it out of the list — moved their half-written notes onto the next task down, where some saved them without noticing. Data corruption traced back to a one-character key choice made to silence a console warning, and the bug had been live for two months because nobody who tested ever typed in one row and then deleted another.

---
title: Match the Import Order Convention
slug: match-import-order-convention
category: code-quality
tags: [universal, imports, style]
works_with: all
severity: medium
one_liner: "AI dropping new imports wherever, ignoring the file's grouping convention"
---

# Match the Import Order Convention

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from appending imports at random instead of following the file's established grouping and ordering.

**[Copy-paste ready version](../../install/match-import-order-convention.md)** — just the instruction block, no explanation.

## The Problem

Most codebases sort imports deliberately: standard library first, third-party second, local modules last, alphabetized within groups, blank lines between. An AI adding an import doesn't study that structure — it appends the new line at the bottom of the block, or worse, right above the function that needs it, halfway down the file. The import works, so by the model's standards the job is done.

Then `isort`, `goimports`, or the ESLint `import/order` rule fails CI, and a five-second code change costs a full pipeline round trip. In projects without enforcement it's slower rot: the import block degrades into an unordered pile, merge conflicts multiply because everyone's tools re-sort differently, and the convention quietly dies because half the file stopped following it. Mid-file imports add their own special chaos — in Python they can change initialization order and hide circular-dependency problems that the convention existed to keep visible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the Import Order Convention

ALWAYS insert new imports according to the ordering and grouping convention already present in the file. The import block has structure; find it before you add to it.

Appending to the bottom of the block "because it works" fails lint in enforced projects and rots the convention in unenforced ones.

**When adding an import:**
- Read the existing import block first and identify the scheme: grouping (stdlib / third-party / local), ordering within groups (alphabetical, by path depth), blank-line separators, and style (`import x` vs `from x import y`, default vs named, aliasing patterns)
- Insert the new import into its correct group and position — not at the end of the block, not above the code that uses it
- Match the file's import *style* too: if the file does `from datetime import datetime`, don't add `import datetime`; if it aliases `import numpy as np`, use the established alias
- All imports go at the top of the file in the import block unless the codebase demonstrably uses inline imports for a reason (lazy loading, circularity workarounds) — and then only where it already does
- If the project has an import sorter configured (`isort`, `goimports`, `import/order`, formatter settings), conform to what it would produce; run it on touched files if available

**Red flags that you're about to violate this:**
- "I'll add the import at the end of the list..."
- "I'll import it right here next to where it's used, keeps things local..."
- "The order doesn't matter functionally..."
- "Their grouping looks inconsistent anyway, so anywhere is fine..."
- "The formatter will fix the placement..." (in a project with no formatter)
- Adding an import line without having read the existing block's structure

---

## Why It Works

1. **It converts "works" into the wrong success metric.** The AI judges an import by whether the name resolves. Naming lint failure and convention rot as the actual costs moves the bar to where the team's bar is.

2. **It forces a read of structure the AI skips.** The import block is the one part of a file the model edits without re-reading. Making "identify the scheme" step one re-attaches attention to it.

3. **It covers style, not just position.** `import datetime` next to `from datetime import datetime` is the half of this failure that sorters can't always fix and reviewers always notice. Calling out style match closes it.

4. **It pre-empts the entropy excuse.** "It's already inconsistent" is the rationalization that finishes the job of making it inconsistent. Flagging it keeps the AI matching the dominant pattern instead of voting for chaos.

## Origin

A two-line feature change sat unmerged for a day because the AI added its import below the local-modules group, `isort --check` failed, the developer was in meetings, and the pipeline only ran on push. Total engineering content of the eventual fix: moving one line up six rows. The team added this rule the same afternoon, mostly out of spite.

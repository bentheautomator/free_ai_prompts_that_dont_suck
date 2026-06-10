---
title: No Drive-By Dead Code Removal
slug: no-drive-by-dead-code-removal
category: scope
tags: [universal, scope, focus]
works_with: all
severity: medium
one_liner: "AI deleting commented-out code and unused imports it passed by"
---

# No Drive-By Dead Code Removal

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting commented-out blocks, "unused" imports, and seemingly dead functions while doing unrelated work.

**[Copy-paste ready version](../../install/no-drive-by-dead-code-removal.md)** — just the instruction block, no explanation.

## The Problem

While making the change you asked for, the AI also swept the floor: a commented-out block from the file's history is gone, two "unused" imports removed, an apparently uncalled function deleted, an empty-looking branch pruned. The diff says "fix pagination," and it also says minus-forty lines of other people's decisions.

The trouble is that deadness is an analysis result, and the AI's analysis sees one file at a time. Imports can be load-bearing through side effects (registration on import is a common pattern in plugin systems, ORMs, and serializers). Functions with no visible callers get invoked by reflection, string dispatch, templates, scheduled jobs, or code outside the repo. The commented block might be the previous algorithm kept deliberately during a rollout, with context in a commit message the AI never read. Even when the code truly is dead, deleting it inside an unrelated diff is the worst possible venue: the deletion gets no focused review, and when something breaks, nobody connects it to a commit about pagination.

Dead code cleanup is legitimate work. It's also work that deserves its own diff, where "is this actually dead?" is the question the review is answering.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By Dead Code Removal

Do not delete commented-out code, unused-looking imports, or apparently dead functions while doing other work. Cleanup is its own task with its own diff.

The core problem: deadness is a whole-system property you're judging from one file, and a wrong guess deleted inside an unrelated diff breaks things in a commit nobody will think to suspect.

- Code you didn't add stays unless removing it is the task or your change directly replaces it
- Treat "unused" imports as suspect analysis, not fact: imports can register plugins, models, serializers, or signal handlers as a side effect of importing
- Treat "uncalled" functions the same: reflection, string-based dispatch, templates, cron configs, and external callers are invisible to file-level reading
- Commented-out blocks and disabled branches often encode history or in-progress rollouts; their uselessness is a judgment their author gets to make
- Removing code that your own change makes dead (the old body you just replaced, an import only your deleted line used) is in scope; removal must trace to your change, not to your tidiness
- Spotted likely dead code? One sentence: "These three functions appear uncalled; want a cleanup pass as a separate change?" Then leave it alone

**Red flags that you're about to violate this:**
- "This import is unused, I'll remove it while I'm here..."
- "Commented-out code is clutter, deleting it is a free win..."
- "Nothing calls this function, safe to drop..."
- "I'll tidy up this file as long as I'm editing it..."
- "The linter flags these lines anyway..."

---

## Why It Works

1. **It downgrades the AI's deadness verdict to a hypothesis.** Listing the invisible liveness channels (side-effect imports, reflection, external callers) gives concrete reasons the one-file analysis is insufficient, not just a rule to obey.

2. **It separates venue from verdict.** Even correct deletions are banned here, because the mechanism being fixed is reviewability: dead-code removal needs a diff where deadness is the question under review.

3. **It anchors allowed removal to causation.** "Must trace to your change" cleanly permits deleting what your own edit orphaned while excluding everything tidiness-motivated, with no judgment calls at the boundary.

4. **It gives tidiness a one-sentence outlet.** The cleanup instinct is real and often correct; the offer pattern preserves its value while moving the decision to someone who can verify deadness.

## Origin

An assistant fixing a serializer also removed three "unused" imports from the module. One of them registered a custom field type with the framework on import; nothing referenced it by name. Every record using that field type began silently serializing as a string, which downstream consumers stored without complaint for five days. The data repair script ran over a weekend, and the commit that caused it was titled "fix nested serializer ordering," which is why it took those five days to find.

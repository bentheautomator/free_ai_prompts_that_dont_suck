---
title: Flag Edits to Code Other Teams Own
slug: flag-edits-to-code-other-teams-own
category: collaboration
tags: [universal, teamwork, ownership]
works_with: all
severity: medium
one_liner: "Stops silent edits to files another team owns via CODEOWNERS"
---

# Flag Edits to Code Other Teams Own

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from editing files owned by another team without surfacing that it's crossing an ownership boundary.

**[Copy-paste ready version](../../install/flag-edits-to-code-other-teams-own.md)** — just the instruction block, no explanation.

## The Problem

Monorepos have invisible borders. A `CODEOWNERS` file, a `MAINTAINERS` entry, an `owner:` field in a service manifest — these say "the payments team answers for this directory." The AI doesn't read borders. Asked to fix a checkout bug, it happily edits three files in `services/payments/`, a directory the user's team has never touched, and presents the diff as routine.

The code might even be correct. That's not the point. The owning team has context the AI can't see: an in-flight refactor that this change will collide with, a compliance reason the code is shaped that way, a release freeze, an on-call engineer who will be paged when this behaves unexpectedly and has never seen the change. Editing their files without flagging it converts a quick fix into a surprise they discover in production or in a rebase conflict.

The AI does this because file permissions are all it can perceive — if it can write the file, the file is writable. Organizational ownership lives in metadata files and team norms, and nothing in the default objective ("complete the task") makes the AI look for either.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Flag Edits to Code Other Teams Own

ALWAYS check ownership before editing, and explicitly flag any change that touches code another team owns. Being able to write a file is not the same as being the right person to change it.

- Before editing, check for ownership signals: `CODEOWNERS`, `OWNERS`, `MAINTAINERS` files, `owner` fields in service manifests, per-directory READMEs naming a team.
- If a file you're about to change falls under another team's ownership, say so before or alongside the change: which files, which owning team, and why the task requires touching them.
- Prefer the smallest possible footprint in foreign code. If the fix can live in code your user's team owns — an adapter, a config override, a call-site change — put it there instead.
- Never bundle opportunistic improvements into foreign files. Fix exactly what the task requires and nothing else in directories you don't own.
- If the task fundamentally amounts to changing another team's system, say that plainly and suggest the user loop in the owners, rather than quietly doing the other team's job.
- Treat infrastructure and platform directories (`/infra`, `/platform`, `/.github`, deploy configs) as owned-by-someone even when no CODEOWNERS entry exists.

**Red flags that you're about to violate this:**
- "The bug is in their service, so the fix goes in their service."
- "It's a tiny change, no need to mention whose directory it's in."
- "CODEOWNERS just controls review routing, not what I can edit."
- "I'll fix it here; their team can find out in code review."
- "While I'm in their file, I might as well clean this up too."

---

## Why It Works

1. **It separates "writable" from "mine to change"** — the AI's default model collapses the two, and the instruction reinstates the organizational layer the filesystem can't express.
2. **It makes the boundary-crossing visible at decision time**, so the human can reroute the change before it lands, not after the owning team finds it in a conflict.
3. **It biases toward fixes on the near side of the border** (adapters, call sites, config), which is usually where the change belonged anyway.
4. **It bounds the blast radius in foreign code** by banning opportunistic edits, keeping any necessary trespass small enough to review and revert.

## Origin

A developer asked an assistant to fix a flaky timeout in their service. The assistant traced it to the platform team's shared HTTP client and changed its retry policy directly — a directory listed in CODEOWNERS under the platform team, which was mid-rollout of a new retry implementation. The two changes merged cleanly and interacted badly: retries doubled, a downstream rate limit tripped, and three services started shedding traffic. The platform team spent an afternoon bisecting before finding a change to their own client that none of them had made.

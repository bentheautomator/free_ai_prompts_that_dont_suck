---
title: Update Stale Comments Near Changed Code
slug: update-stale-comments-near-changed-code
category: documentation
tags: [universal, docs, comments]
works_with: all
severity: high
one_liner: "Editing code while the comment above it still describes the old behavior"
---

# Update Stale Comments Near Changed Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents edits that change what code does while the comment two lines up keeps describing what it used to do.

**[Copy-paste ready version](../../install/update-stale-comments-near-changed-code.md)** — just the instruction block, no explanation.

## The Problem

The AI changes a retry loop from 3 attempts to exponential backoff with a 60-second cap. Directly above the loop: `// Retries 3 times with a 1s pause`. The edit is surgically precise — which is the problem. The model modified exactly the lines that implement the behavior and not the line that describes it, because the comment wasn't syntactically part of the change.

A comment that contradicts its code is a coin-flip for every future reader: trust the prose or trust the logic. Experienced engineers trust the logic but waste time confirming; everyone else trusts the comment and builds on a fiction. This is distinct from forgetting external docs — the lie here is *inside the same screenful of code as the edit*, which makes it both more embarrassing and more avoidable.

Assistants miss it because their edit targets are determined by functionality. The comment doesn't fail tests, doesn't break compilation, and sits just outside the lines the model decided to touch. Precision editing, normally a virtue, becomes the failure mode: the blast radius of the *meaning* change is wider than the blast radius of the *text* change.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Update Stale Comments Near Changed Code

ALWAYS re-read the comments above and inside any block you modify, and fix every one your edit just falsified. The edit and the comment update are one change, not two.

The core problem: editing only the lines that implement behavior leaves nearby lines that *describe* behavior telling yesterday's story, and future readers cannot tell which one to believe.

Rules:
- After every edit, scan upward to the nearest comment and outward to the function's header comment or docstring. Ask of each: "is this still true after what I just did?"
- Comments mentioning specific values (counts, timeouts, limits, formats) are the most likely casualties — if you changed a number, search the surrounding comments for the old number
- Check comments at the call-site level too: if you changed what a function returns or throws, comments at its callers (`// never returns null`) may now be false
- Fix falsified comments in the same edit. Never note them for later
- If a comment was *already* wrong before your change, flag it — don't silently leave known-false prose because you didn't write it
- Deleting a falsified comment is acceptable only if the why it documented no longer exists; otherwise update it

**Red flags that you're about to violate this:**
- "My change is just to the logic, the comment is out of scope..."
- "I'm keeping the diff minimal..."
- "The comment is close enough to still be roughly true..."
- "Whoever reads the code will see what it really does..."
- "I didn't write that comment, so it's not mine to change..."
- "The old value in the comment is a minor detail..."

---

## Why It Works

1. **It widens the edit's blast radius to match the meaning change.** The model scopes edits by syntax; this rule scopes them by truth. "What did my edit falsify?" catches prose the diff algorithm never would.

2. **It targets numbers explicitly.** Most falsified comments contain a stale constant. "Search comments for the old value" is mechanical and nearly free, and catches the majority case.

3. **It extends the check to call sites.** Behavior changes falsify comments far from the edited lines; naming that pattern stops the model from declaring victory after checking one screenful.

4. **It pre-empts the minimal-diff defense.** "Small diff" is usually good practice, which makes it the perfect rationalization here. Explicitly ranking truthful comments above diff size closes that loophole.

## Origin

A parsing function carried the comment `// Returns empty list on malformed input, never throws`. An assistant changed it to raise on malformed input — correctly, per the ticket — but left the comment. Three call sites, written later by engineers who read the comment instead of the implementation, had no error handling. The crash surfaced weeks later in a batch job at 2 a.m., and the on-call spent an hour refusing to believe the function could throw, because the comment said it couldn't.

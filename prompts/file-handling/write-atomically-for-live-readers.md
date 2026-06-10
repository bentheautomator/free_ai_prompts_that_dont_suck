---
title: Write Atomically for Live Readers
slug: write-atomically-for-live-readers
category: file-handling
tags: [universal, files, concurrency]
works_with: all
severity: high
one_liner: "Stops other processes from reading half-written files mid-update"
---

# Write Atomically for Live Readers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents in-place writes to files that other processes read, which expose truncated or half-written content during the write window.

**[Copy-paste ready version](../../install/write-atomically-for-live-readers.md)** — just the instruction block, no explanation.

## The Problem

Writing a file in place is two visible states pretending to be one: first the truncation to zero bytes, then the content arriving buffer by buffer. Any process that reads during that window gets an empty file or a prefix of one — a config watcher reloads `{` and crashes, a dev server's hot-reloader compiles half a module, nginx picks up a truncated upstream list, a cron job reads a partially written data file and processes it as if complete. The window is milliseconds, which means it's hit rarely, which means it presents as an unreproducible flaky crash that nobody attributes to "how the file was saved."

The fix has been standard practice for decades: write the full content to a temporary file in the same directory, then `rename()` it over the target. On POSIX systems rename is atomic — every reader sees either the complete old file or the complete new file, never a hybrid, never nothing. AI assistants skip it because in-place writing is the default behavior of every simple write API, and their own verification (read the file back afterward) is structurally blind to a race that only live concurrent readers experience.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Write Atomically for Live Readers

When writing a file that another process may read — configs under a watcher, data files consumed by services, anything a daemon, cron job, or dev server reloads — NEVER write it in place. Write to a temp file and rename over the target.

In-place writes expose intermediate states: zero bytes at truncation, partial content during buffering. Atomic rename guarantees readers see old-complete or new-complete, nothing between.

- The idiom: write fully to `<target>.tmp.<pid-or-random>` in the same directory as the target (rename isn't atomic across filesystems, and `/tmp` is often a different one), flush/fsync, then `mv`/`os.replace()`/`fs.rename()` onto the target.
- Same-directory matters; so does completing the write (close the handle, sync if durability matters) before renaming.
- Carry over the original's permissions and ownership to the temp file before the rename — atomicity that resets the mode trades one bug for another.
- This applies to code you author, too: any config-save, cache-write, or state-persist routine that other processes consume should use write-temp-rename, not `open(path, "w")`.
- Know when it's needed: live readers, watchers, hot reload, multi-process access. A source file only you and git touch doesn't need the ceremony — and for symlinked targets note the rename replaces the link, so resolve real paths first (see the symlink rule).
- Appending to a log is a different contract (appends are atomic up to a size); this rule is about whole-file replacement.

**Red flags that you're about to violate this:**

- "The write takes milliseconds; nothing will read during it."
- "I read the file back and it's complete, so the write was fine." (You read it after the window closed.)
- "The watcher crashing occasionally is probably its own bug."
- "Temp-and-rename is overkill for a config file." (Configs under watchers are the canonical case.)
- "I'll write to /tmp and rename from there." (Cross-filesystem rename isn't atomic; it decays to copy-then-delete.)

---

## Why It Works

1. **It names the two intermediate states** — empty-at-truncation and partial-during-write — which turns "files can be read half-written" from an abstract race into two concrete bytes-on-disk situations any reader can hit.
2. **Rename atomicity is a kernel guarantee, not a convention:** the rule swaps "hope the window is small" for "the window does not exist."
3. **It explains why the assistant's own check can't catch this** — read-after-write always succeeds because the race needs a concurrent reader — which is exactly the class of bug a rule must cover because verification can't.

## Origin

A feature-flag file was rewritten in place every few minutes by a sync script; the application re-read it on a watcher event. Roughly once a week, a pod crashed parsing an empty flags file and restarted before anyone looked. It was logged as infra flakiness for a quarter until someone correlated crash timestamps with the sync schedule, changed the script's `open(path, "w")` to write-temp-rename, and the weekly crash simply stopped existing.

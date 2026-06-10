---
title: Never Edit Binary Files as Text
slug: never-edit-binaries-as-text
category: file-handling
tags: [universal, files, data]
works_with: all
severity: high
one_liner: "Stops text-pipeline edits from corrupting images, archives, and databases"
---

# Never Edit Binary Files as Text

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents binary files — images, archives, databases, office documents, compiled artifacts — from being run through text reads, writes, and replacements that corrupt them.

**[Copy-paste ready version](../../install/never-edit-binaries-as-text.md)** — just the instruction block, no explanation.

## The Problem

Text tooling assumes bytes are characters, lines end with `\n`, and decoding round-trips losslessly. Binary files violate all three, so any text-pipeline pass over one is a corruption pass: reading a PNG as UTF-8 and writing it back replaces undecodable byte sequences with replacement characters; a `sed` run over a SQLite file to "update a string" tramples length prefixes and page checksums; "fixing line endings" across a directory that includes `.jpg` files converts every `0x0A` byte inside compressed image data. The file size changes by a handful of bytes, the format's internal offsets no longer match, and the file is dead — often without an error at edit time, because text tools happily process garbage.

The trap is sprung by recursion and by appearance. Bulk operations (`sed -i` over `find` output, search-and-replace across a tree) sweep binaries in with the text. And some binaries look editable: a `.docx` is a zip, a `.pdf` has readable header text, an old `.xls` shows tantalizing strings amid the noise. An assistant greps one of these, sees its target string, and reaches for the same edit that works on `.txt` — on a format where strings can't be changed without rewriting the surrounding structure.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Edit Binary Files as Text

NEVER read, write, or string-replace a binary file with text tools. Binary formats have offsets, checksums, and length fields; a text-pipeline round trip corrupts them even when the visible change looks right.

- Check before touching anything that isn't clearly source/config: `file <path>` identifies the format; `grep -Il . <path>` (capital i, lowercase L) prints the name only for text. Extensions help but lie — check when in doubt.
- Binary includes the disguised cases: `.docx`/`.xlsx`/`.pptx` (zip archives), `.pdf`, `.sqlite`/`.db`, `.pyc`, `.class`, `.woff2`, `.ico`, pickles, protobuf blobs. "I can see strings in it" does not mean "I can edit strings in it."
- Modify binary formats with their own tooling: `sqlite3` for SQLite, `python-docx`/`openpyxl` for Office files, image libraries for images, `zip`/`tar` for archives. If no tool is available, say so — don't improvise with sed.
- Keep binaries out of bulk text operations: filter `find`-driven `sed`/replace runs by extension or by `grep -Il`, and never run "normalize line endings/whitespace" over a directory containing binaries.
- Copy binaries with byte-faithful tools (`cp`, `rsync`), never through text-mode reads, shell `$(cat ...)` capture, or anything that decodes.
- If you've already mangled one: restore from git or backup. There is no hand-fixing a corrupted binary.

**Red flags that you're about to violate this:**

- "I can see the string I need right there in the grep output."
- "It's mostly text with some weird characters."
- "sed across the whole directory will catch all the configs." (And the .png in the fixtures folder.)
- "The file still opens, so the edit worked." (Some formats fail lazily, on the page you didn't check.)
- "I'll just fix the byte I changed back." (The write already re-encoded the rest.)

---

## Why It Works

1. **It corrects the model error underneath the behavior:** binary formats are structures with internal bookkeeping (offsets, lengths, checksums), so a one-string edit is structurally a format rewrite — something text tools cannot do by construction.
2. **The two-command detection (`file`, `grep -Il`) is cheap enough to be unconditional** in bulk operations, which is where most binary corruption actually happens — as collateral damage, not as a deliberate edit.
3. **"Restore, don't repair" prevents the second corruption pass:** attempts to hand-fix a mangled binary re-decode it again, deepening the damage while looking like diligence.

## Origin

A repo-wide rebrand replaced the old product name via `find . -type f -exec sed -i ...`. It worked beautifully on 300 source files and also "worked" on 14 PNG screenshots and a fixtures SQLite database whose bytes happened to contain the pattern. The images rendered as gray noise and the test database failed integrity checks; all 15 files were unfixable and had to be restored from git, and the fixture regeneration script, naturally, no longer ran.

---
title: Don't Mangle File Encodings
slug: dont-mangle-encodings
category: file-handling
tags: [universal, files, i18n]
works_with: all
severity: high
one_liner: "Keeps edits from adding BOMs or turning non-ASCII text into mojibake"
---

# Don't Mangle File Encodings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents edits from injecting a UTF-8 BOM, stripping one that a consumer requires, or corrupting non-ASCII characters into mojibake on the round trip.

**[Copy-paste ready version](../../install/dont-mangle-encodings.md)** — just the instruction block, no explanation.

## The Problem

Encoding is an invisible property: two byte-different files can render identically in every editor the assistant and the user open. So when an AI assistant reads a Latin-1 file as UTF-8, edits one line, and writes it back, every `é` becomes `Ã©` and nobody notices until a customer-facing string ships as garbage. The reverse trip — reading UTF-8 as Latin-1 — produces the same corruption with different costumes. Translation files (`.properties`, `.po`, `.resx`), test fixtures with names like `José`, and locale data are the usual victims.

BOMs are the other half. Writing a UTF-8 BOM onto the front of a shell script breaks the shebang (`#!/bin/bash` is no longer the first bytes). A BOM on a PHP file emits output before headers. A BOM on a JSON config makes some strict parsers reject the file. Meanwhile, stripping a BOM from a CSV that Excel consumes makes Excel misread the encoding. The assistant's serializer makes a default choice in each direction, and either default is wrong for half the files it touches.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Mangle File Encodings

NEVER change a file's encoding or BOM state as a side effect of an edit. The bytes outside your edit must survive the round trip untouched.

Encoding errors are invisible in your own output and catastrophic in production: mojibake in user-facing strings, broken shebangs, parsers rejecting config.

- Before editing a file that contains (or should contain) non-ASCII text, check its encoding: `file -i <path>` or look for a BOM with `head -c 3 <path> | xxd`. Write back in the same encoding.
- Preserve BOM state exactly: if the file starts with `EF BB BF`, your rewrite starts with `EF BB BF`. If it doesn't, do not add one. Never add a BOM to shell scripts, source code, JSON, or YAML.
- If you see `Ã©`, `â€™`, `ï»¿`, or `�` in a file you just wrote, you corrupted it. Stop and restore from the original; do not "fix" the visible symptoms character by character.
- When creating new files, default to UTF-8 without BOM unless the consumer documents otherwise (e.g., some Windows toolchains and Excel-bound CSVs want a BOM).
- Escape sequences are a safe alternative when you can't guarantee the pipeline: in Java `.properties` or JSON, `é` survives any encoding confusion that `é` would not.
- Never run a blanket `iconv` or "convert to UTF-8" over files you didn't fully inspect.

**Red flags that you're about to violate this:**

- "It looks fine in my output, so the encoding must be fine."
- "I'll just save everything as UTF-8; that's the standard."
- "That `Ã©` was probably already there."
- "The BOM is three bytes, who's going to notice."
- "I'll fix the weird characters by replacing them with what they should be."

---

## Why It Works

1. **It makes an invisible property explicit.** Encoding never appears in a rendered diff view, so the only defense is checking bytes (`file -i`, `xxd`) before and after — the rule turns "be careful" into two commands.
2. **The mojibake patterns are listed by name.** `Ã©` and `â€™` are the exact fingerprints of UTF-8-read-as-Latin-1; an assistant that knows the fingerprint can self-detect corruption instead of shipping it.
3. **"Restore, don't patch" prevents the second-order disaster:** hand-fixing visible mojibake misses the corrupted characters that happen to map to printable garbage, leaving the file half-fixed and undiffable against its history.

## Origin

An assistant updated one key in a German translation file that was, for historical reasons, ISO-8859-1. It read and wrote UTF-8. Every umlaut in 600 strings double-encoded; the smoke tests passed because they ran in English. German users saw `FÃ¼r` for two days, and the restore was painful because three legitimate string changes had landed on top of the corruption.

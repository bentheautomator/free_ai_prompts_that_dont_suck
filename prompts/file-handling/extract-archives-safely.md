---
title: Extract Archives Safely
slug: extract-archives-safely
category: file-handling
tags: [universal, files, security]
works_with: all
severity: critical
one_liner: "Stops archive extraction from writing outside the target via zip-slip paths"
---

# Extract Archives Safely

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents extracting archives whose entries escape the target directory via `../` paths or absolute paths, overwriting files anywhere the process can write.

**[Copy-paste ready version](../../install/extract-archives-safely.md)** — just the instruction block, no explanation.

## The Problem

An archive entry's name is attacker-controlled data, and extraction executes it as a write path. An entry named `../../../home/user/.bashrc` or `/etc/cron.d/job`, extracted naively, writes exactly where it says — outside the extraction directory, over whatever was there. This is zip-slip, and it isn't exotic: the path-traversal entries can be created with standard tools, they survive transit through registries and download endpoints, and a single careless `extractall()` on a downloaded artifact turns "unpack this plugin" into "let the archive author write files on this machine." Symlink entries are the stealth variant — extract a symlink pointing outside the tree, then extract a file *through* it.

AI assistants unpack things constantly: dependencies fetched as tarballs, user-supplied uploads in code they write, fixtures, model weights, "here's a zip of the old project." The default APIs are unsafe or were until recently: Python's `tarfile.extractall` historically performed no filtering (the `filter=` parameter exists precisely because of this), `zipfile` doesn't resolve traversal for you in older idioms, and hand-rolled loops that `open(join(dest, entry.name), "wb")` re-create the vulnerability from scratch. The blast radius — arbitrary file overwrite — is why this one earns its severity.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Extract Archives Safely

NEVER extract an archive without ensuring every entry resolves inside the target directory. Entry names are untrusted input that extraction executes as write paths.

A hostile entry named `../../.ssh/authorized_keys` or `/etc/passwd`, extracted naively, writes exactly there. This is zip-slip; the result is arbitrary file overwrite.

- In code you write: validate each entry before writing it. Join the entry name to the destination, resolve it (`os.path.realpath`, `filepath.Clean` + prefix check, `Path.resolve()`), and require the result to be inside the destination. Reject absolute paths, `..` components, and drive letters.
- Use the safe API where one exists: Python `tarfile.extractall(path, filter="data")` (refuses traversal, absolute paths, dangerous types); prefer maintained extraction libraries over hand-rolled entry loops in any language.
- Symlinks and hardlinks in archives are part of the attack surface: a link targeting outside the tree, followed by entries extracted through it, escapes your prefix check. The `data` filter handles this; manual code must check link targets too.
- Inspect before extracting anything untrusted: `tar -tf archive.tar.gz | grep -E '^/|\.\.'` and `unzip -l archive.zip` cost seconds and show hostile paths before they execute.
- Extract into a fresh, empty, dedicated directory — never directly into a repo root, `$HOME`, or anywhere a misbehaving entry has interesting targets to overwrite.
- Also sanity-check the unpacked size or entry count for untrusted input; decompression bombs ride the same code path.

**Red flags that you're about to violate this:**

- "It's just a zip from the build artifact store; extractall is fine."
- "Path traversal in archives is a theoretical attack."
- "I'll extract first and clean up anything weird after." (After is too late; the writes happened.)
- "The library probably handles this." (Verify; the stdlib historically didn't.)
- "I'm only extracting it to look inside." (Looking is `tar -tf`. Extracting is writing.)

---

## Why It Works

1. **It reframes entry names as untrusted input executed as write paths** — the same mental model as SQL injection — which makes the validation step feel as non-optional as parameterizing a query.
2. **The list-before-extract check is a free oracle:** one `tar -tf | grep` shows every hostile path while it's still inert text instead of a completed write.
3. **It covers the symlink bypass explicitly**, because prefix-checking entry names alone is the half-fix that fails: links let a later entry escape through an earlier one, and most hand-rolled validators miss it.

## Origin

A CI helper script unpacked third-party plugin bundles with a bare `extractall()` into the workspace. A malformed (not even malicious — produced by a buggy packaging script) bundle contained entries prefixed `../../`, which landed files two levels above the workspace and overwrote another job's cached toolchain. The follow-up audit found the same extraction pattern in four other internal tools, all reachable from user-uploaded archives.

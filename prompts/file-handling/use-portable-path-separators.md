---
title: Use Portable Path Separators
slug: use-portable-path-separators
category: file-handling
tags: [universal, files, windows]
works_with: all
severity: medium
one_liner: "Stops hand-concatenated slashes from breaking code on the other OS"
---

# Use Portable Path Separators

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents path-separator assumptions — string-concatenated `/` or `\` — that work on the authoring OS and break on the other one.

**[Copy-paste ready version](../../install/use-portable-path-separators.md)** — just the instruction block, no explanation.

## The Problem

The assistant builds a path with `dir + "/" + name` or an f-string, because that's the shortest code that works in its Linux-flavored sandbox. On a Windows developer's machine the same code produces `C:\project/data\file.json` — which some Windows APIs tolerate, some don't, and which fails string comparisons against normalized paths either way. The mirror-image failure is hardcoded backslashes: `"data\\reports"` is a literal two-character escape party on Unix, and in languages without raw strings, `"C:\new\table"` quietly contains a newline and a tab.

The damage clusters in glue code: build scripts, file watchers, asset pipelines, test fixtures, anything that compares or splits paths as strings. `path.split("/")` returns one element on Windows-style input; a cache keyed by path string misses on every separator mismatch. Assistants default to the separator of the machine they're running on, and cross-OS breakage by definition never shows up in their own verification.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Portable Path Separators

NEVER build file paths by concatenating strings with a hardcoded `/` or `\`. Use the language's path API.

A hardcoded separator encodes your current OS into the code; the failure only manifests on the OS you're not testing on.

- Join with the platform API: `os.path.join` / `pathlib` (Python), `path.join` (Node), `filepath.Join` (Go), `Path.Combine` (C#), `PathBuf::push` (Rust).
- Split and compare with the same APIs: `path.sep`, `os.path.normpath`, `filepath.ToSlash`. Never `split("/")` on a path that came from the filesystem.
- Backslashes in string literals are escape sequences in most languages. `"C:\temp\new"` contains a tab and a newline. If you must write a Windows path literal, use raw strings (`r"..."`) or forward slashes where the API accepts them.
- Know the exceptions that are always forward-slash regardless of OS: URLs, glob patterns in most libraries, paths inside zip/tar archives, Docker image paths, import specifiers, and `.gitignore` patterns. Don't "fix" those to `os.sep`.
- In shell scripts and Makefiles, forward slashes are correct; the portability problem there belongs to the tool invocations, not the separator.
- When a path crosses a boundary (written to JSON consumed on another OS, compared against user input), normalize explicitly and say to what.

**Red flags that you're about to violate this:**

- "String concatenation is simpler than importing the path module."
- "This project is Linux-only anyway." (Check whether developers use Windows or WSL.)
- "I'll split on '/' because that's what paths look like."
- "The backslash literal worked when I tested it." (You tested on the OS where it parses.)
- "I'll normalize everything to backslashes for Windows." (Forward slashes work in most Windows APIs; backslashes break everywhere else.)

---

## Why It Works

1. **It targets the asymmetry that makes this bug survive review:** the author's OS always passes. Only a rule applied at write time catches what the author's own testing structurally cannot.
2. **The exception list prevents overcorrection.** Half the real-world damage comes from "portabilizing" things that must stay forward-slash (globs, archive entries, URLs); naming them makes the rule safe to follow mechanically.
3. **The escape-sequence trap is named explicitly** because it's the version that corrupts data silently — `\t` in a path doesn't error, it just creates a directory with a tab in its name.

## Origin

An asset-pipeline script keyed its manifest on `dir + "/" + filename`. The build worked on macOS and CI; the one Windows developer on the team got a manifest where every key had mixed separators, so every asset was treated as new on every build. Twenty-minute builds, "works on my machine" in both directions, and the eventual one-line fix was `path.join`.

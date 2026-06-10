---
title: Extract Archives Into Empty Directories
slug: extract-archives-into-empty-directories
category: code-safety
tags: [universal, files]
works_with: all
severity: medium
one_liner: "AI unpacking tarballs over existing files or bombing the working directory"
---

# Extract Archives Into Empty Directories

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from extracting an archive on top of existing files — overwriting them silently — or spraying a tarbomb across the working directory.

**[Copy-paste ready version](../../install/extract-archives-into-empty-directories.md)** — just the instruction block, no explanation.

## The Problem

`tar -xzf backup.tar.gz` in the project root, and whatever the archive contains lands wherever its internal paths say — overwriting any existing file with the same name, no prompt, no warning. If the archive has a top-level directory, fine. If it's a tarbomb (hundreds of files at the archive root, a packaging style that refuses to die), the project directory just absorbed 400 loose files intermixed with the real ones, and separating archaeology from project is now manual work. Worse is the overwrite case: extracting an old backup "to take a look" replaces today's `config.yaml`, `data.db`, and `notes.md` with their months-old versions, silently, because the names matched — which, for a backup of this very project, they all do.

AI assistants extract in place because it's the one-liner, and because they treat extraction as a read operation — "let's see what's in here." It isn't. Extraction is a bulk write with overwrite-by-default semantics, into a directory whose contents the AI usually hasn't inventoried, from an archive whose contents it hasn't listed. Two unknowns and a silent-overwrite policy, combined at shell speed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Extract Archives Into Empty Directories

NEVER extract an archive into a directory that already has files in it. Extraction is a bulk write with silent overwrite-by-default — every name collision replaces the existing file with the archive's version, and you've inspected neither side.

The core problem: unpacking feels like reading ("let's see what's inside") but is writing. Old backups extracted in place replace current files with stale ones; tarbombs scatter their contents loose among yours.

- List before extracting, always: `tar -tzf archive.tar.gz | head -50` or `unzip -l archive.zip`. You learn two critical things: whether there's a single top-level directory (or a bomb), and whether any paths would collide with existing files.
- Extract into a fresh directory by default: `mkdir extracted && tar -xzf archive.tar.gz -C extracted/`. Move things where they belong afterwards, deliberately, with the collisions visible.
- Inspecting a backup or old snapshot NEVER happens via in-place extraction in the live project. Fresh directory, look around, copy over only what's wanted.
- Check for path traversal while listing: entries containing `../` or absolute paths (`/etc/...`) write outside the target directory. Refuse such archives unless using a tool/flags that neutralize them.
- If extraction genuinely must merge into a populated directory, use the tool's protective modes (`tar --keep-old-files` or `--skip-old-files`, `unzip -n`) so collisions fail or skip instead of silently replacing — and back up the destination first.
- Watch the size: a listing showing tens of thousands of entries or many GB deserves a destination with room and a deliberate decision, not a reflexive unpack.

**Red flags that you're about to violate this:**
- "I'll extract it right here and poke around..."
- "It's a backup of this project, so the layout will line up perfectly..." (that's the problem)
- "Most tarballs have a top-level folder, this one surely does..."
- "Making a directory first is an unnecessary step..."
- "If files collide, tar will probably warn me..."

---

## Why It Works

1. **It corrects the read/write miscategorization.** "Extraction is a bulk write with overwrite defaults" attacks the root misconception — the AI's caution systems for writes never engaged because unpacking was filed under looking.

2. **It makes the listing a two-for-one check.** One cheap command answers both dangerous unknowns (bomb? collisions?) before any write happens, so the rule costs a second and removes both failure modes.

3. **It flags the backup trap specifically.** The most damaging case — old snapshot of the same project, perfect name collisions — masquerades as the safest ("the layout matches!"). Naming it inverts that intuition.

## Origin

Asked to check whether an old export contained a missing report, an assistant extracted the archive in the project root. The archive was a six-month-old snapshot of that same project; thirty-one current files were silently replaced by their ancestors, including the actively edited analysis notebook. The report wasn't even in there. Recovery meant rummaging through editor histories file by file, while `mkdir look && tar -C look` sat unused at the bottom of every tar tutorial ever written.

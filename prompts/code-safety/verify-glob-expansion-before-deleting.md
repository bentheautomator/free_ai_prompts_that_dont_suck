---
title: Verify Glob Expansion Before Deleting
slug: verify-glob-expansion-before-deleting
category: code-safety
tags: [universal, files, shell]
works_with: all
severity: critical
one_liner: "AI deleting with wildcards that expand to far more than intended"
---

# Verify Glob Expansion Before Deleting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running a wildcard delete without knowing what the wildcard actually expands to.

**[Copy-paste ready version](../../install/verify-glob-expansion-before-deleting.md)** — just the instruction block, no explanation.

## The Problem

`rm fixtures/ *.json` — one accidental space, and instead of deleting JSON files inside `fixtures/`, the shell deletes the `fixtures` directory's contents *and* every JSON file in the current directory. Or `rm *.log` runs in a directory where `*.log` matches nothing in the AI's mental model but `debug.log.gz` and a directory named `archive.log/` exist in reality. Or the glob is `temp_*` and someone's `temp_final_DO_NOT_DELETE/` matches beautifully.

The shell expands globs; the AI imagines them. Those two operations frequently disagree — about hidden files, about directories matching file patterns, about a stray space splitting one argument into two, about case sensitivity, about whether `*` includes that one file someone named weirdly. The AI writes the pattern against the directory it pictures, not the directory that exists, and `rm` doesn't grade on intent.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Glob Expansion Before Deleting

NEVER delete using a wildcard without first seeing exactly what it expands to. The shell expands globs against the real directory; you wrote yours against an imagined one.

The core problem: glob patterns routinely match more than intended — hidden surprises, directories matching file patterns, a stray space turning one argument into two — and `rm` executes the expansion, not the intent.

- Before any wildcard delete, expand the pattern visibly: `ls -d <pattern>` or `echo <pattern>`, and read the full list. Then delete that reviewed list.
- Quote and inspect arguments carefully. `rm fixtures/*.json` and `rm fixtures/ *.json` differ by one space and one catastrophe.
- List the directory first (`ls -la`) so you know what's actually there, including dotfiles and oddly named entries your pattern might catch.
- Prefer the most specific pattern that works: `rm ./build/*.o` over `rm *.o` over `rm *`. Anchor with explicit directories (`./`) rather than relying on cwd.
- Never combine an unverified glob with `-r` or `-f`. Recursion plus a wrong match is how single-file mistakes become directory-tree mistakes.
- If the expansion includes anything you didn't predict — even one entry — stop and resolve the surprise before deleting anything.

**Red flags that you're about to violate this:**
- "The pattern obviously only matches the build outputs..."
- "There's nothing else in that directory anyway..."
- "I'll add -f so it doesn't complain about non-matches..."
- "Expanding it first is an extra step for a one-liner..."
- "Wildcards are standard practice, this is fine..."

---

## Why It Works

1. **It separates expansion from execution.** `echo` or `ls` of the pattern is the same computation `rm` would do, minus the deleting. Requiring it first means the AI sees reality before acting on imagination.

2. **It names the one-space failure class.** Argument-splitting accidents (`fixtures/ *.json`) are nearly invisible in generated commands. Calling them out makes the AI re-read its own command character by character.

3. **It makes surprise a halt condition.** "One unpredicted entry = stop" removes the discretion to shrug off small mismatches — which is how the weirdly named important file dies.

## Origin

An assistant cleaning up exports ran `rm -rf output_*` in a workspace where the pattern matched `output_v2/` (build artifacts, intended) and `output_final_keep/` (a hand-curated set of results a researcher had renamed "to be safe"). An `ls -d output_*` first would have shown both names side by side, and no human or model would have approved the second one.

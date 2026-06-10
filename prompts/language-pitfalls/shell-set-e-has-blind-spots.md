---
title: Shell set -e Has Blind Spots
slug: shell-set-e-has-blind-spots
category: language-pitfalls
tags: [universal, shell]
works_with: all
severity: high
one_liner: "Stops scripts from trusting set -e in the places it silently does nothing"
---

# Shell set -e Has Blind Spots

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents scripts that rely on `set -e` from sailing past failures in command substitutions, conditionals, and `local` assignments.

**[Copy-paste ready version](../../install/shell-set-e-has-blind-spots.md)** — just the instruction block, no explanation.

## The Problem

`set -e` ("exit on error") is treated by generated scripts as a force field: add it to line 2, then write twenty commands with no error handling. But errexit has documented holes. It does not fire for commands in an `if`/`while`/`until` condition, on the left of `&&`/`||`, inside `!`, or — the killer — for failures inside `$(command substitution)` used in an assignment that's part of `local`, `export`, or `declare`. `local version=$(git describe)` succeeds with an empty `version` even when `git describe` fails, because `local` itself returned 0 and ate the exit status. Functions called from a condition (`if deploy; then`) run their *entire body* with errexit suspended.

The result is the worst combination: a script that advertises strictness while specific failure paths fall through silently, with empty variables flowing into commands that were "guaranteed" to run only on success.

Assistants produce this because `set -e` at the top is the cargo-cult marker of a "robust" script in training data, and the blind spots are exactly the constructs models love to generate — `local x=$(...)` appears in nearly every generated bash function.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Shell set -e Has Blind Spots

NEVER treat `set -e` as complete error handling in shell scripts. Errexit is silently suspended in several constructs; handle those failure paths explicitly.

- Start scripts with `set -euo pipefail` (bash), but treat it as a backstop, not the strategy.
- `local var=$(cmd)` discards cmd's exit status — `local` returns 0. Split it: `local var` on one line, `var=$(cmd)` on the next; now the assignment's status is cmd's status and errexit can see it. Same for `export` and `declare`.
- Inside `if cond`, `while cond`, `! cmd`, and the left side of `&&`/`||`, failures do not trigger errexit — by design. If a function is called in a condition, its whole body runs with errexit off; keep such functions trivial or check statuses manually inside them.
- `set -u`: expanding an unset variable is fatal — this catches typos and missing environment that `set -e` never would. Use `"${VAR:?message}"` to demand required variables with a useful error.
- After a command whose failure needs cleanup or a specific message, check explicitly: `if ! cmd; then echo "..." >&2; exit 1; fi`. Explicit beats implicit for anything destructive.
- `cmd || true` disables checking for that command — only write it when failure is genuinely acceptable, with a comment saying why.
- Don't rely on errexit semantics being portable: `sh`/dash/old bash differ. Explicit checks are portable.

**Red flags that you're about to violate this:**

- "The script has `set -e`, so any failure stops it."
- "`local output=$(build)` — if build fails, we exit." (You don't.)
- "I'll wrap this in a function and call it from the if-condition." (Errexit is now off inside it.)
- "Adding explicit error checks is redundant with strict mode."
- "`|| true` here just keeps the script tidy."

---

## Why It Works

1. **It demotes `set -e` from strategy to backstop.** The failure isn't ignorance of strict mode — it's overconfidence in it; reframing what the flag is *for* changes what the model writes after line 2.
2. **It targets the highest-frequency hole.** `local var=$(cmd)` is in practically every generated function; giving the two-line split as the fixed idiom patches the spot where the bug actually ships.
3. **It explains the condition-context suspension.** "Functions called from `if` run with errexit off" is the non-obvious semantic that makes otherwise-correct refactors dangerous; stating it prevents the refactor-into-a-condition trap.
4. **It prices the escape hatches.** `|| true` with a mandatory comment keeps legitimate uses while removing the reflexive ones.

## Origin

A release script used `local tag=$(git describe --exact-match)` under `set -e` to refuse releases from untagged commits. On an untagged commit, git failed, `local` swallowed the status, `tag` was empty, and the script published an artifact named `app-.tar.gz` to the stable channel. Downstream installers sorted it as the newest version. The fix was four characters of line break between `local tag` and the assignment.

---
title: Shell Quote Every Variable
slug: shell-quote-every-variable
category: language-pitfalls
tags: [universal, shell]
works_with: all
severity: critical
one_liner: "Stops unquoted shell variables from word-splitting and glob-expanding"
---

# Shell Quote Every Variable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `rm $dir/tmp` becoming `rm` of two unrelated paths the moment a filename contains a space — or a `*`.

**[Copy-paste ready version](../../install/shell-quote-every-variable.md)** — just the instruction block, no explanation.

## The Problem

In shell, an unquoted `$var` is not "the value of var." It is "the value of var, split into words on whitespace, with each word then expanded as a glob pattern." `rm -rf $BUILD_DIR/cache` with `BUILD_DIR="/srv/my app"` runs `rm -rf /srv/my app/cache` — three arguments, one of which is `/srv/my`. A variable containing `*` expands against whatever directory you happen to be in. An empty variable vanishes entirely, so `[ $status = ok ]` becomes `[ = ok ]` and errors out, and `rm -rf $PREFIX/` becomes `rm -rf /`.

These scripts pass every test, because test environments have civilized paths without spaces. Production has "My Documents," mounted volumes named by humans, and filenames created by `touch "$(date)"`. The failure is data loss or a destroyed directory tree, triggered by data, not by code changes.

Assistants emit unquoted variables constantly: the majority of shell snippets in training data are unquoted because they were written for blog posts where `$f` is always `file1.txt`. The model also drops quotes when "simplifying" working scripts, which is how a previously safe script gets a delayed-action bug in review.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Shell Quote Every Variable

ALWAYS double-quote every variable and command substitution in shell: `"$var"`, `"$(cmd)"`, `"$@"`, `"${arr[@]}"`. Unquoted expansions undergo word splitting and glob expansion, so any value containing spaces, tabs, newlines, or `* ? [` becomes multiple arguments or a wildcard match.

- Wrong: `rm -rf $TMPDIR/build` — with a space in `TMPDIR` this deletes two paths, neither of them the right one. Right: `rm -rf "${TMPDIR}/build"`.
- Wrong: `[ $x = "ok" ]` — errors or misbehaves when `x` is empty or multi-word. Right: `[ "$x" = "ok" ]`, or use `[[ ]]` in bash (still quote for habit and copy-paste safety).
- Pass arguments through with `"$@"` (each argument preserved), never bare `$@` or `"$*"` (which joins them into one).
- Loop over command output with arrays or `while IFS= read -r line`, not `for f in $(ls)` — that splits on every space in every filename and glob-expands the pieces.
- Quote inside `${}` defaults too: `"${name:-default}"`.
- The few legitimate unquoted uses (deliberate globbing like `for f in *.log`, or intentional splitting of a flags variable) must be commented as intentional; better, use arrays for flag lists: `args=(-v --color); cmd "${args[@]}"`.
- Arithmetic contexts `$(( ))` and assignments `x=$y` are safe unquoted, but quoting them is harmless — when in doubt, quote.

**Red flags that you're about to violate this:**

- "This variable is a path I control, it'll never have spaces."
- "Quoting everything makes the script noisy; I'll quote where it matters."
- "It's a quick CI script, not production code." (CI deletes directories for a living.)
- "The original script didn't quote it and it works."
- "`$@` and `\"$@\"` are basically the same thing."
- "I'm just cleaning up the quoting style." (Removing quotes is never cleanup.)

---

## Why It Works

1. **It makes quoting the unconditional default.** Any rule with judgment ("quote where needed") fails, because the model judges that spaces "can't happen here" — the same judgment the human who lost `/srv` made.
2. **It explains the mechanism in one clause.** Split-then-glob is the actual semantic; once stated, `[ $x = ok ]` failing on empty input stops being mysterious and starts being predictable.
3. **It covers the lookalikes.** `$@` vs `"$@"` and `for f in $(ls)` are where quoting knowledge usually runs out; enumerating them removes the gap between "knows the rule" and "applies the rule."
4. **It requires a comment to opt out.** Deliberate unquoted expansion exists, but making it cost a comment means the model can't reach it by laziness, only by intent.

## Origin

A cleanup script ran nightly with `rm -rf $APP_HOME/releases/old`. A deploy-tooling change left `APP_HOME` unset in the cron environment, the expansion vanished, and the command became `rm -rf /releases/old` — harmless by pure luck of that path not existing. The next variant, on a host where the variable held a path with a space, deleted a sibling directory that did exist. Recovery came from backups; the postmortem's first action item was a shellcheck gate, whose top warning is precisely this.

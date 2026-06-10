---
title: Guard Empty Variables in Destructive Commands
slug: guard-empty-variables-in-destructive-commands
category: code-safety
tags: [universal, shell, automation]
works_with: all
severity: critical
one_liner: "AI writing rm -rf $VAR/ where an unset variable means deleting from root"
---

# Guard Empty Variables in Destructive Commands

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the classic shell catastrophe: a destructive command whose path variable silently expanded to nothing.

**[Copy-paste ready version](../../install/guard-empty-variables-in-destructive-commands.md)** — just the instruction block, no explanation.

## The Problem

`rm -rf "$BUILD_DIR/"` is a perfectly safe-looking line, and it deletes from `/` when `BUILD_DIR` is unset — because `"$BUILD_DIR/"` expands to `"/"`. The variable can be unset for the dullest reasons: a typo in the name (`$BUILDDIR` vs `$BUILD_DIR`), a config file that didn't load, an env var that exists in CI but not locally, a function called before its setup ran, `set -u` missing so the shell substitutes empty and carries on. This exact pattern has destroyed enough systems that it's shell-scripting folklore — and AI assistants regenerate it constantly, because the happy path works and the variable is *obviously* going to be set.

Variations abound: `rm -rf $OUTPUT/*` (empty var: `rm -rf /*`), `rm -rf ~/$PROJECT` (empty: the entire home directory), `chown -R user "$APP_HOME"`, `find $TARGET -delete`. The common shape is a destructive command whose target is assembled from variables at runtime, with no check between "assemble" and "destroy." The AI writes for the case where everything resolved; the disaster lives in the case where something didn't.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Guard Empty Variables in Destructive Commands

NEVER write or run a destructive command whose target is built from a variable without guarding the empty case. `rm -rf "$BUILD_DIR/"` deletes from the filesystem root when the variable is unset — the quotes don't save you, and `set -u` isn't always there.

The core problem: variables are unset for boring reasons (typos, unloaded config, env differences between machines), the shell substitutes empty and proceeds, and an empty path component turns a scoped delete into `rm -rf /` or `rm -rf ~`.

- In scripts: start with `set -u` (or `set -euo pipefail`) so unset variables are fatal instead of empty. This is non-negotiable in any script containing `rm`, `mv` to overwrite, `chown`, or `find -delete`.
- Use the no-fallback expansion for destructive targets: `rm -rf "${BUILD_DIR:?BUILD_DIR is not set}/"` — the `:?` aborts with a message instead of expanding to nothing.
- Validate before destroying, explicitly: check the variable is non-empty AND the path exists AND it's the kind of path you expect (`[[ -n "$BUILD_DIR" && -d "$BUILD_DIR" && "$BUILD_DIR" == */build* ]]`). Refuse `/`, `$HOME`, and suspiciously short paths outright.
- Echo the resolved target before the destructive line acts on it: `echo "Deleting: '$TARGET'"` makes an empty expansion visible as `Deleting: ''` — in logs and in your own pre-run review.
- The same trap exists outside bash: Python `shutil.rmtree(os.environ.get("BUILD_DIR", ""))`, Makefiles (`rm -rf $(OUTDIR)/`), CI YAML interpolation. Guard them all: empty-check before any rmtree/recursive delete on a constructed path.
- When *running* an existing script that takes path variables, read it for this pattern first and confirm the variables are set in the current environment.

**Red flags that you're about to violate this:**
- "The variable is set right there at the top of the script..."
- "This script always runs through the Makefile, so the env is guaranteed..."
- "Quoting the variable makes it safe..."
- "Adding :? checks everywhere is noise..."
- "It worked on my run, the variable resolves fine..."

---

## Why It Works

1. **It corrects a false safety belief.** AI assistants (and humans) believe quoting protects variable expansions. Stating plainly that `"$VAR/"` becomes `"/"` removes the specific misconception that makes the pattern feel safe.

2. **It provides one-token fixes.** `${VAR:?}` and `set -u` cost almost nothing to include, so the rule competes on equal convenience terms with the dangerous version — there's no efficiency reason left to skip them.

3. **It makes the empty expansion visible.** Echoing the resolved target turns the failure from a silent substitution into a printed `''` that reads as wrong to any reviewer, including the AI checking its own output.

## Origin

A deploy helper script written by an assistant included `rm -rf "$RELEASE_DIR/current/"`. On one machine, the config file exporting `RELEASE_DIR` had a different name, the variable expanded empty, and the script ran `rm -rf /current/` — harmlessly, by pure luck, because no such directory existed. The reviewed fix added `:?` guards; the near-miss was only noticed because someone read the logs and saw a delete aimed at the filesystem root.

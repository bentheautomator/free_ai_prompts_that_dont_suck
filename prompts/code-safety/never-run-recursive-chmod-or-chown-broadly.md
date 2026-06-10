---
title: Never Run Recursive Chmod or Chown Broadly
slug: never-run-recursive-chmod-or-chown-broadly
category: code-safety
tags: [universal, shell, files]
works_with: all
severity: critical
one_liner: "AI fixing a permission error with chmod -R 777 or chown -R on huge trees"
---

# Never Run Recursive Chmod or Chown Broadly

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from carpet-bombing permissions across a directory tree to fix a one-file problem.

**[Copy-paste ready version](../../install/never-run-recursive-chmod-or-chown-broadly.md)** — just the instruction block, no explanation.

## The Problem

A script can't write one file, and the AI responds with `chmod -R 777 .` — or worse, `sudo chown -R $USER /usr/local` because a package manager complained. Recursive permission changes are uniquely nasty because they're *irreversible by default*: the original modes and owners weren't uniform, so there's no single command that puts them back. The tree held a mix of 644s, 600s, executables, setuid bits, and files owned by service accounts. After `-R`, it holds one value, and the diversity that made things work is gone.

The fallout arrives in waves. SSH refuses keys with loose permissions. Services won't start because their config is suddenly world-writable. Cron jobs silently stop. Package managers find their own directories owned by the wrong user and corrupt their state. AI assistants reach for the recursive hammer because permission errors are opaque and `777` makes any single error disappear — it just makes it disappear by removing the security model rather than by fixing the actual one-file, one-bit problem.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Run Recursive Chmod or Chown Broadly

NEVER fix a permission error with a recursive chmod/chown across a directory tree, and never use 777 at all. Recursive permission changes are irreversible — the tree held many different modes and owners, and `-R` flattens them to one with no way back.

The core problem: a permission error names one file and one missing bit, but the recursive fix rewrites thousands of files' security metadata, breaking SSH, services, package managers, and setuid binaries in ways that surface for weeks.

- Diagnose first: which exact file, which operation, which user? `ls -l` the file and its parent. Fix that file: `chmod u+w path/to/file`, not `chmod -R 777 .`
- Never apply `chmod 777` to anything. If "everyone can do everything" looks like the fix, the actual problem is which *user* is acting — solve that instead.
- Never run `chown -R` on system paths (`/usr`, `/etc`, `/var`, `/opt`, `$HOME` itself) to appease a tool. Tools that suggest it (or errors that seem to demand it) are better served by user-level installs, groups, or fixing the one offending path.
- If a recursive change over a project subtree is genuinely warranted, record the current state first so it's reversible: `getfacl -R dir > perms-backup.txt` (restorable with `setfacl --restore`), and scope the command with `find` to target only the relevant type: `find dir -type f -name '*.sh' -exec chmod u+x {} +`.
- Anything recursive touching more than a handful of files, or anything with `sudo`: state the exact command and scope, and get confirmation.

**Red flags that you're about to violate this:**
- "Permission denied — I'll just open up the whole directory..."
- "777 for now, we can tighten it later..."
- "chown -R will make all these errors stop at once..."
- "It's faster than figuring out which file actually needs it..."
- "The installer says it can't write, so I'll take ownership of the parent..."

---

## Why It Works

1. **It exposes the irreversibility.** The AI treats permissions as a setting you can set back. Stating that the original modes were heterogeneous — and thus unrecoverable after flattening — reframes `-R` as destructive, not configurational.

2. **It shrinks the unit of repair to match the unit of failure.** The error names one file; the rule demands the fix name one file too. That symmetry blocks the carpet-bomb response.

3. **It provides the reversible escape valve.** `getfacl` backup plus `find`-scoped changes covers the legitimate cases, so the rule can be absolute about `777` and blind `-R` without ever blocking real work.

## Origin

Hitting an EACCES during a dependency install, an assistant ran `sudo chown -R` of the user over a system prefix directory. The install succeeded. Over the following days: a daemon stopped starting (config no longer owned by its service account), another developer's tooling broke on the shared machine, and SSH key auth failed for a deploy user whose home had been swept up in the change. Restoring took a re-image, because nobody knew what the original ownership map had been — which is exactly the point.

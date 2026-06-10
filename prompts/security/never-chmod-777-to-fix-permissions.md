---
title: Never chmod 777 to Fix a Permission Error
slug: never-chmod-777-to-fix-permissions
category: security
tags: [universal, security]
works_with: all
severity: high
one_liner: "AI making files world-writable because something got Permission denied"
---

# Never chmod 777 to Fix a Permission Error

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from resolving EACCES by making files and directories world-writable.

**[Copy-paste ready version](../../install/never-chmod-777-to-fix-permissions.md)** — just the instruction block, no explanation.

## The Problem

`EACCES: permission denied`. The AI knows a command that always makes this error stop: `chmod -R 777 .`, or its enterprise variants — `chmod 777 /var/www/uploads`, `sudo chown -R $(whoami) /usr/lib/node_modules`, running the container as root, `umask 000` in an init script. World-writable means the error cannot recur, which makes 777 the most reliable-looking fix in the toolbox. It also means every account and process on the machine can modify your application's code, plant files in your upload directory, rewrite your cron-adjacent scripts, and tamper with anything the recursive flag touched. On shared hosts and multi-service boxes, that's privilege escalation infrastructure with your name on it; for SSH specifically, it's also self-defeating, since sshd refuses keys with loose permissions.

The pattern is pure path-of-least-resistance: a permission error is a question ("which user should own this, and what access does it actually need?") and 777 is the answer that requires not finding out. AI assistants compound it with `-R` from the project root, with `sudo` to make doubly sure, and by writing `0o777` into application code (`os.makedirs(path, mode=0o777)`, `fs.chmodSync(file, 0o777)`) so the misconfiguration regenerates itself on every deploy. Secrets files get caught in the recursive blast, turning "the app can read its key" into "everyone can read its key."

The real fix is almost always identifying the user the process runs as and granting that user, alone, the minimal access.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never chmod 777 to Fix a Permission Error

NEVER resolve a permission error with mode 777/666, recursive ownership grabs, or running as root. Find out which user needs access and grant that user the minimum.

World-writable means every process and account on the system can modify the file. That's not a fix; it's an invitation with the error message removed.

- Do not run `chmod 777`/`chmod -R 777`, `chmod 666` on anything executable or sensitive, `umask 000`, or write `mode=0o777` into code that creates files/directories.
- Diagnose first: `ls -l` the path, then find which user the failing process runs as (`ps aux`, the service unit), then `chown appuser:appgroup` the specific directory or add group access (`chgrp` plus `g+rw`). Web servers have a designated user (`www-data`, `nginx`); grant that user, not the world.
- Sane defaults: 755 directories / 644 files for code and static assets; 700/600 for anything containing secrets. Private keys and `.env` files: 600, always. SSH will reject worse, and so should you.
- Never `sudo chown -R` system paths (`/usr`, `/etc`, package-manager territory) to fix a tooling error; fix the tool's prefix or use a user-writable location instead.
- Containers: don't solve volume-permission mismatches with 777 on the host mount or by switching the image to run as root; align the UID/GID (`user:` in compose, `runAsUser`, or chown in the entrypoint for the specific path).
- If a permission error has you genuinely stuck, present the diagnosis (who owns it, who needs it) and the minimal-grant options to the user instead of escalating to "everyone."

**Red flags that you're about to violate this:**
- "777 just while we get it working, then we'll set proper permissions..."
- "It's a single-user VM, there are no other users to worry about..."
- "The recursive flag saves doing this directory by directory..."
- "Running the container as root sidesteps the whole volume mess..."
- "I don't know which user nginx runs as, but 777 covers all cases..."
- "It's only the uploads folder, nothing sensitive lives there..."

---

## Why It Works

1. **It converts the error into the right question.** 777 is what "I don't know which user needs access" looks like as a command; the diagnose-first steps make answering the question as fast as avoiding it.

2. **It supplies the numbers.** Models reliably remember 777 and unreliably remember 755/644/600; putting the sane defaults in context replaces the bad reflex with an equally concrete good one.

3. **It blocks the in-code variant.** A shell `chmod` is at least visible to ops; `mode=0o777` in application code re-creates the hole on every deploy and hides from audits that only inspect the filesystem. Few rules catch it; this one names it.

4. **It addresses containers separately.** Volume UID mismatch is the modern trigger for the whole pattern, and the AI will run images as root forever unless the UID-alignment fix is in its vocabulary.

## Origin

A deploy script failed writing to a cache directory, and the assistant fixed it with `chmod -R 777` from the application root — which included `config/`, where the database credentials lived. The host also ran a neighboring team's cron jobs under a different account; nobody malicious ever touched anything, but the compliance scan that found world-readable credentials triggered a mandatory rotation, an audit of every file the flag had touched, and a quarter of remediation work. The cache directory had needed one `chown` to one user.

---
title: Never Hotfix Files on Production Servers
slug: never-hotfix-files-on-production-servers
category: code-safety
tags: [universal, production]
works_with: all
severity: critical
one_liner: "AI editing or deleting files directly on a live server over SSH"
---

# Never Hotfix Files on Production Servers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating a live production server like a local working directory.

**[Copy-paste ready version](../../install/never-hotfix-files-on-production-servers.md)** — just the instruction block, no explanation.

## The Problem

There's a bug in production, an SSH session is available, and the file with the bug is right there at `/srv/app/handlers.py`. The AI edits it in place. Maybe the fix is even correct. Now production runs code that exists nowhere else — not in the repo, not in the deploy pipeline, not on anyone's machine. The next deploy silently erases the fix and the bug returns, except now it "was already fixed," which makes the re-investigation twice as confusing. That's the *good* outcome. The bad outcome is a typo in the live edit taking the service down, with no deploy log entry explaining what changed, because nothing was deployed.

AI assistants do this because proximity reads as permission: the file is accessible, editing files is the job, and the path of least resistance runs straight through the SSH session. Live servers also tempt with cleanup — old releases, stale logs, "unused" directories — where a wrong guess about what the running process needs means an outage. Production machines are an output of the deploy process, not a workspace. Anything changed by hand there is unrecorded, unreviewed, unreproducible, and scheduled for silent destruction by the next deploy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Hotfix Files on Production Servers

NEVER edit, delete, or move files directly on a production or live server. Production machines are outputs of the deploy process, not working directories — hand changes there are unrecorded, unreviewed, and will be silently destroyed or contradicted by the next deploy.

The core problem: an SSH session makes live files feel editable like local ones, but a live edit either diverges prod from the repo (the fix vanishes on next deploy) or breaks the running service with no deploy log to explain what changed.

- Fixes go through the pipeline: change in the repo, review if applicable, deploy. If a true emergency demands a live edit, that's the user's call to make explicitly — not yours to default into.
- If the user does authorize a live edit: copy the original aside first (`cp app.py app.py.pre-hotfix`), make the minimal change, state exactly what you changed, and immediately ensure the same change lands in the repo so the next deploy doesn't revert it.
- Never delete anything on a live server to free space or tidy up — old releases may be rollback targets, "stale" sockets and PID files may belong to running processes, logs may be mid-rotation or legally retained. Report what could be freed and let the user act.
- Never restart, reload, or send signals to production services as a side effect of investigating. Observation commands only, unless explicitly asked.
- Treat anything reachable over SSH whose hostname, prompt, or path suggests live traffic (prod, www, app-1, /srv, /var/www) as production until proven otherwise.

**Red flags that you're about to violate this:**
- "The file's right here — faster to fix it in place than redeploy..."
- "It's a one-character change, deploying for that is silly..."
- "I'll clean up these old release directories while I'm in here..."
- "I'll just bounce the service to pick up the change..."
- "We can backport it to the repo afterwards..."

---

## Why It Works

1. **It reframes the server as build output.** "Production is an output of the deploy process" gives the AI a model in which hand-editing prod is as incoherent as hand-editing a compiled binary — the change belongs upstream.

2. **It names the divergence failure, not just the outage.** The subtle cost (fix erased by next deploy, repo and prod disagreeing) is the one the AI doesn't foresee; stating it kills "it's just a small fix" reasoning.

3. **It scripts the emergency path.** Real hotfixes happen. Providing the exact protocol — backup, minimal change, announce, backport immediately — means the rule bends under pressure instead of breaking.

## Origin

An assistant with SSH access fixed a null-check bug by editing the handler directly on the production box. It worked. Eleven days later a routine deploy shipped the repo's version — without the fix — and the crash returned at 2 a.m. The on-call engineer spent three hours proving the bug "couldn't be happening" because the code on their screen already handled it. The code on their screen was not the code that had been running.

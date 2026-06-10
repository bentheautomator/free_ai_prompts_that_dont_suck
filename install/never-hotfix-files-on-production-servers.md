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

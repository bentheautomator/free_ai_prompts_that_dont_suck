### Never Prune Docker Without Scoping It

NEVER run machine-wide Docker prune commands to fix a single project's problem. `docker system prune -a --volumes` acts on every project on the host, and the `--volumes` flag deletes data — any volume not attached to a *currently running* container, including the database volumes of containers that merely happen to be stopped.

The core problem: prune commands are global, but your problem is local. A stopped dev database's volume counts as "dangling" and gets destroyed.

- Scope to the project: `docker compose down` (without `-v`!) for this project's containers, `docker rmi <specific image>`, `docker builder prune --filter` for build cache. Fix the thing that's broken, not the daemon's entire state.
- NEVER include `--volumes` in a prune without explicitly listing which volumes will die: `docker volume ls -f dangling=true` first, and identify each one. Volume names like `myapp_pgdata` are databases. Treat them like databases.
- Before any `-a` prune, acknowledge the rebuild cost: every cached image on the machine, re-pulled and rebuilt across all projects. State it and get approval.
- `docker compose down -v` deletes this project's volumes — its local database included. Only with explicit user intent to lose that data.
- Disk-space pressure: diagnose with `docker system df` and present what's using space and what each option deletes, rather than defaulting to the biggest hammer.
- Stopped containers are not garbage. People stop containers to come back to them. Removing them discards their writable layer and their volume attachments.

**Red flags that you're about to violate this:**
- "A full prune will clear out whatever's causing this..."
- "Dangling volumes are by definition unused..."
- "docker compose down -v for a really clean restart..."
- "Disk is full — prune -a is the standard fix..."
- "Everything important is in images, and images rebuild..."

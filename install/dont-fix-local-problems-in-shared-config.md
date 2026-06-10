### Don't Fix Local Problems in Shared Config

NEVER modify committed, shared configuration to solve a problem specific to the current machine. Shared config encodes the team's agreement; a local conflict is your problem to absorb locally, not theirs to inherit.

A port collision, a missing local service, or a path that doesn't exist on this machine is a local condition. Fixing it in a committed file exports your environment's quirks to every other environment.

- First ask: would this change be wrong on a teammate's machine or in CI? If yes, it doesn't belong in a committed file.
- Use the project's local-override mechanism instead: `.env.local`, `docker-compose.override.yml`, `config/local.*`, `settings_local.py`, direnv — whatever the project already supports. These exist precisely for this.
- If no override mechanism exists, propose adding one (gitignored) rather than editing the shared file.
- Environment variables that the shared config already reads (`PORT=5433 make dev`) are a fine zero-footprint fix.
- If you genuinely believe the shared default is wrong for everyone, say so explicitly and make that case in the change description — as a deliberate team-wide decision, not a drive-by fix.
- This applies to tool config too: editor settings, linter paths, test runner ports, registry mirrors.

**Red flags that you're about to violate this:**
- "The port was already in use, so I changed it in the compose file."
- "It works now" (on this machine, which is the only one I checked).
- "Everyone probably has the same conflict anyway."
- "It's a tiny config change, easy to revert if anyone complains."
- "I'll mention it in the commit message so people can adjust."

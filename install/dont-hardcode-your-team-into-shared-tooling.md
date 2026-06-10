### Don't Hardcode Your Team Into Shared Tooling

NEVER bake one team's specifics — paths, service names, regions, defaults, assumptions about project shape — into tooling other teams use. Shared tools must stay generic; team-specific needs go in parameters and config, not in the tool's body.

Every hardcoded special case makes the tool a little more about one team and a little less usable by the rest, and special cases breed special cases.

- When changing a shared script, generator, CI template, or CLI, ask: would this change make sense to a team that isn't mine? If not, it doesn't belong in the shared layer.
- Express team-specific needs through existing extension points: arguments, config files, env vars, per-project overrides. If no extension point exists, add a generic one — don't add an `if (service === "payments")`.
- Don't change shared defaults to your team's values. A default change is a behavior change for every team that relied on the old one.
- Don't encode assumptions about project layout ("every service has `Dockerfile` at the root") that merely happen to be true for the requesting team. Check what shapes actually exist, or fail gracefully with a clear message.
- If the requesting team's need genuinely can't be met generically, say so and propose a team-local wrapper around the shared tool instead of a team-shaped patch inside it.

**Red flags that you're about to violate this:**
- "I'll hardcode the path for now; it's the only service using this anyway."
- "A special case for our service is simpler than adding a parameter."
- "Our region is the sensible default."
- "Every service surely has this file." (You checked one.)
- "I'll generalize it later if another team complains."

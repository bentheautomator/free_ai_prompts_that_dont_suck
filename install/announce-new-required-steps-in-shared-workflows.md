### Announce New Required Steps in Shared Workflows

NEVER add a required step to a shared workflow silently. Anything that changes what every developer must do — hooks, CI gates, codegen steps, env vars, setup commands — is an announcement plus a change, not just a change.

Each teammate who discovers the new requirement by hitting it pays the confusion cost separately. You impose the step once; they trip over it N times.

- If your change adds an obligation (a hook that can block, a check that can fail, a step that must run, a variable that must be set), say so prominently in your summary: what the new step is, who hits it, and what they must do.
- Update the docs where developers would look: README setup section, CONTRIBUTING, onboarding docs, `.env.example`. A requirement documented nowhere is a trap, not a process.
- Make failure self-explanatory. A hook or check you add must say what it wants and how to satisfy it in its own error output — not assume tribal knowledge that doesn't exist yet.
- Provide the migration path for existing checkouts: the exact command to run, the default that keeps old setups working, or both.
- Prefer non-blocking introductions where possible: warn before you enforce, default before you require.
- Ask whether the team actually wants this obligation. If the new step is your initiative rather than the task's requirement, present it as a proposal, not a fait accompli.

**Red flags that you're about to violate this:**
- "The hook explains itself when it fires; that's documentation enough."
- "Everyone will figure out the new env var from the error."
- "It's a clear improvement; announcing it is bureaucracy."
- "The setup change only affects new checkouts." (It never does.)
- "I'll add the check now and document it later."

### Scope CI Token Permissions Minimally

NEVER grant a CI workflow broad permissions to fix a scope error. Resolve `Resource not accessible` by adding the single missing scope to the single job that needs it — not `permissions: write-all`, not a PAT with every box checked, not an org-wide deploy key.

The workflow token's scopes define the blast radius of every compromise in your pipeline — bad dependency, hijacked action, injected input. Minimal scopes make those incidents small; `write-all` makes them total.

- Set a restrictive default at the workflow level — `permissions: { contents: read }` (or even `permissions: {}`) — and grant additions per job: the release job gets `contents: write`, the commenter gets `pull-requests: write`, and neither gets the other's.
- When a permission error appears, identify which API call failed and which scope it needs (the platform docs map calls to scopes), then add exactly that. If you can't determine the scope, say so — don't resolve uncertainty by granting everything.
- Don't substitute a personal access token to dodge `GITHUB_TOKEN` limits without flagging it: PATs outlive runs, span repos, and escape the per-job permission model. If one is genuinely required (cross-repo triggers), request minimum scopes and say why in the PR.
- For cloud access from CI, prefer OIDC federation with a role scoped to the specific repo and branch over long-lived static keys in secrets.
- Never widen permissions in the same PR as unrelated work. A scope grant is a security decision; make it a visible, one-line, explained change.
- When touching an existing workflow that has `write-all` or no permissions block (older defaults are broad), flag it and propose the minimal set based on what the jobs actually do.

**Red flags that you're about to violate this:**

- "write-all fixes it for sure; narrower might mean another failed run."
- "I'll grant everything now and tighten it once the workflow is stable."
- "It's our own pipeline; the token can't fall into the wrong hands."
- "The example in the action's README uses write-all."
- "A PAT just works everywhere; the GITHUB_TOKEN restrictions are a hassle."

### Never Run Untrusted PRs with Secrets

NEVER execute untrusted PR code in a workflow context that has secrets or write permissions. Specifically: never combine `pull_request_target` (or any privileged trigger) with a checkout of the PR's head ref followed by anything that executes PR-controlled code — builds, installs, tests, scripts, or linters with plugin loading.

The platform strips secrets from fork PRs on purpose. Every workaround that restores secrets to attacker-supplied code is the vulnerability, regardless of how standard the YAML looks.

- Default to plain `pull_request` for anything that builds or tests PR code. If a step inside it needs a secret, that step is in the wrong workflow.
- Use `pull_request_target` only for jobs that operate on PR *metadata* without checking out or executing PR code: labeling, commenting, assigning. If the job contains a checkout of `head.sha` or `head.ref`, stop.
- When a result from untrusted code genuinely needs privileges (posting coverage, publishing previews), split it: an unprivileged `pull_request` workflow produces an artifact; a separate `workflow_run` workflow with secrets consumes the artifact as *data only* — validating it, never executing scripts or binaries from it.
- Never interpolate attacker-controlled fields (`pull_request.title`, `head_ref`, issue bodies, commit messages) into `run:` scripts. Pass them through `env:` and reference the environment variable, which the shell treats as data.
- Treat "secrets are not available to fork PRs" as a design constraint to architect around, not an error to make go away. If the user asks for the unsafe pattern, explain the exfiltration path before doing anything.

**Red flags that you're about to violate this:**

- "Switching to pull_request_target fixes the missing-secrets error."
- "Our repo is small; nobody's going to attack our CI."
- "The token only has a few scopes, so the exposure is limited."
- "I saw this exact trigger-plus-checkout pattern in a popular repo."
- "We need coverage upload on fork PRs and this is the only way."
- "It's just echoing the PR title for the log."

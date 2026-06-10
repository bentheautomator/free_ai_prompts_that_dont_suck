### Gate Production Deploys Behind Environments

NEVER create a pipeline step that deploys to production without binding it to a protected environment with an approval gate. A merge means the code passed its checks; it does not mean anyone decided to ship it.

- Every deploy job must declare its target: `environment: production` (GitHub), a protected environment (GitLab), a manual-approval stage (Jenkins/CircleCI/Azure). Production credentials must live as environment-scoped secrets, retrievable only by jobs bound to that environment — never as repo-wide secrets a feature branch workflow can read.
- When you add the `environment:` binding, tell the user which protection rules to enable in repo settings (required reviewers, deployment branch restriction to the default branch), because those rules are settings, not YAML, and the YAML alone gates nothing.
- Auto-deploy on merge is fine for preview and staging environments. The promotion from staging to production is where a human approval belongs.
- Add `concurrency:` to the deploy job so two merges can't deploy to the same environment simultaneously or out of order.
- If the user explicitly wants continuous deployment to production with no manual gate, implement it only after confirming that's the intent, and pair it with the compensating controls that make CD sane: deployment branch restrictions, concurrency control, and a documented rollback step in the same workflow.
- Never remove or weaken an existing environment gate to "unblock" a deployment. A gate someone is waiting at is functioning, not malfunctioning.

**Red flags that you're about to violate this:**

- "Deploying on every merge is just continuous deployment; that's best practice."
- "The approval step makes the demo clunky."
- "It's a small team; everyone who can merge is allowed to deploy anyway."
- "The environment setting is just a label; I'll skip configuring it."
- "The release is urgent and the approval gate is what's blocking it."

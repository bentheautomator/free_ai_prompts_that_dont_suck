### Show the Terraform Plan Before Apply

NEVER run `terraform apply` until a human has seen and approved the plan output in this session. Editing `.tf` files is safe; applying them mutates live infrastructure.

The plan is the only artifact that reveals whether a change is an in-place update or a destroy-and-recreate. If no human reads it, the safety mechanism did not happen.

- After editing Terraform, run `terraform plan` (or `terraform plan -out=tfplan`) and show the summary line plus every resource marked for change.
- Call out destructive symbols explicitly: any `-/+` (replace), `-` (destroy), or `forces replacement` annotation must be quoted to the user verbatim, not paraphrased as "some updates."
- State the blast radius in one sentence: what gets destroyed, what depends on it, whether it holds state (databases, volumes, NAT gateways with reserved IPs).
- Only apply after the user confirms, and prefer applying the saved plan file (`terraform apply tfplan`) so what runs is exactly what was reviewed.
- If the plan shows zero changes or only additions of brand-new resources, say so, then still wait for confirmation before applying.
- A non-empty plan you did not expect is a stop condition, not something to apply and explain afterward.

**Red flags that you're about to violate this:**

- "It's a one-line change, the plan will obviously be an in-place update..."
- "I'll run plan and apply together to save a round trip..."
- "The plan output is long, I'll just summarize it as 'looks fine'..."
- "They asked me to update the instance type, applying is implied..."
- "It's only the staging workspace, plan review is overkill here..."

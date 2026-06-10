### Know Which Database Infra Changes Cause Downtime

NEVER modify a managed database's infrastructure (RDS, Aurora, ElastiCache, Cloud SQL, etc.) without first determining whether the change applies live, requires a reboot/failover, or degrades performance during modification. An "in-place update" in the IaC plan can still be a restart in reality.

- Before changing any attribute, classify it from the service docs: dynamic (live), static/reboot-required, failover-inducing (instance class changes, minor upgrades on Multi-AZ), or long-running (storage type/size — which can also block further modifications for hours).
- Check the `apply_immediately` setting (Terraform defaults it to false; consoles often default the equivalent to "apply now"). State explicitly which behavior the change will get: immediate disruption, or deferred to the maintenance window — and tell the user which window that is.
- For parameter group changes, distinguish dynamic from static parameters. A static parameter change without a planned reboot is a change that hasn't happened; report it as pending, not done.
- Never set `apply_immediately = true` (or reboot the instance) just to make your change observable. Disruption timing is the user's call: present "takes effect now, with a failover of roughly N seconds-to-minutes" versus "takes effect in the Sunday 03:00 window" and let them choose.
- Multi-AZ failover is fast but not free — in-flight transactions break and DNS re-resolution takes time. "It fails over automatically" is a mitigation, not an exemption from announcing it.
- After applying, verify the change is actually in effect (`aws rds describe-db-instances`, parameter `pending-reboot` status) rather than trusting apply output.

**Red flags that you're about to violate this:**

- "The plan shows in-place update, so there's no disruption..."
- "It's just a parameter group tweak..."
- "Multi-AZ means changes are seamless..."
- "I'll set apply_immediately so we can confirm it worked..."
- "Instance resizes only take a minute or two..."

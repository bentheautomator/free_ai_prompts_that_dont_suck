---
title: Know Which Database Infra Changes Cause Downtime
slug: know-which-db-infra-changes-cause-downtime
category: devops
tags: [universal, devops]
works_with: all
severity: critical
one_liner: "Applying RDS-class changes that reboot or fail over the database mid-afternoon"
---

# Know Which Database Infra Changes Cause Downtime

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from applying a "settings change" to a managed database that is secretly a reboot scheduled for right now.

**[Copy-paste ready version](../../install/know-which-db-infra-changes-cause-downtime.md)** — just the instruction block, no explanation.

## The Problem

Managed database services hide a brutal distinction inside innocent-looking attributes: some changes apply live, some require a reboot, and some trigger a full failover or minutes-to-hours of modification with degraded performance. Change `instance_class` on an RDS instance with `apply_immediately = true` (or click the equivalent) and the database restarts now — not at 3 a.m. Sunday, now. Switch a static parameter in a parameter group and nothing happens until the next reboot, which means the AI reports success while the change silently isn't live — or worse, the change rides along with an unrelated reboot weeks later and "nothing we changed" alters database behavior. Storage modifications can lock further changes for six hours. Minor version upgrades fail over; major ones can take the instance offline for the duration.

AI assistants apply these like any other Terraform attribute, because syntactically that's all they are. The plan says `~ instance_class: "db.r5.large" -> "db.r5.xlarge"` — an in-place update! — and nothing in the plan output says "this in-place update is a reboot." The knowledge lives in the service docs, not the diff.

The result is a database restart as a side effect of an afternoon task, taking every connection with it, with no maintenance window, no announcement, and an AI reporting "applied successfully" while the application's error rate goes vertical.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It breaks the plan-symbol illusion.** The AI trusts `~` versus `-/+` as the complete danger taxonomy; stating that in-place updates can be reboots forces a second lookup the diff cannot provide.

2. **It makes "when" a first-class output.** The same change can be a non-event or an outage depending on `apply_immediately` and maintenance windows; requiring the AI to state the timing converts a hidden default into a decision.

3. **It redefines "done" for deferred changes.** Static parameters create a state where the apply succeeded and nothing changed; "report it as pending, not done" prevents the success message that misleads everyone later.

4. **It reserves disruption timing for humans.** The AI's incentive is to verify its own work now; explicitly removing "reboot to confirm" as an option blocks the verification urge from causing the outage.

## Origin

Asked to bump an RDS instance one size up "when convenient," an assistant made the Terraform change and, finding `apply_immediately` already set true from someone's earlier migration, applied at 2 p.m. on the busiest day of the month. The Multi-AZ failover took 90 seconds; the application's connection pool took eleven more minutes to recover because it cached DNS. The change itself was perfect. The timing cost a four-figure number of abandoned checkouts and one very pointed retro about the phrase "when convenient."

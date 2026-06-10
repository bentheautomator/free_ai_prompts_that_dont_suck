---
title: Do the Capacity Math Before Scaling Changes
slug: capacity-math-before-scaling-changes
category: devops
tags: [universal, devops]
works_with: all
severity: high
one_liner: "Resizing or downscaling infrastructure without computing the resulting headroom"
---

# Do the Capacity Math Before Scaling Changes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing replica counts and instance sizes by feel, with no arithmetic connecting the change to actual load.

**[Copy-paste ready version](../../install/capacity-math-before-scaling-changes.md)** — just the instruction block, no explanation.

## The Problem

Scaling changes are numbers, and AI assistants pick them like adjectives. "Reduce costs" becomes replicas 6 → 3 because half sounds thrifty. "Right-size the instances" becomes `m5.2xlarge` → `m5.large` — which reads like one step down and is actually a 75% reduction in CPU and memory. The change applies cleanly, dashboards stay green at current load, and the actual verdict arrives with the next traffic peak: the cluster that ran at 55% CPU across six replicas now needs 110% of three, and there is no 110%.

The missing artifact is two lines of arithmetic: what the fleet's peak utilization is now, and what it becomes after the change. AI assistants skip it for three reasons. Peak data requires looking at monitoring over weeks, not the current instant — and "CPU is at 20% right now" is the most seductive wrong input in capacity planning, because *now* is almost never *peak*. Instance-type names obscure magnitude — families and sizes don't map linearly, and memory-to-CPU ratios shift between families. And N+1 logic is invisible until violated: three replicas at 60% are fine until one dies or a deploy takes one out of rotation, at which point two replicas absorb 90% each, miss their health checks under load, and the cascade starts.

The same blindness applies upward, in money: scaling to 40 replicas of a 16xlarge "to be safe" has a monthly price the AI never multiplied out.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Do the Capacity Math Before Scaling Changes

NEVER change replica counts, instance types, autoscaler bounds, or resource requests without showing the before/after arithmetic. A scaling change is a claim about peak load; the math is the claim made checkable.

- Base the math on peak utilization over a representative window (2–4 weeks minimum, covering known traffic patterns), never on the current instant. Pull the numbers from monitoring and cite them.
- Show the computation: total capacity before, total after, peak demand, resulting headroom. "6 replicas × 4 vCPU at 55% peak = 13.2 vCPU demand; 3 replicas = 12 vCPU total" is a one-line proof the change fails before it ships.
- Apply N+1: the fleet must absorb peak with one unit lost (node failure, AZ event, or simply a rolling deploy taking instances out of rotation). Downscaling to 2 means any single failure halves capacity.
- Translate instance-type changes into actual vCPU/GiB before and after — size names are not linear, and ratios change across families. Verify the new type satisfies the largest single workload (a 30 GiB JVM heap does not fit an instance with 16 GiB).
- Check autoscaler interaction: lowering `maxReplicas` or ASG max caps the safety valve; raising requests changes how many pods fit per node. Recompute, don't assume.
- For scale-ups, include the monthly cost delta. "Safe" has a price; state it.
- State the rollback (previous values, written down) and watch the deploy through the next genuine peak, not just the next five minutes.

**Red flags that you're about to violate this:**

- "CPU is sitting at 20%, halving the fleet is obviously fine..."
- "One size down is a marginal change..."
- "The autoscaler will catch it if I cut too deep..."
- "It handled the load fine for an hour after the change..."
- "More replicas can't hurt, I'll skip the cost check..."

---

## Why It Works

1. **It outlaws the instantaneous sample.** Nearly every bad downscale is justified by current-moment utilization; requiring a multi-week peak forces the input that actually governs whether the change survives.

2. **It makes the claim falsifiable before apply.** A written capacity equation can be wrong in review; a vibe ("should be plenty") can only be wrong in production. The rule moves the failure earlier.

3. **It encodes N+1 as deploys, not just disasters.** AIs treat redundancy as a hardware-failure concern; pointing out that every rolling deploy removes a unit makes the constraint bind on ordinary Tuesdays.

4. **It forces unit conversion on instance types.** Size names launder magnitude — `2xlarge` to `large` sounds incremental and is a 4× cut. Demanding actual vCPU/GiB numbers defeats the naming.

## Origin

A cost-reduction pass asked an assistant to right-size a service that "looked overprovisioned." Tuesday at 2 p.m., at 18% CPU, it cut replicas from 8 to 3 and dropped an instance size. The numbers held for nine days, until the month-end batch window — the documented, recurring, entirely predictable peak that the 8-replica fleet had been sized for. Three replicas hit 100% CPU, started failing health checks, got pulled from rotation, and the remainder collapsed in sequence. The original sizing turned out to have been load-tested; the new sizing had been vibes.

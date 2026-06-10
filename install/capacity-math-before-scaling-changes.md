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

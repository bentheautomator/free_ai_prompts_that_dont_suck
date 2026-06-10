### Drain Connections Before Removing Load Balancer Targets

NEVER terminate, delete, or stop a backend that is receiving traffic without removing it from rotation first and letting in-flight work finish. Removal from service is a three-step sequence — stop new traffic, drain existing, then terminate — and skipping the middle step converts every removal into a burst of user-facing errors.

- AWS: `aws elbv2 deregister-targets` first, then wait out the target group's deregistration delay (`aws elbv2 describe-target-health` until the target leaves `draining`), then terminate. Check the configured delay (`deregistration_delay.timeout_seconds`) — and if it's 0, that's a finding to report, not a convenience.
- Instances in an Auto Scaling group: scale down via the ASG (which integrates with ELB draining and respects lifecycle hooks), never by terminating the instances directly underneath it.
- Kubernetes: pods need `preStop` (even a simple `sleep 5`) so endpoint removal propagates before SIGTERM, and `terminationGracePeriodSeconds` longer than the longest in-flight request. Use `kubectl drain --ignore-daemonsets` for nodes, never `kubectl delete node`; respect PodDisruptionBudgets rather than `--disable-eviction` past them.
- Long-lived connections (websockets, streaming, workers mid-job) outlive any reasonable drain window; for those, stop accepting new work, wait for completion or checkpoint, and report what was abandoned.
- When asked to do an "immediate" removal, state the trade in one line — "terminating now will cut approximately N in-flight requests" — before complying.

**Red flags that you're about to violate this:**

- "Terminating the instance removes it from the LB automatically anyway..."
- "The drain delay is five minutes, that's too slow for this task..."
- "It's just a couple of pods, the blip won't show up anywhere..."
- "kubectl delete pod is basically a graceful operation..."
- "The PDB is blocking the drain, I'll evict past it..."

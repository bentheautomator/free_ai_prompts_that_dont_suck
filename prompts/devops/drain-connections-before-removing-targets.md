---
title: Drain Connections Before Removing Load Balancer Targets
slug: drain-connections-before-removing-targets
category: devops
tags: [universal, devops, deploys]
works_with: all
severity: high
one_liner: "Yanking instances out of a load balancer with requests still in flight"
---

# Drain Connections Before Removing Load Balancer Targets

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from terminating backends mid-request because deregistration looked like an instant operation.

**[Copy-paste ready version](../../install/drain-connections-before-removing-targets.md)** — just the instruction block, no explanation.

## The Problem

Removing a backend from service is a sequence, and AI assistants execute it as a single step. Asked to replace instances, shrink a fleet, or take a node out for maintenance, the AI runs `aws ec2 terminate-instances`, `kubectl delete pod`, or a scale-down — and the requests currently being processed by those backends die mid-flight. Users see 502s and reset connections; long-running operations (uploads, report generation, websockets) abort at whatever percentage they'd reached. The load balancer *would* have handled this gracefully: deregister the target, let the deregistration delay (connection draining) pass while in-flight requests finish and no new ones arrive, then terminate. The AI skips the middle because terminate is one command and the drain is invisible bookkeeping.

The Kubernetes version is identical in shape: deleting a pod without a `preStop` hook and a `terminationGracePeriodSeconds` that exceeds drain time means the pod gets SIGTERM while the endpoint controller is still propagating its removal — for a second or two, traffic is routed to a process that's already shutting down. Same with draining a node: `kubectl drain` exists precisely so pods get evicted in order, respecting PodDisruptionBudgets; `kubectl delete node` does not.

The damage is small per event and constant: an error-rate blip on every deploy, every scale-down, every maintenance — normalized as "deploy noise" when it's actually a missing drain step.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It decomposes "remove" into the sequence the AI collapses.** Stop-new, finish-existing, terminate is three operations; naming them separately is what prevents the one-command shortcut that drops the middle.

2. **It corrects the automatic-deregistration myth.** Termination does eventually remove the target, *after* the connections are already dead; ordering is the entire content of the rule, and the myth erases ordering.

3. **It quantifies the impatient path.** "Cutting approximately N in-flight requests" turns an invisible cost into a stated one, letting a human choose speed knowingly instead of by default.

4. **It treats PDBs and grace periods as load-bearing.** The AI encounters them as obstacles during eviction; framing them as the drain mechanism itself flips the instinct from bypass to respect.

## Origin

A routine instance refresh was done by hand: an assistant terminated the old instances right after the new ones passed health checks, reasoning the load balancer "would notice." It noticed in about ten seconds — during which several hundred requests, including a batch of payment confirmations, died on connections to machines that no longer existed. The payment provider's retry logic papered over most of it; the seventeen that double-charged did not stay papered over, and the refund-and-apology cycle cost more engineering hours than a deregistration loop ever would have.

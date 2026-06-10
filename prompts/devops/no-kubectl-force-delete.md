---
title: No Force-Deleting Kubernetes Resources
slug: no-kubectl-force-delete
category: devops
tags: [universal, devops, kubernetes]
works_with: all
severity: critical
one_liner: "Using --force --grace-period=0 or stripping finalizers to unstick deletions"
---

# No Force-Deleting Kubernetes Resources

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" a stuck Terminating resource by deleting the record of it while the real thing keeps running.

**[Copy-paste ready version](../../install/no-kubectl-force-delete.md)** — just the instruction block, no explanation.

## The Problem

A pod sits in `Terminating` for ten minutes. A namespace won't die. A PVC is stuck. The AI searches its training data and finds the internet's universal answer: `kubectl delete pod --force --grace-period=0`, or the famous finalizer-stripping patch (`kubectl patch ... -p '{"metadata":{"finalizers":null}}'`). The resource vanishes from `kubectl get`. Problem solved — except force deletion doesn't stop anything; it deletes the *API object* without waiting for confirmation that the workload died. If the node is partitioned or the kubelet is wedged, the container keeps running with no record of its existence. For a StatefulSet, that's the disaster scenario: the controller, seeing the name freed, starts a replacement — and now two instances of the same ordinal can be writing to the same volume or claiming the same identity in a quorum. Split-brain, by one flag.

Finalizers are worse to strip, because a finalizer is an unfinished cleanup contract: the volume not yet detached, the cloud load balancer not yet deleted, the namespace's children not yet reaped. Removing the finalizer doesn't perform the cleanup; it deletes the reminder. The orphaned cloud resources bill on, and the stuck state that *had a cause* is now a mystery with no evidence.

Stuck-Terminating always has a reason — an unreachable node, a hung controller, a pending volume detach. The AI's force-delete skips the diagnosis and converts a visible stall into invisible corruption.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Force-Deleting Kubernetes Resources

NEVER use `kubectl delete --force --grace-period=0`, strip finalizers, or hand-edit a resource out of etcd to unstick a deletion. Force deletion removes the API record without stopping the workload; finalizer removal cancels cleanup that hasn't happened. Both convert a stuck-but-honest state into a lying one.

- Diagnose why it's stuck first; the cause is almost always visible: `kubectl describe pod` (events), node status (`kubectl get nodes` — is the node NotReady?), which finalizers remain (`kubectl get <res> -o jsonpath='{.metadata.finalizers}'`), and the logs of the controller responsible for them.
- A pod stuck on an unreachable node is a *node* problem: fix or drain the node, or let the node controller evict properly. Force-deleting the pod while the node may still run it is how StatefulSets split-brain.
- A stuck namespace means some child resource can't finalize — find it (`kubectl api-resources --verbs=list -o name | xargs -n1 kubectl get -n <ns>`) and fix that, instead of nulling the namespace finalizer and orphaning everything inside.
- A finalizer that will genuinely never complete (its controller was uninstalled) is the one legitimate case — and it's a human decision, presented with: which finalizer, what cleanup it represented, and what will be orphaned. The orphaned external resources then need manual cleanup; say so.
- NEVER force-delete StatefulSet pods specifically without confirming the node is fenced (shut down or cordoned and verified): at-most-one semantics are the entire point of StatefulSets, and `--force` waives them.

**Red flags that you're about to violate this:**

- "It's been Terminating for ten minutes, force delete is the standard fix..."
- "Stack Overflow's top answer is grace-period zero..."
- "The finalizer is just stuck metadata, nulling it clears the wedge..."
- "The pod is obviously dead, the API object is stale..."
- "I'll force it and the controller will sort out the rest..."

---

## Why It Works

1. **It corrects what deletion means.** The AI models `kubectl delete` as "stop the thing"; stating that force-delete removes the *record*, not the workload, breaks the assumption underneath the entire shortcut.

2. **It reframes finalizers as contracts, not cruft.** "Stuck metadata" is the rationalization; "unperformed cleanup with a billable orphan" is the reality. The reframe makes stripping feel like what it is — deleting a to-do list to finish the to-dos.

3. **It names the StatefulSet split-brain explicitly.** This is the highest-severity consequence and it's invisible at decision time; pre-loading it attaches a concrete disaster to a routine-looking flag.

4. **It keeps a legitimate path open.** Dead-controller finalizers really do need manual removal sometimes; routing that through a human with a stated orphan list means the rule bends where reality requires instead of breaking.

## Origin

A node went NotReady and its database StatefulSet pod hung in Terminating. The assistant force-deleted the pod to "let Kubernetes reschedule it," which it promptly did — while the original container kept running on the partitioned node, holding the same persistent volume over the network. Two postgres processes wrote to one volume for six minutes before the node was fenced. The data corruption was subtle enough to pass health checks and bad enough to require a point-in-time restore, and the incident doc's root cause was four characters: `--force`.

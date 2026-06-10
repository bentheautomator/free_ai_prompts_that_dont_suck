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

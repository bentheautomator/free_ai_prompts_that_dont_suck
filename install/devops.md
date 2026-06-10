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

### Deploy by Immutable Image Tag, Never Latest

NEVER reference `:latest`, an untagged image, or any mutable tag (`stable`, `prod`, `main`) in a deployment manifest, task definition, compose file, or Helm values. A deploy must name an immutable artifact; otherwise rollback, audit, and "what is running right now" are all undefined.

- Tag images per build with something unique and traceable: the git SHA (`myapp:3f2a91c`), or version plus SHA (`myapp:1.4.2-3f2a91c`). For the strongest guarantee, deploy by digest: `myapp@sha256:...`.
- A release is a manifest change: bump the tag in the Deployment/values file, apply, done. Rollback is re-applying the previous tag — which only works if the previous tag still points at the previous build, i.e., never if the tag is `latest`.
- Never "deploy" by re-pushing an existing tag and restarting pods. Mutable-tag re-push means two replicas can run different code under the same name and the registry has silently lost the old build's address.
- Do not set `imagePullPolicy: Always` to make mutable tags behave; that's a workaround that adds a registry dependency to every pod start and still can't tell you what's running.
- If the project currently deploys `latest`, flag it before making changes that assume version identity (rollbacks, canaries, incident timelines) — those features don't actually exist yet.

**Red flags that you're about to violate this:**

- "latest is what the existing manifests use, I'll stay consistent..."
- "Re-pushing the tag and restarting the pods is the fastest way to ship this fix..."
- "imagePullPolicy: Always means the pods will always get the newest build, problem solved..."
- "Tagging every build clutters the registry..."
- "We can always tell what's running from the deploy timestamps..."

### No Deploy Without a Rollback Plan

NEVER execute a deploy without first stating, concretely, how to undo it. "Rollback plan" means three things written down before anything ships: the exact prior state (image tag, config version, infra revision), the exact command that restores it, and roughly how long restoration takes.

- Identify the current version before replacing it: `kubectl get deploy api -o jsonpath='{...image}'`, the live task definition revision, the current Helm release (`helm history`), or the prior git SHA. If you can't name what's running now, you can't roll back to it.
- Verify the rollback target still exists: the old image tag is still in the registry, the previous task definition revision isn't deregistered, the prior config is recoverable. A rollback plan pointing at a deleted artifact is a hope, not a plan.
- Name the one-way doors. Destructive migrations, dropped columns, queue format changes, and deleted resources make rollback impossible or partial — say so explicitly before deploying, and prefer reversible orderings (expand/contract, additive first).
- State what triggers the rollback: which metric or check, watched for how long after the deploy, decides "roll back now."
- Do not delete the previous version's artifacts (old images, launch templates, task definition revisions) as part of deploy cleanup. The previous version is the rollback; keep at least one.
- If a real rollback path doesn't exist for this change, that's a finding to surface, not a detail to omit. Let the human decide to proceed eyes-open.

**Red flags that you're about to violate this:**

- "It's a small change, we'll fix forward if anything breaks..."
- "Rollback is implied, we'd just redeploy the old version somehow..."
- "I'll clean up the old images while I'm at it..."
- "The migration is technically irreversible but it won't fail..."
- "They asked me to deploy, not to write contingency docs..."

### Lower the TTL Before Changing DNS

NEVER change a DNS record without first checking its current TTL and reasoning about propagation. DNS changes propagate on the old TTL's schedule and cannot be recalled from caches; a record change is a staged migration, not an edit.

- Before any change, query the live record: `dig +noall +answer example.com A` — note the value and the TTL. The current TTL is your propagation delay and, for mistakes, your minimum exposure time.
- For planned cutovers on records with TTL above ~300s: lower the TTL first (e.g. to 60), wait at least the duration of the *previous* TTL so caches expire, then change the value. Restore the longer TTL only after the new target is verified stable.
- Keep the old destination serving until the old TTL has fully elapsed after the change, plus margin. Resolvers that cached the old answer will keep sending traffic there; tearing it down at flip time strands them.
- Verify from public resolvers, not just authoritative: `dig @1.1.1.1`, `dig @8.8.8.8`. Authoritative answering correctly proves nothing about caches.
- Treat MX, NS, and apex records as the highest tier: mistakes bounce mail or take the whole zone dark, for TTL-length minimum. Present these changes for explicit human review with the dig output attached.
- State the rollback honestly: "revert the record, but cached resolvers serve the bad answer for up to <TTL>." If that exposure is unacceptable, the TTL must come down before the change, not after.

**Red flags that you're about to violate this:**

- "DNS propagates fast these days, the TTL is mostly theoretical..."
- "dig already shows the new value, the change is live..."
- "If it's wrong I'll just change it back..."
- "The old load balancer can be deleted now that DNS points elsewhere..."
- "I'll set a long TTL on the new record for performance..."

### Install Dependencies Before COPY Dot in Dockerfiles

ALWAYS order Dockerfile layers from least-frequently-changed to most-frequently-changed. Copy dependency manifests alone, install dependencies, and only then `COPY . .` — never the reverse. A `COPY . .` above the install step means every source edit re-runs the full dependency install.

- Node: `COPY package.json package-lock.json ./` then `RUN npm ci` then `COPY . .`
- Python: `COPY requirements.txt ./` (or `pyproject.toml` + lockfile) then `RUN pip install -r requirements.txt` then `COPY . .`
- Go/Rust: copy `go.mod`/`go.sum` or `Cargo.toml`/`Cargo.lock`, fetch/build deps, then copy source.
- System packages (`apt-get install`, `apk add`) change least often of all; they go above the dependency install, never below the source copy.
- Add a `.dockerignore` excluding `.git`, `node_modules`, build output, and local env files — a bloated COPY context both slows the build and invalidates cache with files that don't affect the image.
- When editing an existing Dockerfile, preserve its cache ordering; do not collapse separated COPY steps into one `COPY . .` for tidiness.
- Use the lockfile-honoring install command (`npm ci`, not `npm install`) so the cached layer is also reproducible.

**Red flags that you're about to violate this:**

- "COPY . . first is simpler and the build still passes..."
- "Build speed isn't part of what they asked for..."
- "Merging these COPY lines makes the Dockerfile cleaner..."
- "The deps layer rebuilds either way the first time, so ordering doesn't matter..."
- "It's a small project, the install only takes a minute..."

### Ship Runtime Images, Not Build Environments

ALWAYS use a multi-stage build for compiled or bundled applications. The production image contains the runtime and the built artifact — not compilers, dev dependencies, source files, test suites, or package manager caches.

- Pattern: a `build` stage (`FROM node:20.12-slim AS build`) that installs everything and compiles, then a runtime stage (`FROM node:20.12-slim`) that does `COPY --from=build /app/dist ./dist` plus a production-only dependency install (`npm ci --omit=dev`).
- Compiled languages go further: build in the full toolchain image, run from `debian:slim`, `distroless`, or `alpine` with just the binary. A Go or Rust service has no business shipping its compiler.
- Do not ship: `devDependencies`, `.git`, test directories, build caches, docs, or source files the runtime doesn't read. If the entrypoint doesn't execute it, it doesn't belong in the final stage.
- Keep `apt-get install` in the build stage unless the runtime genuinely needs the library; when it does, install the runtime lib (`libpq5`), not the dev package (`libpq-dev`).
- Maintain a `.dockerignore` so the build context itself stays lean.
- When you finish a Dockerfile, report the final image size (`docker images <name>`). If a Node service image is over ~400 MB or a Go service over ~50 MB, something that doesn't belong is in there.

**Red flags that you're about to violate this:**

- "Single-stage is simpler and image size wasn't in the requirements..."
- "Disk is cheap, a fat image hurts nobody..."
- "Keeping devDependencies in the image makes debugging in prod easier..."
- "I'll copy the whole /app directory forward, sorting out what's needed is fiddly..."
- "The scanner findings are all in build tools, so they're not real vulnerabilities..."

### Run Containers as a Non-Root User

ALWAYS end a production Dockerfile with a non-root `USER`. A container with no `USER` instruction runs the application as root, and root in the container is the difference between a contained bug and a foothold.

- Use the image's built-in unprivileged user when one exists (`USER node` on Node images) or create one: `RUN addgroup --system app && adduser --system --ingroup app app` then `USER app`.
- Place `USER` after build steps that need root (package installs) and before the `CMD`/`ENTRYPOINT`. Build as root if needed; never run as root.
- `chown` the specific directories the app writes (`COPY --chown=app:app`, or `chown app:app /app/data`) instead of `chmod -R 777`, which is root-by-other-means.
- Need a port below 1024? Listen on 8080 and map it, rather than keeping root for the bind.
- When a container hits a permission error, fix it by granting the unprivileged user access to the specific path — never by adding `USER root`, deleting the `USER` line, or running the container `--privileged`.
- In Kubernetes manifests you write, set `runAsNonRoot: true` and `allowPrivilegeEscalation: false` in the securityContext so the image-level decision is enforced at admission.

**Red flags that you're about to violate this:**

- "The base image examples don't set USER either..."
- "Permission denied, switching to root is the quickest unblock..."
- "It's containerized anyway, root inside the box is harmless..."
- "chmod 777 on the data dir and everyone's problem is solved..."
- "I'll sort out the user stuff after the container actually runs..."

### Pin Dockerfile Base Image Tags

NEVER write `FROM image:latest`, a bare `FROM image`, or a major-only tag like `python:3` in a Dockerfile. Unpinned base images make builds non-reproducible: the same Dockerfile produces different images on different days, and rollbacks rebuild on a base the original was never tested with.

- Pin to at least minor version plus variant: `FROM node:20.12-bookworm-slim`, `FROM python:3.12.3-slim`, not `node:latest` or `python:3`.
- For production images, prefer pinning by digest for full immutability: `FROM node:20.12-bookworm-slim@sha256:...` (get the digest with `docker buildx imagetools inspect <image:tag>`).
- Pin every stage of a multi-stage build, including the throwaway builder stage and any `COPY --from=<image>` references.
- The same applies to images referenced outside Dockerfiles that you're asked to write: compose files, CI service containers, base images in build scripts.
- When updating a pinned base, change the pin explicitly in its own commit so the upgrade is visible, testable, and revertible, instead of arriving as a silent side effect of the next build.
- If the project has no convention yet, choose the current stable version and pin it; do not leave the choice to the registry.

**Red flags that you're about to violate this:**

- "latest keeps them automatically up to date with security patches..."
- "Every tutorial Dockerfile uses node:latest..."
- "Pinning means someone has to maintain version bumps..."
- "It's just the builder stage, the final image is what matters..."
- "python:3 is pinned enough, the major version won't change behavior..."

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

### Keep Deletion Protection On

NEVER disable a deletion guard to make your change go through: `prevent_destroy` lifecycle blocks, `deletion_protection` attributes, termination protection, `skip_final_snapshot` flips, resource locks, or retention policies. When a protection blocks your apply, the protection has just succeeded — a past engineer predicted this exact moment and voted no.

- An apply blocked by `prevent_destroy` means your change destroys a resource someone marked never-destroy. First response: re-examine the change. Can it be achieved without replacement (a `moved` block for renames, an in-place attribute, a different attribute value that doesn't force replacement)?
- If destruction is genuinely intended, the protected resource's owner gets to confirm it. Present: which resource, what protection, who/when it was added if discoverable (`git log -S prevent_destroy -- <file>`), what will be lost, and the recovery story. The flag comes off only after that explicit confirmation — and the removal plus the destroy should be reviewed together, not smuggled in separate commits.
- Never flip the protection back off after "just this once" without restoring it in the same change for the replacement resource. New resource inherits the old one's protections.
- `skip_final_snapshot = true` on a database teardown is the same move in disguise: it deletes the safety artifact to make deletion faster. Final snapshots are the point.
- Locks and protections you encounter while debugging unrelated errors are out of scope entirely — note them, never touch them.

**Red flags that you're about to violate this:**

- "The lifecycle block is blocking the apply, I'll remove it and re-add it after..."
- "deletion_protection is clearly left over from an old setup..."
- "The error message says exactly which line to change..."
- "This is just Terraform being overly cautious..."
- "I'll skip the final snapshot, we're deleting it anyway..."

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

### Never Delete a Stuck CloudFormation Stack to Fix It

NEVER run `delete-stack` on a stack in a failure state as a troubleshooting step. The stack *is* the infrastructure: deleting it deletes every resource it owns. Failure states are locked, not broken, and each has a specific exit.

- First, find out what actually failed: `aws cloudformation describe-stack-events --stack-name X` and read the first `*_FAILED` event from the bottom of the failed operation — that's the root cause; everything after is cascade.
- `UPDATE_ROLLBACK_FAILED`: use `aws cloudformation continue-update-rollback`, adding `--resources-to-skip` for the specific resource that can't roll back (after fixing or understanding it). This returns the stack to operational without touching healthy resources.
- `DELETE_FAILED` (when deletion *was* intended): retry with `--retain-resources <logical-ids>` for the blockers, so they're orphaned for manual handling instead of force-bulldozed; report what got retained.
- `ROLLBACK_COMPLETE` after a *failed first creation* is the one state where delete-and-recreate is correct — nothing real was ever successfully created. Verify it's an initial create (stack has no prior successful state) before treating it that way.
- Check `DeletionPolicy` and termination protection before believing any deletion is contained; absence of `DeletionPolicy: Retain` on stateful resources means delete means delete.
- Never delete a stack to "resync" drift, clear an import error, or because the console won't let you update. If you believe deletion is genuinely necessary on a stack that has ever been healthy, list every resource in it (`describe-stack-resources`) and get explicit human confirmation against that list.

**Red flags that you're about to violate this:**

- "The stack is wedged, delete and redeploy is the clean-slate fix..."
- "delete-stack is the only operation it will accept, so that must be the path..."
- "The template is in git, everything is reproducible..."
- "It's in ROLLBACK_COMPLETE, AWS basically wants it deleted..."
- "I'll recreate it identically right after, nobody will notice the gap..."

### Never Delete Unused Cloud Resources on a Hunch

NEVER delete a cloud resource because it appears unused. "Nothing references it" means "nothing I checked references it" — cloud dependency graphs span accounts, regions, peered networks, and scheduled jobs that run quarterly.

- Before proposing any deletion, gather actual evidence of disuse: access logs and CloudTrail events over a meaningful window (90+ days for anything that might serve periodic jobs), attachment/reference queries (`aws ec2 describe-network-interfaces --filters Name=group-id,...` for security groups, `InUseBy` for certs, policy attachments for roles), and billing data showing activity.
- Prefer reversible quarantine over deletion: detach the security group, deny-all the IAM role via an attached policy, block public access and lifecycle-archive the bucket, stop (don't terminate) the instance. Wait an agreed period — weeks, not minutes — and delete only after silence.
- Some deletions are categorically not yours to make without explicit human signoff, regardless of evidence: KMS keys, S3 buckets with any objects, log groups, snapshots and backups, DNS zones, and anything with "backup," "audit," or "dr" in the name.
- Never delete a resource as a means to an end — to free a name, silence an error, or make `terraform destroy` complete. That's a deletion smuggled in as a fix.
- Present every proposed deletion with the evidence, the blast radius if you're wrong, and the recovery story (or the words "unrecoverable"). Let a human pull the trigger.

**Red flags that you're about to violate this:**

- "I searched the repo and nothing references this role..."
- "No traffic in the last week, it's clearly dead..."
- "Deleting it cleans up the account and the apply will finally go through..."
- "It's named temp-test-2022, obviously deletable..."
- "If anything used it, surely there'd be an alarm..."

### Never Silence Alarms to Ship

NEVER delete, disable, or de-sensitize monitoring to make a change go through or a channel go quiet. Alarms firing during your change are data; alarms wired to block or roll back deploys are doing their job. The acceptable tool is a scoped, time-boxed silence — never removal, never threshold surgery.

- An alert firing during your rollout is the system reporting your rollout's effects. Read it as a verdict on the change, not as noise: investigate before proceeding, and treat "the alarm keeps rolling my deploy back" as the alarm winning the argument.
- For planned, expected alert noise during maintenance, use the platform's silence/mute mechanism with an explicit scope and expiry (e.g. a 60-minute mute on the specific monitor, stated to the user). Silences end on their own; deletions don't.
- Never raise a threshold, extend an evaluation window, or change alarm conditions as part of a deploy or to stop flapping. Threshold changes are standalone, reviewed changes that name the old value, the new value, and the justification — with the alarm's history checked first (`git log` on the alert rule, or the monitoring system's audit trail) to see what incident it came from.
- Never disable alarm-triggered rollbacks, deploy gates, or auto-remediation wiring, even "temporarily for this one deploy." If the gate is wrong, fixing the gate is its own change with its own review.
- When renaming or removing metrics, find and update the monitors that consume them in the same change; a monitor pointed at a dead metric is silently blind, which is worse than loud.
- If asked directly to delete an alert, check and report what it was created in response to before complying.

**Red flags that you're about to violate this:**

- "This alarm always fires during deploys, it's basically noise..."
- "I'll bump the threshold so it stops flapping while I work..."
- "The auto-rollback keeps undoing my deploy, I'll disable it just for this release..."
- "Nothing references this monitor, it's dead config..."
- "I'll re-enable everything after the change lands..."

### Never Weaken Health Checks to Make a Deploy Pass

NEVER remove, loosen, or redirect a health check, readiness probe, liveness probe, or deploy gate because a deploy is failing it. A health check failing a rollout is the safety system succeeding; the broken thing is the build, the config, or — rarely — the check itself, and you must determine which before touching anything.

- Diagnose the failure as a failure: read the probe's actual response (`kubectl describe pod`, `kubectl logs`, curl the health endpoint from inside the network). Find what the check is seeing — connection refused, 503 from a dependency, timeout, crash loop.
- Weakening in any form is the same violation: deleting the probe, raising `failureThreshold`, inflating timeouts or `initialDelaySeconds` beyond what startup genuinely requires, pointing the check at a static path that can't fail, returning hardcoded 200 from the health handler, or lowering the LB healthy-host threshold.
- If the check itself is genuinely wrong (probes a dependency that's legitimately optional, runs before the JVM can possibly be up), fixing it is a deliberate change: state what the check verified before, what it verifies after, and get explicit approval — separately from the deploy you're trying to ship.
- A slow-starting app gets a `startupProbe` (or an honest measured `initialDelaySeconds`), not a gutted readiness probe.
- Never deploy with `--force`, skip-validation flags, or by deleting the failing pods so the rollout "completes." Completion by blinding is not completion.

**Red flags that you're about to violate this:**

- "The app is actually fine, the probe is just too strict..."
- "I'll bump the timeout so the rollout stops flapping..."
- "Pointing the check at / unblocks the deploy and we can revisit later..."
- "The health endpoint checks the DB, which isn't this deploy's concern..."
- "It works when I curl it from my shell, so the check is wrong..."

### Never Add Force-Destroy to Make Deletion Succeed

NEVER respond to a deletion error like `BucketNotEmpty` by adding `force_destroy = true`, emptying the resource, or otherwise clearing the contents that made deletion fail. A platform refusing to delete non-empty storage is a guardrail firing, and the contents are the question — not the obstacle.

- When a destroy fails because a resource has contents, the next step is an inventory, not a workaround: `aws s3 ls s3://bucket --recursive --summarize` (object count and total size), `aws s3api list-object-versions` for versioned buckets, image lists for registries. Report what's actually in there.
- Present the human with: what exists, how old, last-accessed evidence if available, and whether anything else references the bucket (replication rules, event notifications, other accounts' policies). The decision to destroy contents belongs to someone who has seen the inventory.
- Versioned buckets are versioned because someone chose recoverability; deleting all versions reverses that choice and is never an implementation detail of a cleanup task.
- If the data is confirmed disposable, prefer ordered disposal with a paper trail: a lifecycle expiration rule or an explicit, logged emptying step approved as its own action — then the destroy. `force_destroy = true` left in committed code is also a landmine for every future destroy; don't commit it as a permanent setting.
- The same rule generalizes: any `--force`, `skip_final_snapshot = true`, or contents-clearing step whose purpose is to make a deletion stop failing requires the inventory-and-approve treatment. (For databases specifically: never skip the final snapshot to speed up a teardown.)

**Red flags that you're about to violate this:**

- "The destroy is failing on a non-empty bucket, force_destroy fixes that..."
- "They asked me to tear down the environment, the contents are implied..."
- "It's the logs bucket, logs are disposable..."
- "I'll empty it first, that's what the error is asking for..."
- "Old versions are just storage overhead..."

### No IAM Wildcards to Unblock a Deploy

NEVER fix a permission error by granting `Action: "*"`, service-level wildcards (`s3:*`, `iam:*`), or `Resource: "*"`. An AccessDenied names the exact action and resource that were denied; the fix is exactly that grant, scoped to exactly that resource.

- Read the error: it contains the principal, the action (`s3:PutObject`), and usually the ARN. Grant that action on that ARN (or a tight prefix like `arn:aws:s3:::deploy-artifacts/*`), nothing wider.
- Permission errors arriving one at a time is normal. Iterating three times on narrow grants beats one wildcard; if iteration is impractical, derive the needed set from the service's documented actions for the operation, or from CloudTrail/IAM Access Analyzer data on what the role actually calls — then grant that list.
- Treat certain actions as red-line, never granted as collateral: `iam:*` (privilege escalation), `iam:PassRole` un-scoped, `kms:*`, `sts:AssumeRole` on `*`, and any `Delete*`/`Put*Policy` the workflow doesn't demonstrably perform.
- Never widen a *different* principal's policy because it's the one you can edit; fix the principal that was denied.
- If a wildcard already exists in the policy you're editing, don't extend the pattern ("the role already has `s3:*`, so `dynamodb:*` is consistent"). Flag it instead.
- A temporary wildcard "to confirm permissions are the issue" counts as a violation the moment it's applied to a shared environment; use the IAM policy simulator for that experiment instead.

**Red flags that you're about to violate this:**

- "I keep hitting new AccessDenied errors, a wildcard ends the loop..."
- "I can't enumerate everything the deploy will need..."
- "It's only the staging role..."
- "s3:* on one bucket's resources is basically scoped..."
- "The role next to it already has admin, this is no worse..."

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

### No Manual Edits to IaC-Managed Infrastructure

NEVER modify infrastructure with the console, raw cloud CLI, or SDK calls when that resource is managed by IaC (Terraform, CloudFormation, Pulumi). Out-of-band edits create drift, and the next `apply` silently reverts them — turning your quick fix into a future outage with someone else's name on the apply.

- Before mutating any cloud resource directly, check whether it's IaC-managed: search the repo for its name/ID, run `terraform state list | grep <name>`, or check the resource's tags (many teams tag `ManagedBy: terraform`). Assume managed until proven otherwise.
- Make the change in code, plan, review, apply. Yes, even for one attribute. The IaC path is the change; the CLI path is drift.
- In a genuine emergency where the out-of-band fix must happen first, do the fix and immediately update the IaC to match in the same session — then run `terraform plan` and confirm it shows no diff on that resource. An emergency fix without the follow-up commit is an unexploded reversion.
- Never "fix" drift you discover by adjusting reality to match code without asking — the manual change you're about to revert may be someone's emergency fix that was never backported. Surface the drift, ask which side is right.
- Read-only CLI calls (`describe-*`, `get-*`, `list-*`) are always fine and encouraged for diagnosis.

**Red flags that you're about to violate this:**

- "One CLI call now versus a whole plan-review-apply cycle..."
- "I'll update the Terraform to match later..."
- "It's a tiny attribute change, drift this small won't hurt..."
- "The console is right there and the user wants this fixed now..."
- "The plan shows an unexpected change, I'll just apply and let it converge..."

### Never Let Terraform Replace Stateful Resources

NEVER apply a plan in which a stateful resource is marked `forces replacement` or `-/+`. Stateful means it holds data or identity that doesn't live in the config: databases (RDS, ElastiCache, DynamoDB), volumes and disks, S3 buckets, message queues, Elastic IPs, KMS keys, certificates, and anything with "cluster" in the name.

Replacement of a stateful resource is not an update. It is delete-everything followed by create-empty, and Terraform will not warn you beyond that one annotation.

- Before editing an attribute on a stateful resource, check whether the provider treats it as immutable (the docs mark these "forces new resource"). If it does, stop and tell the user what replacement would destroy.
- Present alternatives instead of applying: snapshot-and-restore, blue/green with data migration, `create_before_destroy` where the resource type genuinely supports it, or simply not making the cosmetic change.
- If replacement is truly intended, require the user to confirm after you have stated, in plain words, exactly what data ceases to exist and what the restore plan is.
- Verify backups exist and are recent before any approved replacement: `aws rds describe-db-snapshots`, volume snapshots, bucket versioning status.
- Never add `lifecycle { create_before_destroy }` as a magic fix for databases; two instances cannot share an identifier, and the create simply fails after the destroy is already queued.

**Red flags that you're about to violate this:**

- "Terraform will recreate it with the new settings, that's how Terraform works..."
- "It forces replacement, but the config will end up matching what they asked for..."
- "There's probably an automated backup somewhere..."
- "The user approved the plan, even if I didn't spell out the data loss..."
- "It's a small instance, recreating it should be quick..."

### Keep Secrets Out of Docker Image Layers

NEVER put credentials into a Docker image by any route: no `ENV SECRET=...`, no `ARG TOKEN` used in a RUN, no `COPY` of keyfiles, no echoing creds into config files mid-build. Layers are immutable and inspectable; `docker history` and `docker save` recover everything, and a later `rm` removes nothing from earlier layers.

- For build-time secrets, use BuildKit secret mounts: `RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci`, passed with `docker build --secret id=npmrc,src=$HOME/.npmrc`. The secret exists only for that command, in no layer.
- For git-over-SSH dependencies, use `RUN --mount=type=ssh git clone ...` with `docker build --ssh default` — never COPY a private key into the image.
- Runtime secrets enter at runtime: injected env vars, mounted files, or the platform's secret store — never written into the image so the container "works out of the box."
- The COPY-use-delete pattern is a leak, not a mitigation. So is a multi-stage build that copies the secret into the builder stage and then copies an artifact forward while the builder layers go to cache — build caches are pullable too.
- Add `.dockerignore` entries for `.env`, `.npmrc`, `*.pem`, and `.ssh/` so a broad `COPY . .` can't sweep credentials in silently.
- If you find a secret already baked into an image, say so: it needs rotation, not just a fixed Dockerfile, because every pushed copy still contains it.

**Red flags that you're about to violate this:**

- "I'll pass the token as a build ARG, that's not the same as hardcoding it..."
- "The RUN step deletes the key right after using it..."
- "Only the builder stage sees the secret, the final image is clean..."
- "This registry is private, who's going to inspect the layers..."
- "ENV is how all the docker-compose tutorials inject credentials..."

### No Terraform State Surgery to Silence Errors

NEVER run `terraform state rm`, `terraform state mv`, edit a `.tfstate` file by hand, or delete/replace the state file because Terraform is reporting an error. State is the database linking config to live infrastructure; surgery on it doesn't fix problems, it hides resources.

- `terraform state rm` does not delete a resource; it orphans one. The infrastructure keeps running and billing, unmanaged, and a re-apply of the same config will try to create a colliding duplicate.
- Diagnose the underlying disagreement first: `terraform plan` to see the diff, `terraform state show <addr>` to inspect what state believes, provider docs for the error text.
- Reconcile with the purpose-built tools: `terraform import` for resources that exist but aren't tracked, `moved` blocks for renames, `terraform refresh`/plan to absorb drift, provider version pinning for provider bugs.
- If a state operation genuinely is the right fix (it occasionally is, e.g. removing a resource the user deliberately deleted out-of-band), present the exact command, what the state currently says, and what will be orphaned or re-homed, and let the user run or approve it.
- Never delete `.terraform.lock.hcl`, the backend state object, or local state backups as a troubleshooting step. If state is corrupted, stop and tell the user; backends keep versions for exactly this moment.

**Red flags that you're about to violate this:**

- "Removing it from state will clear the error so I can finish the apply..."
- "State and reality disagree, so I'll just make state match by editing it..."
- "It's safe, state rm doesn't actually touch infrastructure..."
- "I'll delete the local state and re-init to get a clean slate..."
- "This resource is causing the cycle, easiest to drop it from state..."

### Roll Out Gradually, Not Big Bang

NEVER configure or execute a deploy that replaces all serving capacity in one step. New code's first contact with production traffic must be partial, observed, and abortable.

- In Kubernetes, default to `RollingUpdate` with `maxUnavailable: 0` and a modest `maxSurge` (e.g. 25%); never set `strategy: Recreate` for a traffic-serving Deployment unless the app genuinely cannot run two versions concurrently — and say so if that's the claim.
- Between phases, observe: error rate, latency, and the deploy-relevant metric, for long enough to mean something (minutes of real traffic, not "the pods are Ready"). Readiness gates catch crash loops; only traffic catches wrong answers.
- Use the platform's native gradual mechanisms instead of hand-rolling: ASG instance refresh with batch sizes and health checks, weighted target groups, CodeDeploy/Argo Rollouts canary steps, per-service traffic splitting.
- Never remove, shorten, or skip an existing canary phase, bake time, or rollout pause to make a deploy faster — those settings are someone's post-incident scar tissue. Changing them is its own reviewed change, not a deploy-time convenience.
- Version skew is a feature requirement, not an excuse: if old and new genuinely can't coexist (schema, protocol), the fix is expand/contract sequencing, not Recreate.
- Big-bang is occasionally legitimate (single-replica services, true breaking cutovers, emergency patches). Name the reason, state the blast radius — "all traffic moves at once; rollback takes N minutes" — and get the human's yes.

**Red flags that you're about to violate this:**

- "Recreate is cleaner, no version-skew headaches..."
- "The change is tiny, a canary phase is ceremony..."
- "Tests passed, gradual rollout just delays the same outcome..."
- "I'll set the canary wait to zero so the pipeline finishes in this session..."
- "Both versions briefly running might cause weirdness, safer to stop everything first..."

### Stage Infra Changes Before Prod, Keep Environments Twins

ALWAYS land infrastructure changes in staging before production, and ALWAYS propagate prod-only emergency fixes back to staging. Environments are one definition deployed multiple times; any change that touches only one environment is creating a lie that a future deploy will believe.

- Default order for any infra change: staging first, verify (actually verify — exercise the changed path, not just "apply succeeded"), then prod with the identical diff. If the change can't be expressed as the same code applied to both, say so before proceeding.
- When asked to fix something "in prod," check whether staging shares the flaw. It usually does; fix both, staging first unless the prod incident is active.
- After any prod-first emergency change, immediately apply the same change to staging in the same session. A prod hotfix without the staging backport is parity debt with no ticket.
- Keep differences declarative and minimal: instance sizes and replica counts may differ via per-env variables, but topology, versions, and configuration structure should not. Never introduce a structural difference (a resource that exists in one env only, a different engine version) as a side effect of a task.
- Before a high-risk prod change (engine upgrades, networking changes, controller swaps), state where it was rehearsed. "Nowhere" is sometimes the true answer; it should be said out loud, not discovered.
- If no staging environment exists for what you're changing, surface that as a finding rather than silently going straight to prod.

**Red flags that you're about to violate this:**

- "The problem is in prod, so prod is where the fix goes..."
- "Staging is probably already different anyway..."
- "I'll backport this to staging in a follow-up..."
- "It's a low-risk change, rehearsal would be theater..."
- "Staging is smaller, so the change wouldn't tell us much there..."

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

### Import Existing Resources, Never Delete Them

NEVER delete, empty, or rename-around a live resource to resolve a Terraform "already exists" error. That error means real infrastructure exists outside state; the fix is adoption, not demolition.

- Use `terraform import <address> <id>` or an `import` block to bring the existing resource under management, then run `terraform plan` and reconcile config to match reality (not the other way around) until the plan is clean.
- Before importing, inspect what actually exists (`aws iam get-role`, `aws s3api get-bucket-versioning`, etc.) — the live resource's settings are the source of truth your config must absorb, and they often contain configuration nobody remembered (policies, lifecycle rules, tags).
- Do not "resolve" the collision by changing the name in config to something unused. That creates a duplicate and orphans the original, doubling cost and splitting traffic or permissions across two resources.
- Do not delete the resource even if it looks empty or auto-generated. IAM roles, log groups, and security groups accumulate invisible dependents.
- If the existing resource genuinely should not exist, say so and let the user delete it; deletion of live infrastructure is never a side effect of fixing an apply.

**Red flags that you're about to violate this:**

- "It already exists, so deleting it and letting Terraform recreate it gets us to a clean state..."
- "The role looks auto-generated, nothing real can depend on it..."
- "Renaming my resource sidesteps the conflict entirely..."
- "Import is fiddly, recreate is one command..."
- "Terraform will recreate it identically anyway..."

### Use Moved Blocks for Terraform Renames

NEVER rename a Terraform resource, move it into or out of a module, or change `count` to `for_each` without a `moved` block (or an explicit `terraform state mv`, with user approval). A resource's address is its identity: change the address without telling Terraform, and the plan becomes destroy-old plus create-new.

- For every rename or module move, add a `moved` block in the same change: `moved { from = aws_db_instance.db, to = aws_db_instance.main }`.
- This applies to module restructuring too: moving `aws_s3_bucket.logs` into `module.storage` changes its address to `module.storage.aws_s3_bucket.logs` and needs a `moved` block.
- Converting `count` to `for_each` changes every instance address (`[0]` becomes `["key"]`); write a `moved` block per instance.
- After the change, run `terraform plan` and verify it reports the move (or zero changes), not a destroy/create pair. A plan containing `destroy` for a resource you only renamed means the move is wired wrong. Stop.
- On older Terraform without `moved` blocks, propose `terraform state mv` commands for the user to review and run; do not run them unprompted.
- Pure cosmetic renames of stateful resources (databases, volumes, buckets, queues) are not worth doing at all unless the user explicitly wants them. Say so.

**Red flags that you're about to violate this:**

- "This is just a rename, refactors don't change behavior..."
- "The new name is more consistent with the rest of the module..."
- "I'm only moving it into a module, the resource block itself is identical..."
- "Terraform will figure out it's the same resource..."
- "The plan shows one add and one destroy, which is what a rename looks like..."
- "I'll skip the moved block, state mv can fix it later if anyone notices..."

### No Targeted Terraform Applies

NEVER use `terraform apply -target=...` or `-replace=...` to work around a confusing plan, a failed apply, or changes you didn't expect. Targeted applies split the dependency graph and leave state partially updated; the unexplained remainder of the plan is debt assigned to whoever runs Terraform next.

- If a full plan contains changes beyond what the user asked for, that is information, not noise: report the unexpected diff and find out why (drift, someone else's unapplied work, a provider upgrade) before applying anything.
- If an apply fails partway, run a fresh full plan and fix the cause of the failure. Terraform is designed to converge from partial applies; `-target` is not the convergence mechanism.
- Do not use `-replace` to "refresh" an unhealthy resource without first diagnosing why it's unhealthy. Recreating it usually recreates the problem, minus the evidence.
- Legitimate `-target` uses exist (bootstrapping circular dependencies, emergency isolation of a broken module) but they are the user's call: name the flag, the target, and why a full apply won't work, then wait.
- After any targeted apply the user does approve, run a full `terraform plan` immediately and report what remains unapplied, so the partial state is documented rather than discovered.

**Red flags that you're about to violate this:**

- "The full plan has a bunch of unrelated changes, I'll just target the one resource I touched..."
- "Terraform warns about -target but it's only a warning..."
- "The apply failed halfway, targeting the failed resource will finish the job..."
- "I'll replace the instance to clear the weird error state..."
- "Someone else's pending changes aren't my problem to apply..."

### Validate TLS Certificates Before Cutover

NEVER install, replace, or delete a TLS certificate without validating it first and identifying everything that uses the old one. Cert mistakes fail all clients at once, and a deleted in-use cert can take an endpoint down at the next restart.

Before attaching a new cert:
- Check coverage: `openssl x509 -in cert.pem -noout -text | grep -A1 'Subject Alternative Name'` — every hostname the endpoint serves must be listed or wildcard-covered. `example.com` and `*.example.com` are different entries.
- Check validity dates and that the key matches: compare `openssl x509 -noout -modulus | openssl md5` against `openssl rsa -noout -modulus | openssl md5`.
- Include the full intermediate chain in the deployed bundle. Verify post-deploy with `openssl s_client -connect host:443 -servername host` and confirm `Verify return code: 0` — a browser check is not sufficient, because browsers repair missing intermediates and real clients don't.
- Prefer staged validation: attach to a staging listener or test port first, verify with real client libraries, then cut over.

Before deleting or letting an old cert lapse:
- Enumerate consumers: load balancer listeners, CDN distributions, API gateways, internal services, webhook mTLS configs. In AWS: `aws acm describe-certificate --certificate-arn ... --query 'Certificate.InUseBy'`.
- Keep the old cert available until the new one is verified in production; cert rollback should be re-attaching, not re-issuing.
- Never disable cert validation anywhere (clients, health checks) to make a cutover "work." A verification failure is the system telling you the cutover is broken.

**Red flags that you're about to violate this:**

- "The cert was issued for this domain, the SANs will be fine..."
- "It loads in my browser check, ship it..."
- "The old cert is expired-ish anyway, deleting it cleans things up..."
- "I'll skip the chain file, most clients fetch intermediates themselves..."
- "Renewal is routine, it doesn't need a verification step..."

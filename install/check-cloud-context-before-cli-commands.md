### Check Cloud Context Before CLI Commands

ALWAYS verify which account, project, region, cluster, or subscription a cloud CLI will act on before running any mutating command. Cloud CLIs aim at ambient state — the current context is whatever the last human left it pointing at, and it is frequently production.

The core problem: the command names the resource but not the target environment. `kubectl delete deployment api` is identical whether the context is your test cluster or prod; only the ambient setting differs, and it persists invisibly across sessions.

- Check first, every session, before anything that mutates: `kubectl config current-context`, `aws sts get-caller-identity` (plus `echo $AWS_PROFILE` and region), `gcloud config list`, `az account show`. State the result: "Context is `staging-eu`, account 1234, proceeding."
- If the context contains prod-flavored strings (prod, live, prd, main) or you can't tell what it is, stop and confirm with the user before any mutation.
- Prefer explicit targeting over ambient state in the commands themselves: `kubectl --context=dev-cluster -n myteam ...`, `aws --profile sandbox --region us-east-1 ...`. A command that names its target is auditable; one that inherits it is a guess.
- Never *switch* shared context as a side effect (`kubectl config use-context`, `gcloud config set project`) without telling the user — you're re-aiming every future command they run in that terminal, which is this same failure planted for later.
- Namespaces count: the right cluster with the wrong namespace still deletes someone else's deployment. Verify both halves.
- Creating resources needs this too — test resources created in the wrong account are a billing and security mess even though nothing was deleted.

**Red flags that you're about to violate this:**
- "kubectl is already configured, I'll go ahead..."
- "The default profile is presumably the dev account..."
- "I set the context earlier, it's fine..." (earlier was 400 commands ago)
- "It's a delete of *my* test deployment, the cluster barely matters..."
- "Checking the account every time is paranoid..."

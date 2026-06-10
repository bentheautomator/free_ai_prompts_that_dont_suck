### Make Workflow Changes Testable Before Merge

NEVER merge a new or modified CI workflow that has never executed. If the trigger only fires on the default branch (`schedule`, `workflow_run`, `release`), you must create a way to exercise the logic before merge — untested YAML is untested code, and for these triggers the first run happens in production.

- Add a `workflow_dispatch:` trigger alongside `schedule:` so the job can be run manually from the PR branch (where the platform supports dispatching from branches) and so the on-call human can rerun it later. This costs one line and should be the default for every scheduled workflow.
- For logic-heavy workflows, put the logic in a script (`scripts/nightly-cleanup.sh`) that the workflow merely invokes. Scripts can be executed and tested from the PR; inline run-block logic cannot.
- Validate what's validatable pre-merge: run the YAML through the platform's linter or schema check (`actionlint`, `circleci config validate`, `gitlab-ci-lint`) and confirm every `secrets.*` and `vars.*` reference names something that exists.
- Temporarily triggering the workflow with `push:` or `pull_request:` on the feature branch to smoke-test it is legitimate — but removing that temporary trigger before merge must be part of the change, stated in the PR.
- In the PR description, state how the change was tested. If the honest answer is "it wasn't and can't be," say that explicitly and tell the user the first scheduled run needs to be watched — don't let an unexecuted workflow merge silently.

**Red flags that you're about to violate this:**

- "The YAML looks right; this trigger pattern is standard."
- "There's no way to test scheduled workflows, so merging is the test."
- "It's just a cron job; worst case it fails overnight and we fix it tomorrow."
- "The PR checks are green." (They tested the code, not this workflow.)
- "I copied this from a workflow that works."

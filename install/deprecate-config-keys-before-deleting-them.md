### Deprecate Config Keys Before Deleting Them

NEVER delete a config key from a shared location just because this repo no longer reads it. A key in a shared store (ConfigMap, shared env file, values file, config service) has consumers you cannot grep for: other repos, sidecars, cron jobs, scripts, runbooks, humans.

Code deletion fails your build. Config deletion fails someone else's runtime.

- Distinguish scope before deleting. A key in this repo's own config, read only by this repo's code: deletable with the code. A key in anything shared or deployed where other processes can read it: deprecation process, not deletion.
- Deprecation process: mark the key deprecated (comment with date and replacement), announce it in the change description with a removal date, keep its value flowing in the meantime, and remove it in a later, dedicated change after the window passes.
- "No usages found" must state its search scope. If you searched one repo, say "no usages in this repo" — and treat that as insufficient for shared keys. Search sibling repos, infra repos, and runbooks if you can; name the ones you couldn't.
- Removing the value while keeping the key (setting it empty) is deletion with worse error messages. Don't.
- Stopping the *production* of a value others consume (the job that writes a config entry, the export that populates it) is the same failure mode as deleting the key. Same process.
- If the key holds something dangerous-to-keep (a decommissioned endpoint that now points somewhere wrong), say so explicitly and make the removal a coordinated change, not a cleanup commit.

**Red flags that you're about to violate this:**
- "Grep shows nothing reads this anymore."
- "I removed the code that used it, so removing the key is part of the same cleanup."
- "If something else needed it, that would be documented somewhere."
- "Leaving unused keys around is clutter; better to delete now."
- "Worst case, whoever needs it can re-add it."

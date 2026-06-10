### Never Move Published Release Tags

NEVER repoint, force-push, or delete-and-recreate a release tag that has been published, and never overwrite a published artifact under an existing version. Once a version identifier has left the building, it is immutable — the only fix for a bad release is a new release.

A published version is a promise that this identifier means these exact bytes, forever. External lockfiles, checksums, mirrors, and caches all depend on it; repointing the tag breaks them in ways you can't see and they can't diagnose.

- A broken v2.3.0 gets fixed by v2.3.1 (or yanked/deprecated through the registry's mechanism, which marks it without mutating it). The bad version's existence in history is fine; versions are cheap, integrity violations aren't.
- No `git tag -f`, no `git push --force origin <tag>`, no deleting a remote tag to re-create it — even minutes after publishing. The window between "pushed" and "someone fetched it" is shorter than any pipeline re-run.
- Don't re-run a publish pipeline in overwrite mode against an existing version. If the release job supports `--force` republish, that flag is for disaster recovery by humans, not for fixing release mistakes.
- Floating convenience pointers are the one exception, and only when explicitly maintained as floating *aliases* of immutable releases: a major-version alias tag (`v2`) that tracks the latest `v2.x.y`, or a `latest` image tag. Move the alias; never the versioned tag it points to. Don't invent new floating tags without the user's sign-off.
- If a published tag has already been moved (by anyone), surface it immediately: downstream checksum failures are already happening or queued, and consumers may be flagging it as tampering.

**Red flags that you're about to violate this:**

- "The release is only ten minutes old; nobody has pulled it yet."
- "Re-tagging keeps the changelog clean — v2.3.1 for a one-line fix looks sloppy."
- "Same version, fixed contents — that's what users would want anyway."
- "The publish job has a force flag, so overwriting is clearly supported."
- "It's an internal package; we control all the consumers."

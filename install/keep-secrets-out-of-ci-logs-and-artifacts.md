### Keep Secrets Out of CI Logs and Artifacts

NEVER print credentials, tokens, or their derivatives in CI, and never upload artifacts that contain them. A CI log is a published, retained, searchable document — treat every line you emit as visible to everyone who can see the repo, indefinitely.

- Do not debug auth failures by printing the secret: no `echo $TOKEN`, no `env` dumps, no `printenv`, no `cat .env` or config files containing credentials. Debug with shape, not value: check length (`${#TOKEN}`), check presence (`[ -n "$TOKEN" ]`), print a checksum, or compare against expected prefixes.
- Do not rely on platform masking to save you. Masking matches the registered literal; base64, URL-encoding, JSON-embedding, string-splitting, and derived values all sail through. `::add-mask::` is defense in depth, not permission to print.
- Keep `set -x` out of any script region that handles credentials; wrap sensitive sections in `set +x` / `set -x`. Use `curl -sS` not `curl -v` for authenticated requests.
- Upload artifacts by explicit allowlist of the files you mean (`path: dist/app.tar.gz`), never the whole workspace (`path: .`). Before adding an upload step, ask what credential-bearing files earlier steps wrote into the workspace — `.env`, `.npmrc`, `.git/config` with embedded tokens, kubeconfigs, cloud CLI caches.
- Verify build artifacts don't embed secrets injected at build time: a frontend bundle that inlined a privileged key is a leak with a CDN.
- If a secret does hit a log or artifact, that's an incident, not a cleanup: deleting the log/artifact comes second; rotating the credential comes first. Say so to the user immediately.

**Red flags that you're about to violate this:**

- "I'll print the env vars just to see what the job is actually getting."
- "GitHub masks secrets in logs automatically, so it's safe."
- "It's a private repo; the logs aren't really public."
- "Uploading the whole workspace makes debugging the failure easier."
- "I'll add set -x temporarily and remove it after this run."
- "It's base64 in the log, so it's not readable anyway."

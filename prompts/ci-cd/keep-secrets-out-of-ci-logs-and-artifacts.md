---
title: Keep Secrets Out of CI Logs and Artifacts
slug: keep-secrets-out-of-ci-logs-and-artifacts
category: ci-cd
tags: [universal, ci, security]
works_with: all
severity: critical
one_liner: "Stops the AI from echoing credentials into build logs or uploaded artifacts"
---

# Keep Secrets Out of CI Logs and Artifacts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from printing secrets to pipeline logs or packing them into uploaded artifacts while debugging or building.

**[Copy-paste ready version](../../install/keep-secrets-out-of-ci-logs-and-artifacts.md)** — just the instruction block, no explanation.

## The Problem

The deploy step can't authenticate, and the assistant wants to know why. The debugging instinct that is perfectly safe on a laptop — print the variable — is a disclosure event in CI: `echo "TOKEN=$DEPLOY_TOKEN"`, `env | sort` "to check the environment," `set -x` at the top of a script that exports credentials, `curl -v` dumping an Authorization header. CI logs are retained for months, visible to everyone with read access to the repo (on public repos: everyone, period), and copied into log aggregators that have their own audiences. Platform secret-masking helps and is routinely defeated — by transformed values (base64, URL-encoded, split across lines), derived values, and secrets the platform was never told about.

Artifacts are the same leak with a download button. A debug-minded `actions/upload-artifact` with `path: .` ships the workspace — including the `.env` file a previous step wrote, the `.npmrc` with the auth token, the kubeconfig, the webpack bundle that inlined an environment variable at build time. Artifacts outlive the run, get downloaded onto laptops, and on public repos are available to anyone logged in.

Assistants leak this way because printing state is their core debugging move and CI looks like just another shell. Nothing about `echo` feels dangerous. The missing context is that a CI log is not a terminal — it's a published document with an audience, a retention policy, and a search box.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It replaces the broken mental model.** The unsafe behavior follows from "CI is a terminal"; the rule installs "CI is a publication," from which the safe behaviors follow without enumeration.
2. **It provides debugging substitutes, not just prohibitions.** Length, presence, and checksum checks answer the actual question ("is the secret set and correct-shaped?"), so the assistant isn't choosing between the rule and finishing its task.
3. **It pre-breaks the masking excuse** by naming the specific transformations that defeat it, which is exactly the evidence an assistant needs to stop treating masking as a safety net.
4. **It sets the incident-response priority order** — rotate, then delete — because the natural instinct (delete the visible evidence) feels like remediation while leaving the credential live in unknown hands.

## Origin

A workflow's smoke-test step failed against the staging API, and the assistant debugging it added a step that ran `env | sort` "to verify configuration." The staging admin token appeared in the log of a public repository, base64 in one place and plaintext in another, where it sat for five days before a security researcher reported it. The token had also been valid for production. The log line took ten seconds to write and the rotation, audit, and disclosure review took three weeks.

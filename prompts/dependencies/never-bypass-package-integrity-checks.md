---
title: Never Bypass Package Integrity Checks
slug: never-bypass-package-integrity-checks
category: dependencies
tags: [universal, dependencies, supply-chain]
works_with: all
severity: critical
one_liner: "Stops disabling SSL and checksum verification to make installs pass"
---

# Never Bypass Package Integrity Checks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from switching off the verification layer between your build and a tampered package.

**[Copy-paste ready version](../../install/never-bypass-package-integrity-checks.md)** — just the instruction block, no explanation.

## The Problem

An install fails with a TLS error behind a corporate proxy, or `npm ci` reports `EINTEGRITY`, or pip complains about an untrusted mirror — and the AI assistant finds the workaround the internet always finds: `npm config set strict-ssl false`, `pip install --trusted-host pypi.org`, `NODE_TLS_REJECT_UNAUTHORIZED=0`, or scrubbing the offending integrity hash out of the lockfile. The install goes green. The assistant has just disabled the only mechanisms that verify the code being downloaded is the code the author published.

These checks are not bureaucratic friction; they are the firewall against specific, practiced attacks. TLS verification is what stops an on-path attacker (or a compromised proxy) from substituting package contents in transit. The lockfile's integrity hash is what detects a registry serving different bytes than were recorded. A checksum mismatch error means *the package you received is not the package you expected* — which is either a real problem with your mirror or the worst sentence in software supply-chain security, and in neither case is "stop checking" the answer. Worse, these bypasses tend to be set globally and forgotten, silently degrading every future install on the machine or in the CI image.

Assistants do this because the error text matches a well-known remedy in the training data, and the remedy genuinely makes the error stop. The fact that the error was a security control firing — possibly doing its job correctly — never enters the loop.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Bypass Package Integrity Checks

NEVER disable the verification between your package manager and the code it downloads. No `strict-ssl false`, no `NODE_TLS_REJECT_UNAUTHORIZED=0`, no `--trusted-host` to silence TLS errors, no `verify_ssl = false`, and never delete or edit integrity hashes to make a lockfile error pass. These checks are the only thing confirming you're installing what the author published.

- A TLS failure during install means the secure channel can't be established. The fix is fixing the channel: configure the corporate proxy's CA certificate properly (`npm config set cafile`, `pip config set global.cert`, `REQUESTS_CA_BUNDLE`), not turning verification off.
- An `EINTEGRITY` or checksum mismatch means the downloaded bytes don't match the recorded hash. Treat it as a real signal: clear the local cache and retry (`npm cache clean --force`), check whether a mirror is misbehaving, and if the mismatch persists from the canonical registry, stop and escalate to the user — do not "fix" the hash.
- Never set bypasses globally or persistently (in `.npmrc`, `pip.conf`, CI images, or shell profiles). A bypass that outlives the error disables verification for every future install nobody is watching.
- If the user explicitly directs a bypass for a controlled environment, scope it to the single command, state what protection is off while it runs, and leave nothing persistent behind.
- "The install must succeed" is never sufficient justification. An install that succeeds unverified has not succeeded; it has gambled.

**Red flags that you're about to violate this:**
- "It's a certificate issue; disabling strict-ssl is the standard workaround."
- "I'll add --trusted-host so pip stops complaining."
- "The integrity hash is stale; removing it will let the install proceed."
- "This is just a corporate proxy thing, not a real security problem."
- "I'll set the env var globally so this never blocks us again."

---

## Why It Works

1. **It reinterprets the error as a control firing**, not an obstacle malfunctioning. The AI's frame is "error blocks task"; the rule's frame is "alarm reports condition," which changes what counts as a fix.
2. **It supplies the legitimate fix for the most common trigger** — corporate proxy CA configuration — so the AI has a real path through the situation that produced the bypass instinct.
3. **It gives checksum mismatches an escalation protocol** ending at the human, because the rare true positive is exactly the case that must not be resolved by an assistant editing a hash at 2 a.m.
4. **It distinguishes scoped, disclosed, user-directed bypasses from silent persistent ones** — the lasting damage is almost always the forgotten global setting, and the rule targets persistence specifically.

## Origin

Blocked by TLS errors from a corporate proxy, an assistant set `strict-ssl false` in the project's `.npmrc` and committed it so "installs work for everyone." They did — unverified, for fourteen months, on every developer laptop and in CI. The setting was discovered during a security review, and because no one could prove what had been downloaded over that period, the remediation was rebuilding the dependency tree from a clean registry snapshot and auditing artifacts back through a year of releases. The correct fix on day one was pointing npm at the proxy's CA certificate: one line, no risk.

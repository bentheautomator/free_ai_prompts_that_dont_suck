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

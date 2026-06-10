### Prove the Config Value Is in Effect

NEVER claim a configuration value is active based on the file you edited. Claim it only after the running system has told you the value it is actually using.

The core problem: config resolves through layers — defaults, files, local overrides, environment variables, flags — and editing one layer proves nothing about which layer wins. The effective value is a property of the running system, not of any file.

- After changing config, get the effective value from the system itself: a startup log line that prints settings, a debug/health endpoint, a `--show-config` or `print-config` command, a REPL read of the live settings object, or observable behavior that only the new value could produce.
- Check for shadowing before trusting any file edit: environment variables, `.env` and `.local` variants, profile- or environment-specific sections, deploy manifests, and CLI flags can all override what you wrote.
- Verify the key name, not just the value. A misspelled key throws no error in most systems; it is simply ignored and the default applies. Silence is not acceptance.
- Confirm the system reread its config after your change (restart or documented reload) — and then still check the effective value, because reload and resolution are separate failure points.
- If you cannot query the effective value, scope the claim: "the file now sets X to Y; confirm the running value with <command>."

**Red flags that you're about to violate this:**
- "The value is right there in the file, that's what it'll use..."
- "This is the main config; nothing else would override it..."
- "No error on startup, so the new setting was accepted..."
- "I'll assume standard precedence rather than checking it..."
- "The key name looks right — close enough to the docs..."

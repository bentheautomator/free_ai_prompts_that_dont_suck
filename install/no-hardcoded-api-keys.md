### Never Hardcode API Keys or Secrets in Source

NEVER write a real credential into a source file. Not temporarily, not commented out, not as a default value, not in a test. Credentials come from the environment or a secrets manager, full stop.

A secret in source enters git history, and git history is forever. Deleting the line later does not unleak it.

- If the user pastes a key into the chat, do not echo it into code. Read it via `os.environ["API_KEY"]` / `process.env.API_KEY` and tell the user to set it (or add it to a gitignored `.env`).
- Fail loudly when the variable is missing: raise at startup with a clear message. Do not fall back to a hardcoded default like `os.environ.get("KEY", "sk-...")` — the fallback is the leak.
- In tests, use obviously fake values (`"test-key-not-real"`) or fixtures injected by the test runner. Never copy a working key into a test to make it pass.
- In examples, docs, and scaffolded configs, use placeholders that cannot work: `<YOUR_API_KEY>`, not a realistic-looking value.
- Database URLs, signing secrets, SMTP passwords, and webhook secrets are all credentials, not just things named "api_key."
- If you find an existing hardcoded secret while working, flag it: it needs rotation, not just removal, because history already has it.

**Red flags that you're about to violate this:**
- "I'll put the key inline for now so we can verify the integration works..."
- "It's a private repo, nobody outside the team can see it..."
- "I'll add a TODO to move it to env vars before release..."
- "This is just a local script, it won't be committed..."
- "A default value makes the code work out of the box..."
- "It's only the staging key, not production..."

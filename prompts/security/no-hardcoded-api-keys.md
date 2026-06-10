---
title: Never Hardcode API Keys or Secrets in Source
slug: no-hardcoded-api-keys
category: security
tags: [universal, security, secrets]
works_with: all
severity: critical
one_liner: "AI pasting API keys and passwords inline as a temporary measure"
---

# Never Hardcode API Keys or Secrets in Source

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from embedding credentials directly in code, even as placeholders that get filled in.

**[Copy-paste ready version](../../install/no-hardcoded-api-keys.md)** — just the instruction block, no explanation.

## The Problem

You paste an API key into the chat so the assistant can test an integration. Thirty seconds later that key lives in `client.py` as `API_KEY = "sk-live-..."`, because inlining it was the shortest path to a working call. Or the AI scaffolds a config file with `password: "changeme123"` and a real database URL, "to be replaced before deploy." Either way, a credential is now in source, one `git add .` away from being in history forever.

Assistants do this because the secret is right there in context and using it directly produces immediately runnable code. Indirection through an environment variable adds a step that can fail (`KeyError: 'API_KEY'`), and AIs optimize for code that runs on the first try. The cost lands later: secrets in git history survive deletion, get cloned onto every laptop, leak through CI logs, and are harvested by scanners within minutes of a public push.

The pattern also includes the sneaky variants: secrets in test fixtures, in docstrings as "example" values that are actually real, in commented-out debug code, and in default parameter values.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It blocks the echo path.** The highest-risk moment is when a real key is in the conversation context. Explicitly forbidding the AI from writing context-provided secrets into files addresses the exact mechanics of the failure.

2. **It removes the "temporary" frame.** The AI genuinely intends the inline key to be short-lived. Stating that history makes every commit permanent reframes "temporary" as a category error.

3. **It bans the fallback-default pattern.** `env.get(KEY, "real-value")` looks responsible because it mentions the environment. Naming it as a leak closes the most plausible-looking variant.

4. **It mandates rotation on discovery.** Without this, the AI "fixes" found secrets by deleting the line, which fixes nothing.

## Origin

During an integration spike, a developer pasted a payment provider's live secret key into the chat and asked the assistant to wire up a charge flow. The assistant helpfully inlined the key so the example would run, the file was committed in a WIP branch, and the branch was pushed to a public fork by a contractor. The key was used for fraudulent charges before the provider's own scanner revoked it. Total time from push to abuse: under an hour.

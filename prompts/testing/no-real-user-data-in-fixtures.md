---
title: No Real User Data in Fixtures
slug: no-real-user-data-in-fixtures
category: testing
tags: [universal, testing, fixtures]
works_with: all
severity: critical
one_liner: "AI copying production records, PII, and live keys into committed test fixtures"
---

# No Real User Data in Fixtures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents real customer records, emails, tokens, and keys from being baked into version-controlled test data.

**[Copy-paste ready version](../../install/no-real-user-data-in-fixtures.md)** — just the instruction block, no explanation.

## The Problem

The AI needs realistic test data and realistic data is lying around: a production bug report with the actual failing record attached, a log excerpt pasted into the conversation, a `.env` visible in the workspace, a database the AI can query. So the fixture file gains a real customer's name, real email, real address — or a JSON blob lifted from a debugging session with a live bearer token still inside — and gets committed. Git never forgets. That fixture now replicates into every clone, every fork, every laptop, and every CI log that prints test data on failure. If the repo ever goes public or the history gets scanned, it's a disclosure incident with a timestamp proving how long it sat there.

The mechanism is mundane: an AI reproducing a reported bug has the real failing record in context, and the shortest path to a regression test is pasting that record in verbatim. Sanitizing it is an extra step serving a concern — data governance — that nothing in the immediate task surfaces. Real tokens are worse than PII: a fixture containing a live API key isn't just embarrassing, it's an open door, and "but it's in the test directory" has never once mattered to an attacker running a secrets scanner over public commits.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Real User Data in Fixtures

NEVER put real personal data, real credentials, or records copied from production into test fixtures, seed data, or test code. Committed test data is permanent, replicated, and eventually public — treat every fixture as if it will be read by strangers, because via git history, it can be.

The core problem: real data enters tests through the path of least resistance — bug reports, logs, pasted records, visible env files — and once committed, it cannot be reliably recalled.

Rules:
- Fixtures use obviously fake identities: `test-user-1@example.com` (RFC-reserved domains: example.com/.org/.net), names like "Test Testerson," phone numbers from reserved ranges (e.g., 555-01XX), addresses that don't geocode to a real residence
- Credentials in fixtures must be syntactically valid but inert: `sk_test_` style markers, `"FAKE-TOKEN-FOR-TESTS"`, locally generated throwaway keys. NEVER copy a value from an env file, a config, a log line, or the conversation into a fixture — if it ever worked anywhere, it doesn't belong in a test
- When reproducing a production bug, extract the *structure* that triggers it (field lengths, unicode, null pattern, nesting) and rebuild it with fake values. The bug lives in the shape, not in the customer's actual name
- Card numbers, SSNs, government IDs: only documented test values (e.g., 4242 4242 4242 4242-class numbers), never anything observed in real traffic
- If you encounter existing fixtures containing what looks like real PII or live secrets, flag it to the user immediately — including the git-history implication — rather than building more tests on top of it
- Realism that matters for tests is structural (edge-case shapes, encodings, lengths), and fake data can carry all of it

**Red flags that you're about to violate this:**
- "I'll use the actual record from the bug report so the repro is faithful..."
- "This API key is already in the .env file, the fixture can reference the same value..."
- "It's just one customer's email, and it's only test data..."
- "Sanitizing the dataset will change the repro conditions..."
- "The repo is private, so committed test data is safe..."

---

## Why It Works

1. **It severs the repro shortcut.** The dominant entry path is verbatim-pasting the failing record. "Extract the structure, rebuild with fake values" gives a concrete alternative that preserves the only property the test needs — the triggering shape — so fidelity stops justifying contamination.

2. **It kills the private-repo comfort.** "It's only test data in a private repo" is the rationalization that approves the commit. Naming git permanence, forks, CI logs, and history scanners replaces that comfort with an accurate threat model.

3. **It supplies the inert vocabulary.** example.com, 555 numbers, documented test cards, `sk_test_` markers — having ready-made fake-but-valid values removes the friction that made real data the easy choice.

## Origin

A bug repro request — "this customer's import fails, here's the row" — led an assistant to commit the row verbatim as a fixture: full name, home address, national ID number. It passed review inside a 600-line test diff. Fourteen months later the company open-sourced the tool, history included, and a researcher found the record within days. The disclosure notification, regulatory filing, and history rewrite cost incomparably more than the fake address that would have triggered the same parser bug.

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

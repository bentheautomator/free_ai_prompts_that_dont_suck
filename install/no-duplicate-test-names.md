### No Duplicate Test Names

NEVER add a test whose name already exists in the same file or class. In Python, the new definition silently replaces the old one — adding a test can delete a test, with no error and no diff line showing the loss.

The core problem: appending is how tests get added, and natural names collide. A shadowed test stops being collected entirely; the suite stays green because the alarm wasn't triggered — it was unplugged.

Rules:
- Before adding a test, search the file (and its class) for the name you're about to use — and for the behavior you're about to cover. Grep the test name; don't trust that you'd have noticed
- If the name exists, first decide whether the existing test already covers your case. The right move may be extending it or adding a distinct case, not writing a near-twin
- If you genuinely need a new test of similar intent, differentiate the name by what's different about the case: `test_validates_email_rejects_missing_at` vs `test_validates_email_accepts_subdomains` — specific names prevent the next collision too
- After adding tests, verify the collected count went UP by the number you added (`pytest --collect-only -q | tail`, compare runner totals). Same count after adding two tests means something got shadowed
- In JS/parameterized frameworks, the same discipline applies to `it()` descriptions and parametrize IDs: duplicate names break filters, reporters, and snapshot keys even when both tests run
- When you find an existing duplicate pair, flag it — one of them has been dead, and which one matters

**Red flags that you're about to violate this:**
- "I'll add the new test at the bottom, the natural name is test_validates_email..."
- "This file is huge, I'll just append without reading the whole thing..."
- "The diff is purely additive, so nothing can have been lost..."
- "If a name collided, the runner would error..."
- "Test counts bounce around anyway, no need to compare totals..."

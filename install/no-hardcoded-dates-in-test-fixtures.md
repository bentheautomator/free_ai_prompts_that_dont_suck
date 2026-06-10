### No Hardcoded Dates in Test Fixtures

NEVER write a test whose outcome depends on the real current date or time. Any test mixing a hardcoded date literal with the live clock is a scheduled failure.

The core problem: a fixture date that means "recent" or "expired" *today* stops meaning that as the calendar moves, and the test fails later on an unrelated change.

Rules:
- Control the clock: freeze time with the framework's tool (`jest.useFakeTimers().setSystemTime(...)`, `freezegun.freeze_time(...)`, `time-machine`, injected clock) and write fixtures relative to the frozen moment
- If freezing isn't available, compute fixture dates from now (`now - 5 days`, `now + 1 year`) so their meaning is stable — never mix computed-from-now dates with literal dates in the same logic
- Hardcoded date literals are fine only when the test never consults the real clock: pure formatting/parsing tests, or fully frozen-time tests
- Watch the boundary cases you create: a fixture at exactly 30 days hits off-by-one differently depending on time of day. Place fixtures clearly inside or outside windows, and add explicit boundary tests with frozen time
- Treat "far future" literals (`2030-01-01`) as hardcoded dates too — they expire, just slower
- When you see an existing test fail on date math you didn't touch, say so: it's a time bomb to defuse, not a regression from the current change

**Red flags that you're about to violate this:**
- "I'll use today's date for the created_at field, it's realistic..."
- "2027 is far enough in the future, this'll never matter..."
- "The test passes now, the date logic must be fine..."
- "Freezing time is overkill for one little fixture..."
- "I'll just subtract a few days from new Date() right here inline..."

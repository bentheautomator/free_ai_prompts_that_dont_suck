### Python Aware Datetimes Only

ALWAYS create timezone-aware datetimes in Python. NEVER use bare `datetime.now()` or `datetime.utcnow()` — both return naive objects that mean different instants on different machines and that cannot be safely compared, serialized, or converted.

- Right: `datetime.now(timezone.utc)` (from `datetime import datetime, timezone`) for "the current instant."
- Wrong: `datetime.utcnow()` — correct UTC value, but naive, so the UTC-ness is lost the moment it leaves the variable. It is deprecated; do not generate it even though training examples are full of it.
- Wrong: `datetime.fromtimestamp(ts)` — uses the server's local zone; use `datetime.fromtimestamp(ts, tz=timezone.utc)`.
- When parsing, attach the zone: `datetime.fromisoformat(s)` keeps an offset if the string has one; if the string is naive, you must decide and document what zone it represents — don't guess silently.
- Store and compute in UTC; convert to local time only at the display edge with `.astimezone(ZoneInfo("Europe/Berlin"))`.
- Naive datetimes are acceptable only for genuinely zone-free concepts (a recurring "9:00 AM" alarm, a date of birth) — leave a comment when you use one deliberately.
- Never mix: comparing or subtracting naive and aware datetimes raises `TypeError`. If you hit that error, fix the naive side; don't strip tzinfo from the aware side.

**Red flags that you're about to violate this:**

- "`datetime.now()` is the standard way to get the current time."
- "`utcnow()` is the safe version, that's what the name says."
- "The server runs in UTC anyway, so naive is effectively aware."
- "I'll strip tzinfo so the comparison stops raising TypeError."
- "Timezone handling is out of scope for this small helper."

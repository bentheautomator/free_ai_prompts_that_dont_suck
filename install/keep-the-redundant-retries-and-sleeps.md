### Keep the Redundant Retries and Sleeps

NEVER delete a retry, sleep, delay, re-read, or double-check around an external interaction because it looks unnecessary. In legacy code these are absorbers: each one neutralizes a real quirk in a vendor API, a consistency model, or a race that someone diagnosed in production. They look pointless *because they are working*.

Before removing or "simplifying" any defensive timing code:

- `git blame` it. Defensive code added in a small, standalone commit — especially with words like "intermittent," "flaky," "vendor," or a ticket number — is a documented incident response. It stays.
- Identify what it touches. A sleep before a vendor poll, a retry around a third-party call, a read-back after a write to an eventually-consistent store: the proximity to an external boundary is the tell that it absorbs that boundary's behavior.
- Don't be fooled by passing tests. The quirk these constructs absorb lives in production infrastructure you cannot reproduce locally; green CI is evidence of nothing here.
- If the construct is genuinely problematic (blocking a hot path, masking errors), propose a like-for-like replacement that preserves the absorption — backoff instead of fixed sleep, bounded retry with logging — and say what quirk you believe it handles.
- If you can't determine what it absorbs, leave it and flag it. "Unexplained defensive code at a vendor boundary" defaults to load-bearing.

**Red flags that you're about to violate this:**
- "This sleep is obviously a hack someone forgot to remove."
- "The client library already retries, this loop is redundant."
- "Reading the row back right after writing it is pointless."
- "This API is reliable, the error handling here is paranoid."
- "All tests pass without the delay, so it wasn't doing anything."
- "I'll drop these while I'm restructuring the function."

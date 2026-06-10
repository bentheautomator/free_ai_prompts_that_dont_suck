### Drop Stale Responses in UI State

ALWAYS guard response handlers that write UI state: before applying a response, verify it belongs to the *latest* request for that piece of state. Responses arrive in any order; last-write-wins means slowest-write-wins.

- Abort the previous request when issuing a new one for the same state: keep an `AbortController` per fetch target, `abort()` it on re-fetch, and ignore `AbortError`. Cancellation beats checking, because it also stops wasted work.
- Where you can't abort, version-check: capture a request ID or the query value when the request starts; in the handler, `if (requestId !== latestRequestId) return;` before any `setState`.
- In effect-based frameworks, use the cleanup function: set a `cancelled` flag in React's `useEffect` cleanup and check it before applying the response. A fetch in an effect without a cleanup guard is a race by default.
- The guard must cover *all* the state the handler writes — results, loading flags, and error banners. A stale request's error overwriting a fresh success is the same bug in a trench coat.
- Don't debounce as a substitute. Debouncing reduces how often the race runs; it doesn't make any ordering guarantee. You can have both; you can't have only debounce.
- Prefer a data-fetching layer that handles this (query libraries with key-based caching and cancellation) over hand-rolling the guard in every component.

**Red flags that you're about to violate this:**
- "Responses will come back in the order I sent them."
- "The debounce means there's only ever one request in flight."
- "This effect refetches on every keystroke; the latest render wins anyway."
- "It works perfectly in dev." (Localhost never reorders.)
- "Adding request tracking to this little component is overkill."

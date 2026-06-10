### Avoid Catastrophic Regex Backtracking

NEVER apply a regex with nested quantifiers, quantified groups containing quantifiers, or overlapping alternations to user-controlled input. On a backtracking engine these patterns take exponential time on inputs that nearly match, and one crafted string can peg a CPU core for minutes.

The danger shapes, learn them on sight: `(x+)+`, `(x*)*`, `(x+)*`, `(x|xy)+`, `(\s*,\s*)*`, and any group where the same character could be consumed by either of two adjacent quantifiers (`\w+\s?` repeated, `.*.*`).

- Make repetition unambiguous: each character of input should have exactly one way to be consumed. Prefer explicit character classes with single quantifiers (`[\w.+-]+@[\w-]+\.[\w.]+`) over quantified groups of quantified things.
- Anchor patterns and bound repetition where the domain allows (`{1,64}` instead of `+` for an email local part). Bounded repetition caps the search space.
- Length-limit the input before the regex runs. A 100-character cap turns a theoretical exponential into a non-event.
- Where available, prefer a non-backtracking engine for user input: RE2, Rust's `regex`, Go's `regexp`, .NET's `NonBacktracking` flag, or a regex timeout if the platform offers one.
- Often the honest fix is not using a regex: `split`, `startsWith`, or a real parser for emails/URLs (the platform has one).
- Verify with a near-miss test: run the pattern against a long input that almost matches (e.g., 50 repetitions of the repeated unit plus one breaking character) and assert it completes in milliseconds. Matching valid input fast proves nothing; failing fast is the property under test.

**Red flags that you're about to violate this:**
- "This regex passes all the test cases."
- "Nesting the group keeps the pattern readable."
- "Nobody would ever input a string like that."
- "Regex performance is the engine's problem."
- "I'll combine these two patterns into one with an outer `+`."
- "It's just a validation regex, how slow can it be?"

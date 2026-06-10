### Python Strip Is Not Remove Prefix

NEVER use `strip()`, `lstrip()`, or `rstrip()` with a multi-character argument to remove a prefix or suffix. The argument is a character *set*, not a substring: `"production".lstrip("prod")` returns `"uction"`, and `"door".rstrip("or")` returns `"d"`.

- Right: `s.removeprefix("https://")` and `s.removesuffix(".py")` (Python 3.9+). These remove the exact substring once, or return the string unchanged.
- Pre-3.9 fallback: `s[len(p):] if s.startswith(p) else s` — write the conditional; do not reach for strip.
- `strip()` with no argument (whitespace) is fine and idiomatic. Single-character arguments like `s.strip('"')` are fine. The danger zone is exactly: multi-character argument intended as a substring.
- For path manipulation, don't strip extensions with string methods at all — use `pathlib`: `Path(name).stem`, `Path(name).with_suffix("")`.
- When you see `lstrip("http://")`, `rstrip(".json")`, or similar in existing code, treat it as a latent bug worth flagging even if you weren't asked to touch it — it corrupts only the inputs whose adjacent characters happen to overlap the set.
- Self-check before emitting `strip(x)` where `len(x) > 1`: do I mean "these characters" or "this substring"? If substring, switch methods.

**Red flags that you're about to violate this:**

- "`lstrip('https://')` removes the URL scheme — the name says strip from the left."
- "I tried it on one example and got exactly the prefix removed."
- "`rstrip('.py')` is shorter than slicing with startswith."
- "removeprefix might not exist in their Python version, so strip is safer."
- "The characters in the prefix are unlikely to repeat at the boundary."

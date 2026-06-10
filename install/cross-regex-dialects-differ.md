### Regex Dialects Are Not Portable

NEVER copy a regex between languages or tools as if it were plain data. Regex dialects differ in anchoring, escapes, character-class semantics, and supported features; a ported pattern can compile and silently match differently.

- On every port, re-verify three things: anchoring (Python `re.match` anchors at start, `re.fullmatch` both ends, JS/Go search anywhere — add explicit `^...$` or `\A...\z` per the target's rules), flags (how the target spells case-insensitive, multiline, dotall), and feature support.
- For validation, prefer explicit full anchors in the pattern itself rather than relying on the host function's anchoring behavior — it makes the intent portable.
- `$` is not "end of string" everywhere: in several engines it also matches before a final newline; use `\z` (or the target's equivalent) when trailing-newline acceptance matters, e.g. validating user input.
- Feature gaps: Go (RE2), POSIX `grep`/`sed`, and RE2-based services have no lookahead, lookbehind, or backreferences. Do not approximate such patterns — restructure the logic (multiple matches plus code) and say so.
- `\d`, `\w`, `\s` are Unicode-aware in some engines (Python 3) and ASCII in others (Go, JS without flags). If you mean `[0-9]`, write `[0-9]`.
- Shell contexts mangle patterns before the engine sees them: backslashes and `$` inside double quotes, BRE vs ERE in `grep` vs `grep -E`, `sed`'s escaping of `+` and `?` in BRE. Test the pattern *in* the shell context, not just in a regex playground set to PCRE.
- After porting, run the target-language pattern against a small fixture set including the edge cases: empty string, trailing newline, multiline input, non-ASCII digits/letters.

**Red flags that you're about to violate this:**

- "A regex is a regex; I'll reuse the one from the Python service."
- "It compiles in the new language, so the port worked."
- "re.match and string.match do the same thing."
- "I'll emulate the lookbehind with something close enough."
- "The playground says it matches." (The playground is running a different engine than your code.)

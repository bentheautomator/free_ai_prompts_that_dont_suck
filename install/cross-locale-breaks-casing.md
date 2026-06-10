### Locale Breaks String Casing

ALWAYS use locale-independent casing and formatting for machine-facing strings (protocol tokens, headers, extensions, enum/config keys, serialized numbers). Default casing and formatting follow the process locale, so the same code produces different bytes on different machines — the Turkish-İ bug.

- Java: `toLowerCase(Locale.ROOT)` / `toUpperCase(Locale.ROOT)`; `String.format(Locale.ROOT, ...)` for serialized numbers. Bare `toLowerCase()` on a token is a latent bug.
- .NET: `ToLowerInvariant()` / `ToUpperInvariant()`; compare with `StringComparison.OrdinalIgnoreCase`; format/parse with `CultureInfo.InvariantCulture`.
- Python/Go/JS default casing is not locale-driven (safer default), but JS has `toLocaleLowerCase` and Python has locale-aware formatting — don't reach for those for machine strings. For Unicode-correct case-insensitive matching of *human* text, use case folding (`str.casefold()` in Python), not lowercase.
- Case-insensitive token comparison shouldn't case-convert at all where an ordinal-ignore-case comparison exists (`equalsIgnoreCase` in Java is locale-safe for this; `strings.EqualFold` in Go).
- Serializing numbers and dates for files, APIs, and logs: always invariant/ROOT locale. `"1,5"` where a parser expects `"1.5"` is this bug in formatting clothes.
- Locale-aware casing and formatting are correct for text *displayed to users* — that's what the locale-sensitive APIs are for. The rule is about strings consumed by software.
- Don't fix this by setting the process default locale to English: that breaks actual localization and is a global mutable setting. Fix the call sites.

**Red flags that you're about to violate this:**

- "toLowerCase is a pure function of the string."
- "It passes on CI, casing is deterministic."
- "Nobody runs servers in a Turkish locale." (JVMs and desktops inherit OS locales everywhere your users are.)
- "I'll normalize with toUpperCase before comparing — uppercase is safe." (Turkish uppercases i to İ.)
- "I'll just set the default locale to en-US at startup."
- "%f formatting always uses a decimal point."

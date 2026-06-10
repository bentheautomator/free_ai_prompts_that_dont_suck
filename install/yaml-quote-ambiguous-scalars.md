### YAML Quote Ambiguous Scalars

ALWAYS quote YAML values that are strings but look like another type. YAML type-guesses unquoted scalars, and several legitimate strings parse as booleans, numbers, or null with no warning.

- Quote anything matching these shapes when a string is intended: `yes/no/on/off/y/n/true/false` in any case (`country: "NO"`), version-like numbers (`version: "1.10"` — unquoted it's the float `1.1`), leading-zero values (`mode: "0755"`, zip codes like `"02134"`), scientific-notation lookalikes (`"1e5"`), colon-separated times (`"12:30"`), and `null`/`~`.
- All-digit identifiers (phone numbers, account ids, some Git SHAs) must be quoted or they become integers — possibly losing leading zeros or precision.
- An empty value (`key:`) is `null`, not `""`. Write `key: ""` for empty string.
- Booleans and numbers that are MEANT to be booleans and numbers stay unquoted: `enabled: true`, `replicas: 3`. The rule is about strings in disguise.
- Never strip quotes from existing YAML as cleanup. A quote in a config file is load-bearing until proven decorative.
- When generating YAML programmatically, use a real YAML library, not string templating — templating an unquoted user-supplied value into YAML is both a coercion bug and an injection bug.
- Be alert in the usual blast zones: docker-compose/CI image tags (`image: postgres:9.6` is fine; `tag: 9.60` is the float trap), Kubernetes env vars (all values must be strings — unquoted `PORT: 8080` fails or coerces depending on tooling), Ansible/Helm values files, and country/language code lists.

**Red flags that you're about to violate this:**

- "Quotes around simple values are unnecessary noise in YAML."
- "I'll normalize this config by removing redundant quoting."
- "It's a version number, YAML will keep it as written."
- "The parser we use is YAML 1.2, the boolean thing is fixed." (Is every consumer of this file?)
- "Env var values are obviously strings, no need to quote 8080."

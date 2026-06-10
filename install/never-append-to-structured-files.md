### Never Append to Structured Files

NEVER append to a file in a structured format (JSON, XML, TOML, YAML, INI, HTML) with `>>` or any blind append. Insert at the structurally correct position instead.

Strict formats have closing delimiters and positional meaning; bytes after `}` or `</root>` invalidate the entire file, and "the end" is almost never where new content belongs.

- For JSON/XML/TOML: read the file, insert inside the correct object, array, or element, write the result. Better, use the format's own tooling: `npm pkg set`, `jq`, `yq`, `crudini` — they cannot produce unparseable output.
- For YAML and INI, position is semantics. A key appended at the bottom is top-level (YAML) or in the last section (INI), not where you intended. Insert under the right parent.
- True append-friendly formats exist: logs, JSONL/NDJSON, and usually CSV. Even there, confirm the file ends with a newline first, or your first appended record merges with the last existing one.
- Same rule for "prepend": shebang lines, XML declarations, BOMs, and `"use strict"` directives must stay first; never insert above them.
- After any structural edit, validate: `jq . file.json`, `python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))"`, `xmllint --noout`. One second of parsing beats a broken build.

**Red flags that you're about to violate this:**

- "Appending is safer because I'm not modifying existing content."
- "I'll echo the new entry onto the end; the format is forgiving." (JSON forgives nothing.)
- "It's just one config key, no need to parse the whole file."
- "The new YAML key can go at the bottom."
- "I'll skip validation; the change was tiny."

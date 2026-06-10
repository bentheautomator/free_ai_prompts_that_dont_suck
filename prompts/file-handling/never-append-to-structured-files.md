---
title: Never Append to Structured Files
slug: never-append-to-structured-files
category: file-handling
tags: [universal, files, parsing]
works_with: all
severity: high
one_liner: "Stops blind appends from corrupting JSON, XML, and other strict formats"
---

# Never Append to Structured Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tacking content onto the end of files whose format has a closing delimiter or strict structure, producing a file that no longer parses.

**[Copy-paste ready version](../../install/never-append-to-structured-files.md)** — just the instruction block, no explanation.

## The Problem

Appending feels safe — you're not touching anything that exists. But `package.json` ends with `}`, `pom.xml` ends with `</project>`, and a SQL dump may end mid-transaction. Anything appended after the closing delimiter makes the whole file invalid: `npm` refuses to start, the XML parser throws at the first character past the root element, and now the build is down because of an "additive" change. The shell makes this a one-character mistake: `echo '"newDep": "1.0"' >> package.json` is syntactically plausible and structurally fatal.

The subtler variants hurt too. Appending a key to YAML lands it at top level when it was meant to be nested. Appending to an INI file lands the key in whatever `[section]` happens to be last. Appending a row to a CSV without checking the trailing-newline state glues it onto the previous record. Assistants reach for append because it avoids reading the file and computing an insertion point — exactly the work that strict formats require.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reframes append as a structural operation, not a textual one.** The assistant's mental model ("adding is non-destructive") is exactly wrong for delimiter-closed formats, and the rule states the inversion plainly: bytes after the closer destroy everything before it.
2. **Format-native tools are offered as the cheaper path.** `npm pkg set` and `jq` are less work than computing an insertion point by hand, so the rule lowers effort instead of raising it.
3. **Post-edit validation is a one-command oracle.** Whether a file parses is not a judgment call; `jq .` answers it before the broken file reaches the build.

## Origin

A dependency bump was applied by appending a new entry after the final `}` of a service's `package.json` via shell redirection. Local docker cache hid it for one build; the next clean build failed with `Unexpected token` in a file nobody remembered touching, taking the deploy queue down for an hour while the team diffed a config file character by character.

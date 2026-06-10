---
title: Match File Extensions to Content
slug: match-extension-to-content
category: file-handling
tags: [universal, files, tooling]
works_with: all
severity: medium
one_liner: "Stops files whose extension lies about their format to every tool downstream"
---

# Match File Extensions to Content

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents writing files whose extension doesn't match their actual content, breaking every tool that dispatches on the suffix.

**[Copy-paste ready version](../../install/match-extension-to-content.md)** — just the instruction block, no explanation.

## The Problem

An assistant writes JSON content with comments and trailing commas into a `.json` file — that's JSON5/JSONC, and `JSON.parse` and `jq` will reject it cold. Or it saves a YAML-formatted config as `.json` because the neighboring configs are JSON. Or shell commands go into `setup.txt`, a TypeScript module into `.js` (type annotations are syntax errors there), Markdown into `.md` that's actually templated Jinja, or a JSONL stream into `.json` (a multi-object file that no JSON parser accepts). The file's name now lies, and everything downstream believes the name: editors pick the wrong syntax mode, linters apply the wrong rules, build pipelines route it to the wrong loader, and parsers fail with errors that point at the content when the bug is the suffix.

Extensions are dispatch keys, not decoration. Webpack chooses loaders by them, pytest and Jest discover by them, GitHub renders by them, `file`-type associations execute by them. An extension/content mismatch is a typo in a routing table — cheap to make, expensive to trace, because the error always surfaces somewhere other than the filename.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match File Extensions to Content

ALWAYS make the extension tell the truth about the format. Every downstream tool — parsers, loaders, linters, editors, test discovery — dispatches on the suffix and trusts it completely.

- The strict ones bite hardest: `.json` means strict JSON — no comments, no trailing commas, one top-level value. Comments need `.jsonc`/`.json5` (only if a consumer actually supports it); line-delimited records need `.jsonl`/`.ndjson`.
- Don't follow directory peer pressure: content in format X gets X's extension even if every sibling file is format Y.
- Executable content gets an executable's extension: shell scripts are `.sh` (or extensionless with a shebang), not `.txt`. Python is `.py`, not `.txt` "notes that happen to run."
- `.ts` vs `.js`, `.tsx` vs `.jsx`, `.scss` vs `.css`: these are different languages to the toolchain. Type annotations in a `.js` file and JSX in a `.js` file (in configured-strict projects) are build failures.
- Templated files name both layers: `config.yaml.j2`, `index.html.erb` — naming it `.yaml` invites someone (or some tool) to parse the template syntax as YAML.
- Honor project-specific conventions you observe (`.spec.ts` vs `.test.ts`, `.module.css`) — these suffixes trigger different pipelines, not just different names.
- Before finishing, sanity-parse anything you created: `jq . <file>.json`, `bash -n <file>.sh`, a YAML load. If the canonical parser rejects it, the content or the name is wrong; fix whichever lies.

**Red flags that you're about to violate this:**

- "I'll add a few comments to this .json config for clarity."
- "The other configs here are .json, so this one should be too." (It's YAML.)
- ".txt is fine; the user will know to run it as a shell script."
- "It's mostly JSON." (Parsers don't grade on a curve.)
- "The extension is cosmetic."

---

## Why It Works

1. **It states the dispatch-key model plainly:** tools route on suffixes with zero content sniffing, so a mismatch isn't a labeling quibble — it's a guaranteed misroute in every pipeline the file enters.
2. **The JSON-comment case is called out by name** because it's the single most common instance: the assistant adds helpful comments, and the helpfulness is a parse error.
3. **The canonical-parser check is a one-command truth test.** The file's name makes a claim; `jq`/`bash -n`/a YAML load verifies the claim before any downstream consumer has to discover it's false.

## Origin

A deployment config was written as `settings.json` with explanatory `//` comments above each block — genuinely good comments. The Node service read it with `JSON.parse` and crashed on boot in staging with `Unexpected token /`. The engineer who debugged it read the config four times without seeing a problem, because every editor on the team had silently switched that buffer to JSONC mode and highlighted the comments as perfectly legal.

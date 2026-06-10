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

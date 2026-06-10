---
title: Never Redirect Output Into the Input File
slug: never-redirect-output-into-the-input-file
category: code-safety
tags: [universal, files, shell]
works_with: all
severity: high
one_liner: "AI truncating a file by writing a command's output back onto its own input"
---

# Never Redirect Output Into the Input File

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from zeroing out a file by piping a transformation of it back into itself.

**[Copy-paste ready version](../../install/never-redirect-output-into-the-input-file.md)** — just the instruction block, no explanation.

## The Problem

`sort data.csv > data.csv` produces an empty file, every time. The shell opens the redirect target for writing — truncating it to zero bytes — *before* `sort` ever reads it. The same ambush works with `grep -v pattern log.txt > log.txt`, `jq '.items' config.json > config.json`, and `uniq names.txt > names.txt`. The command looks like an elegant in-place transformation. It is a deletion with extra steps.

AI assistants generate this pattern because it reads correctly: take the file, transform it, put it back. The truncation-before-read ordering is shell plumbing the model knows about in the abstract but doesn't apply when composing a quick one-liner. The script-language version of the bug is just as common: open a file for writing (`open(path, "w")`), planning to write back processed content, then crash or hit an exception after the truncation but before the write. Either way, the input is gone, and if the file wasn't in version control, it's gone for good.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Redirect Output Into the Input File

NEVER redirect a command's output to the same file it reads. The shell truncates the redirect target to zero bytes *before* the command runs — `sort file > file` empties the file instead of sorting it.

The core problem: "read, transform, write back" looks like one safe operation, but the write-back destroys the input before the read happens. The result is not a transformed file; it's an empty one.

- ALWAYS transform via a temporary file, then move into place: `sort data.csv > data.csv.tmp && mv data.csv.tmp data.csv`. The `&&` matters — only replace the original if the transform succeeded.
- Watch for the pattern in every form: `>` redirects, `tee` back to the source, pipelines ending where they began, `jq ... config.json > config.json`.
- In scripts, never `open(path, "w")` on a file whose current contents you still need. Read fully first, or better, write to `path + ".tmp"` and rename after a successful write.
- Use in-place modes only when you've verified the tool buffers properly: `sort -o file file` is safe; `sed -i` is safe; a generic `cmd file > file` never is. When unsure, use the temp-file pattern — it's always correct.
- Before any "transform in place" on an unversioned or hard-to-recreate file, keep a backup copy until the result is verified.

**Red flags that you're about to violate this:**
- "I'll just filter the file and write it back in one line..."
- "Redirecting to the same name keeps things tidy..."
- "jq the config and overwrite it, simple..."
- "A temp file is overkill for this..."
- "I'll open it for writing and then process the contents..."

---

## Why It Works

1. **It teaches the mechanism, not just the rule.** "The shell truncates before the command runs" gives the AI a causal model, so it recognizes the trap in novel shapes (`tee`, script file handles) instead of pattern-matching one forbidden string.

2. **It supplies the universally safe substitute.** Temp-file-then-rename costs nothing and is always correct, removing any efficiency rationale for the one-liner.

3. **It conditions replacement on success.** The `&&` detail means a failed transform leaves the original intact — covering the script-crash variant where truncation happens but the write never lands.

## Origin

An assistant tidying a dataset ran `jq 'del(.debug)' records.json > records.json` on a 300 MB file that had taken a day of API scraping to assemble. The file was zero bytes before jq read its first character. The directory wasn't under version control — it was data, who versions data? — and the re-scrape ran overnight while everyone thought about temp files.

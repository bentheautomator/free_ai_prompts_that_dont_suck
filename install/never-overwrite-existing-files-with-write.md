### Never Overwrite Existing Files With Write

NEVER replace an existing file with a full-file write when a targeted edit will do. A whole-file write deletes everything you did not include — including content you never read or no longer remember accurately.

The core problem: full rewrites feel equivalent to edits, but an edit can only damage the lines it touches, while an overwrite silently destroys every line missing from your version.

- ALWAYS use targeted edit operations (string replacement, patch, diff-based edits) to modify existing files.
- Before any full-file write to an existing path, read the complete current file in this same step — not from memory of an earlier read.
- If a file is too large to read fully, that is a reason to edit, never a reason to rewrite.
- Full-file writes are acceptable only for: brand-new files, files you created in this session, or when the user explicitly asks for a complete rewrite — and even then, read the current version first.
- If an edit operation fails because your anchor text doesn't match, re-read the file and fix the anchor. Do not fall back to "I'll just write the whole thing."
- After writing any existing file, state what the file previously contained that your version intentionally drops. If the answer is "I'm not sure," you have already failed.

**Red flags that you're about to violate this:**
- "It'll be cleaner to just rewrite the whole file..."
- "My edit keeps failing to match, so I'll write it from scratch..."
- "I remember what this file looks like from earlier..."
- "The file is mostly my code anyway..."
- "I'll reconstruct the parts I didn't read — they were probably boilerplate..."

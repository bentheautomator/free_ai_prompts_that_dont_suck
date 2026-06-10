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

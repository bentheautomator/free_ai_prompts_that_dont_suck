### Never Edit Binary Files as Text

NEVER read, write, or string-replace a binary file with text tools. Binary formats have offsets, checksums, and length fields; a text-pipeline round trip corrupts them even when the visible change looks right.

- Check before touching anything that isn't clearly source/config: `file <path>` identifies the format; `grep -Il . <path>` (capital i, lowercase L) prints the name only for text. Extensions help but lie — check when in doubt.
- Binary includes the disguised cases: `.docx`/`.xlsx`/`.pptx` (zip archives), `.pdf`, `.sqlite`/`.db`, `.pyc`, `.class`, `.woff2`, `.ico`, pickles, protobuf blobs. "I can see strings in it" does not mean "I can edit strings in it."
- Modify binary formats with their own tooling: `sqlite3` for SQLite, `python-docx`/`openpyxl` for Office files, image libraries for images, `zip`/`tar` for archives. If no tool is available, say so — don't improvise with sed.
- Keep binaries out of bulk text operations: filter `find`-driven `sed`/replace runs by extension or by `grep -Il`, and never run "normalize line endings/whitespace" over a directory containing binaries.
- Copy binaries with byte-faithful tools (`cp`, `rsync`), never through text-mode reads, shell `$(cat ...)` capture, or anything that decodes.
- If you've already mangled one: restore from git or backup. There is no hand-fixing a corrupted binary.

**Red flags that you're about to violate this:**

- "I can see the string I need right there in the grep output."
- "It's mostly text with some weird characters."
- "sed across the whole directory will catch all the configs." (And the .png in the fixtures folder.)
- "The file still opens, so the edit worked." (Some formats fail lazily, on the page you didn't check.)
- "I'll just fix the byte I changed back." (The write already re-encoded the rest.)

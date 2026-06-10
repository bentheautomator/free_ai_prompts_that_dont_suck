### Respect Trailing Newline Discipline

Preserve each file's final-newline state exactly, unless changing it is the task. When creating files, end text files with exactly one newline.

The last byte is invisible in every rendered view and visible to git, linters, snapshot tests, and every line-oriented Unix tool.

- When editing the last line of a file, reproduce its terminator state: if the file ended with a newline, it still does; if it didn't, it still doesn't. `tail -c 1 <path> | xxd` settles any doubt.
- Watch the diff: a `\ No newline at end of file` marker appearing in (or disappearing from) `git diff` on a file where you didn't intend to touch the ending means you flipped it. Fix before finishing.
- New text files: one trailing newline, no more. Multiple blank lines at EOF are churn bait for formatters.
- Honor project config: if `.editorconfig` sets `insert_final_newline` or Prettier governs the file, follow it for new content but still don't mass-fix existing files you weren't asked to touch.
- Files compared byte-for-byte — golden files, snapshots, fixtures with `expected` in the name — are exact artifacts. Never "normalize" their endings; you'll fail the very tests they exist for.
- Shell heredocs and `printf`-composed files are easy to get wrong by one `\n`. Verify the last byte when composing files that other tools parse.

**Red flags that you're about to violate this:**

- "A missing final newline is a mistake; I'll fix it while I'm here."
- "That diff marker about no newline is noise."
- "One newline, two newlines, whatever ends the file."
- "Snapshot files are text like any other text."
- "The file looks identical, so it is identical."

### Preserve Line Endings When Editing

NEVER change a file's line endings unless changing line endings is the explicit task. An edit to line 40 must leave the line endings of lines 1 through 39 and 41 onward byte-identical.

Line endings are invisible in most views but fully visible to git, parsers, and interpreters. Normalizing them as a side effect turns a one-line fix into a whole-file diff and can break scripts outright.

- Before editing, detect what the file uses: `file <path>` or `grep -c $'\r' <path>`. Match it.
- If the file is CRLF, your new or edited lines must also be CRLF. Do not write LF lines into a CRLF file "because the diff will be normalized anyway" — check `.gitattributes` before assuming that.
- Shell scripts (`.sh`), shebang'd files, and Makefiles must stay LF. Windows batch files (`.bat`, `.cmd`) and some `.sln`/`.csproj` tooling expect CRLF. When creating a new file, follow the platform convention of its consumers, then `.gitattributes`, then the repo majority, in that order.
- After editing, verify the diff: if `git diff --stat` shows the whole file changed for a small edit, you almost certainly flipped line endings. Fix it before moving on, not after the user notices.
- A file with mixed line endings is suspicious but not yours to clean. Preserve the mix unless asked.

**Red flags that you're about to violate this:**

- "I'll normalize to LF while I'm in here; CRLF is legacy anyway."
- "The diff shows every line changed, but my edit is in there somewhere, so it's fine."
- "Git will sort out line endings on commit."
- "It's easier to rewrite the file with consistent endings than match the existing ones."
- "Nobody can see line endings, so nobody will care."

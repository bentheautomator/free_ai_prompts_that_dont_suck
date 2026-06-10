### Don't Clobber Files with Shell Redirection

NEVER redirect a pipeline's output onto its own input file, and never compose a multi-step file with a chain of `>`/`>>` commands when a single write will do.

`>` truncates the target before anything runs: self-redirection empties the input pre-read, and one wrong `>` mid-composition silently discards everything composed so far.

- To transform a file in place: write to a temp file and move it over (`sort data.txt > data.txt.tmp && mv data.txt.tmp data.txt`), or use the tool's in-place mode (`sort -o data.txt data.txt`, `sed -i`). NEVER `cmd file > file`.
- To create a file with known content, write it in one operation: a file-write tool, a single heredoc (`cat > out.txt <<'EOF' ... EOF`), or one `printf`. Multi-command `echo`-chains maximize the chances of a `>`/`>>` slip and leave a partial file if any step fails.
- Before any `>` aimed at an existing file, confirm overwriting is the intent. If you're adding, it's `>>`; if you're replacing, say so to yourself explicitly first.
- `set -o noclobber` in scripts you author makes accidental `>` over an existing file an error (`>|` to override deliberately).
- `tee` reads the same trap: `cmd file | tee file` clobbers too. And `2>file` versus `2>>file` follows the same append/truncate logic for logs.

**Red flags that you're about to violate this:**

- "I'll sort the file and write it right back to itself."
- "Building the file with a series of echo appends keeps each step simple."
- "I'm pretty sure I already wrote the header with >>." (Pretty sure is how files get zeroed.)
- "If I clobber it, I'll just regenerate it." (The input you'd regenerate from may be the thing you clobbered.)
- "It's just a redirect, what could it destroy?"

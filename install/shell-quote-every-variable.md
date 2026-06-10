### Shell Quote Every Variable

ALWAYS double-quote every variable and command substitution in shell: `"$var"`, `"$(cmd)"`, `"$@"`, `"${arr[@]}"`. Unquoted expansions undergo word splitting and glob expansion, so any value containing spaces, tabs, newlines, or `* ? [` becomes multiple arguments or a wildcard match.

- Wrong: `rm -rf $TMPDIR/build` — with a space in `TMPDIR` this deletes two paths, neither of them the right one. Right: `rm -rf "${TMPDIR}/build"`.
- Wrong: `[ $x = "ok" ]` — errors or misbehaves when `x` is empty or multi-word. Right: `[ "$x" = "ok" ]`, or use `[[ ]]` in bash (still quote for habit and copy-paste safety).
- Pass arguments through with `"$@"` (each argument preserved), never bare `$@` or `"$*"` (which joins them into one).
- Loop over command output with arrays or `while IFS= read -r line`, not `for f in $(ls)` — that splits on every space in every filename and glob-expands the pieces.
- Quote inside `${}` defaults too: `"${name:-default}"`.
- The few legitimate unquoted uses (deliberate globbing like `for f in *.log`, or intentional splitting of a flags variable) must be commented as intentional; better, use arrays for flag lists: `args=(-v --color); cmd "${args[@]}"`.
- Arithmetic contexts `$(( ))` and assignments `x=$y` are safe unquoted, but quoting them is harmless — when in doubt, quote.

**Red flags that you're about to violate this:**

- "This variable is a path I control, it'll never have spaces."
- "Quoting everything makes the script noisy; I'll quote where it matters."
- "It's a quick CI script, not production code." (CI deletes directories for a living.)
- "The original script didn't quote it and it works."
- "`$@` and `\"$@\"` are basically the same thing."
- "I'm just cleaning up the quoting style." (Removing quotes is never cleanup.)

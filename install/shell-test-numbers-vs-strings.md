### Shell Test Numbers vs Strings

ALWAYS match the comparison operator to the data type in shell tests: `=`/`!=` for strings, `-eq`/`-ne`/`-lt`/`-le`/`-gt`/`-ge` for integers. They are not interchangeable and the failure modes differ — wrong-typed integer ops error at runtime; wrong-typed string ops silently mis-compare values like `" 0"` vs `"0"`.

- Numeric tests: `[ "$count" -eq 0 ]`, or better in bash, arithmetic context: `(( count == 0 ))`, which is built for numbers and supports `<`, `>=` naturally.
- String tests: `[ "$mode" = "prod" ]`. Use single `=` in `[ ]` for portability; `==` is a bashism that breaks under `sh`.
- NEVER use `<` or `>` inside `[ ]` — they are parsed as redirections: `[ "$a" > "$b" ]` always succeeds and creates a file. Inside `[[ ]]` they compare *lexicographically*: `[[ 9 < 10 ]]` is false. For numeric order use `-lt`/`-gt` or `(( ))`.
- Sanitize before numeric comparison: command output like `wc -l` can carry whitespace. Strip it (`count=$(wc -l < file)`, or `count=${count//[[:space:]]/}`) or the integer ops will error on `" 42"` under some shells.
- Validate that a variable is actually numeric before `-eq` if it comes from user input or environment: `[[ "$n" =~ ^[0-9]+$ ]]`.
- Know your bracket: `[ ]` is POSIX and word-splits (quote everything); `[[ ]]` is bash/ksh/zsh-only, safer parsing, supports `=~`. Pick per script shebang and stay consistent.
- Empty/unset checks are string ops: `[ -z "$var" ]` / `[ -n "$var" ]`, always quoted.

**Red flags that you're about to violate this:**

- "`==` works for comparing anything."
- "I'll use `>` to compare the version numbers." (Lexicographic: `9 > 10`.)
- "These are numbers, but `=` compares them fine." (Until the formatting differs.)
- "The test errored, but the else-branch handled it." (The else-branch ran *because* it errored.)
- "`[` and `[[` are the same thing with different spelling."

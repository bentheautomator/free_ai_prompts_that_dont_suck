### Shell set -e Has Blind Spots

NEVER treat `set -e` as complete error handling in shell scripts. Errexit is silently suspended in several constructs; handle those failure paths explicitly.

- Start scripts with `set -euo pipefail` (bash), but treat it as a backstop, not the strategy.
- `local var=$(cmd)` discards cmd's exit status — `local` returns 0. Split it: `local var` on one line, `var=$(cmd)` on the next; now the assignment's status is cmd's status and errexit can see it. Same for `export` and `declare`.
- Inside `if cond`, `while cond`, `! cmd`, and the left side of `&&`/`||`, failures do not trigger errexit — by design. If a function is called in a condition, its whole body runs with errexit off; keep such functions trivial or check statuses manually inside them.
- `set -u`: expanding an unset variable is fatal — this catches typos and missing environment that `set -e` never would. Use `"${VAR:?message}"` to demand required variables with a useful error.
- After a command whose failure needs cleanup or a specific message, check explicitly: `if ! cmd; then echo "..." >&2; exit 1; fi`. Explicit beats implicit for anything destructive.
- `cmd || true` disables checking for that command — only write it when failure is genuinely acceptable, with a comment saying why.
- Don't rely on errexit semantics being portable: `sh`/dash/old bash differ. Explicit checks are portable.

**Red flags that you're about to violate this:**

- "The script has `set -e`, so any failure stops it."
- "`local output=$(build)` — if build fails, we exit." (You don't.)
- "I'll wrap this in a function and call it from the if-condition." (Errexit is now off inside it.)
- "Adding explicit error checks is redundant with strict mode."
- "`|| true` here just keeps the script tidy."

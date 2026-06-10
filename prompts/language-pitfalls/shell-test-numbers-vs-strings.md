---
title: Shell Test Numbers vs Strings
slug: shell-test-numbers-vs-strings
category: language-pitfalls
tags: [universal, shell]
works_with: all
severity: high
one_liner: "Stops shell tests mixing -eq with strings and = with numbers"
---

# Shell Test Numbers vs Strings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `[ "$count" = "10" ]` failing on `" 10"` and `[ "$mode" -eq "prod" ]` erroring at runtime — shell comparison operators are typed, even though variables aren't.

**[Copy-paste ready version](../../install/shell-test-numbers-vs-strings.md)** — just the instruction block, no explanation.

## The Problem

Shell variables are all strings, but `test`/`[` operators are not interchangeable: `=`/`!=` compare strings, `-eq`/`-ne`/`-lt`/`-gt` compare integers. Mix them and you get two different failure flavors. `[ "$count" = "0" ]` is a *string* comparison, so when the command substitution produces `" 0"` (leading space, courtesy of `wc -l` on some platforms) or `"00"`, the test is false and the "empty" branch never runs. Going the other way, `[ "$env" -eq "prod" ]` is an integer comparison handed strings: it errors with "integer expression expected" — and in a script without strict error handling, the failed test just takes the else-branch.

Then there's the operator soup around it: `<` and `>` inside single brackets are *redirections* (`[ "$a" > "$b" ]` creates a file named after `$b` and evaluates true), and `==` inside `[ ]` is nonportable. Inside `[[ ]]`, `<`/`>` compare strings — lexicographically, so `[[ 9 < 10 ]]` is false.

Assistants mix these because in every other language `==` and `<` work on both types, and because shell snippets in training data use whichever operator the original author happened to know. The model ports `if (count == 0)` straight into whichever bracket dialect it last saw.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It restores the type system shell hides.** The model's prior from typed languages is "one set of comparison operators"; stating that shell's operators carry the types the variables lack corrects the actual misconception.
2. **It distinguishes the two failure flavors.** Loud (`integer expression expected`) vs silent (`" 0" != "0"`) failures need different vigilance; naming both stops the model from assuming a mis-typed test will at least announce itself.
3. **It bans the redirection trap outright.** `[ "$a" > "$b" ]` is syntactically valid, always true, and writes a file — no amount of "be careful" beats an explicit NEVER for that one.
4. **It adds the sanitization step.** Most real-world `-eq` failures are formatting (`wc -l` padding), not logic; including the strip idiom fixes the bug the operator rule alone wouldn't.

## Origin

A deployment gate checked replica health with `if [ "$healthy" = "$desired" ]` where both values came from different CLI tools — one emitted `3`, the other `  3` with column padding. The string comparison was never true, the gate concluded the cluster was never healthy, and deploys sat blocked for an afternoon while the on-call read and reread a comparison that was "obviously" correct. One `-eq` (plus a whitespace strip) fixed it.

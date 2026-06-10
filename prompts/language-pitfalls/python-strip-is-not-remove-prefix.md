---
title: Python Strip Is Not Remove Prefix
slug: python-strip-is-not-remove-prefix
category: language-pitfalls
tags: [universal, python]
works_with: all
severity: high
one_liner: "Stops str.strip('text') being used to remove a prefix or suffix"
---

# Python Strip Is Not Remove Prefix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `strip("prefix")` calls that eat arbitrary leading characters instead of removing a substring.

**[Copy-paste ready version](../../install/python-strip-is-not-remove-prefix.md)** — just the instruction block, no explanation.

## The Problem

`url.lstrip("https://")` reads like "remove the https:// prefix." It isn't. The argument to `strip`/`lstrip`/`rstrip` is a *set of characters*, and Python removes leading characters as long as they're in that set — in any order, any count. So `"https://stash.example.com".lstrip("https://")` doesn't stop after the scheme: `s`, `t`, `a`, `h`, `/`, `:`, `p`, `e` are all in the set, and you get `"ash.example.com"`. Worse, `"hello.py".rstrip(".py")` gives `"hello"` for some filenames and mangles others (`"happy.py"` becomes `"ha"`), so spot-checking one example "confirms" the broken code.

This is one of the most reliably hallucinated string operations in AI-generated Python, because the call *usually appears to work*: most test strings don't happen to start with extra characters from the set, so the bug passes review and fails on real data — IDs that start with the same letters as their prefix, filenames, branch names.

The actual prefix-removal methods, `removeprefix()` and `removesuffix()`, only arrived in Python 3.9, so decades of training data use `strip` workarounds instead.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Python Strip Is Not Remove Prefix

NEVER use `strip()`, `lstrip()`, or `rstrip()` with a multi-character argument to remove a prefix or suffix. The argument is a character *set*, not a substring: `"production".lstrip("prod")` returns `"uction"`, and `"door".rstrip("or")` returns `"d"`.

- Right: `s.removeprefix("https://")` and `s.removesuffix(".py")` (Python 3.9+). These remove the exact substring once, or return the string unchanged.
- Pre-3.9 fallback: `s[len(p):] if s.startswith(p) else s` — write the conditional; do not reach for strip.
- `strip()` with no argument (whitespace) is fine and idiomatic. Single-character arguments like `s.strip('"')` are fine. The danger zone is exactly: multi-character argument intended as a substring.
- For path manipulation, don't strip extensions with string methods at all — use `pathlib`: `Path(name).stem`, `Path(name).with_suffix("")`.
- When you see `lstrip("http://")`, `rstrip(".json")`, or similar in existing code, treat it as a latent bug worth flagging even if you weren't asked to touch it — it corrupts only the inputs whose adjacent characters happen to overlap the set.
- Self-check before emitting `strip(x)` where `len(x) > 1`: do I mean "these characters" or "this substring"? If substring, switch methods.

**Red flags that you're about to violate this:**

- "`lstrip('https://')` removes the URL scheme — the name says strip from the left."
- "I tried it on one example and got exactly the prefix removed."
- "`rstrip('.py')` is shorter than slicing with startswith."
- "removeprefix might not exist in their Python version, so strip is safer."
- "The characters in the prefix are unlikely to repeat at the boundary."

---

## Why It Works

1. **It corrects the lie in the method name.** The model maps `lstrip(x)` to "remove x from the left" — a natural-language inference the docs contradict. Stating the set semantics with a counter-example (`"door".rstrip("or")` → `"d"`) replaces the inference.
2. **It kills the single-example verification.** Most inputs survive the bug, so one successful test is meaningless; the instruction says so before the model runs that test.
3. **It scopes the ban precisely.** No-arg and single-char strip stay legal, so the model doesn't over-correct into rewriting legitimate whitespace trimming.

## Origin

An ingest script normalized bucket keys with `key.lstrip("s3://staging/")`. Keys beginning with letters from that character set — anything starting with `a`, `g`, `i`, `n`, `s`, `t`, or `/` after the prefix — were silently truncated, and about 4% of objects were written to mangled destination paths. The corrupted keys weren't discovered until a restore drill failed to find them three months later.

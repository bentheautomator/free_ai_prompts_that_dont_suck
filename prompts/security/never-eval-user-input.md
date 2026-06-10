---
title: Never Eval User Input
slug: never-eval-user-input
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI reaching for eval, exec, or new Function to parse user data"
---

# Never Eval User Input

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from running user-controlled strings through eval, exec, or dynamic code construction.

**[Copy-paste ready version](../../install/never-eval-user-input.md)** — just the instruction block, no explanation.

## The Problem

`eval` is the universal solvent of lazy parsing, and AI assistants reach for it whenever input looks vaguely like code: a calculator feature gets `eval(expression)`, a config value gets `eval(value)` to "handle any type," a dynamic filter gets `new Function("item", "return " + userRule)`, a stringified dict from a form gets `eval()` because `json.loads` choked on the single quotes. Each of these hands the user a full interpreter with your process's permissions. The calculator that evals `2+2` also evals `__import__('os').system('...')`.

The model produces this because eval genuinely is the shortest correct-looking solution to "turn this string into a value/behavior," and because tutorial-grade code uses it freely. The dressed-up variants are more dangerous than the bare ones precisely because they look engineered: a regex "sanitizer" before the eval (bypassable), `eval` with `{"__builtins__": {}}` (escapable via object traversal, famously so), `setTimeout(string)` and `vm.runInNewContext` in Node (the `vm` module is documented as not a security boundary), Python's `exec` for "dynamic method dispatch" that getattr would do safely.

Every legitimate use has a dedicated tool: JSON parsers for data, `ast.literal_eval` for Python literals, real expression-evaluator libraries for formulas, lookup tables for dispatch. The instruction's job is to make those the reflex.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Eval User Input

NEVER pass user-controlled strings to an interpreter. No `eval`, no `exec`, no `new Function`, no string-built code. Use the dedicated parser for whatever the input actually is.

Eval on user input is not a vulnerability that leads to code execution; it IS code execution, gift-wrapped.

- Banned with dynamic input: `eval()`/`exec()` (Python, JS, PHP, Ruby), `new Function(string)`, `setTimeout`/`setInterval` with string arguments, `vm.runInContext` as a "sandbox" (Node's vm module is explicitly not a security boundary), Ruby's `instance_eval`/`send` with user-derived names, PHP's `assert()` with strings.
- Parsing data: use `JSON.parse`/`json.loads`. Python-literal strings (single quotes, tuples): `ast.literal_eval`, which evaluates literals only. Never "fix" a JSON parse error by downgrading to eval.
- Math/formula features: use an expression-evaluator library with an explicit function allowlist (mathjs's limited evaluator, simpleeval, govaluate), or write a small parser. A calculator is a parser problem, not an interpreter problem.
- Dynamic dispatch ("call the method named in the request"): use an explicit dict/map of allowed names to functions. Not `getattr(obj, user_string)` unprefixed, not `globals()[name]`, not `obj[userKey]()` on a non-allowlisted object.
- Sanitizing input before eval does not make it safe: keyword blocklists and emptied `__builtins__` are bypassed via attribute traversal and encodings. If the design requires evaluating user code, that's a sandboxing project (separate process, seccomp/jail, time/memory limits) to raise to the user, not an inline decision.
- User-supplied regexes, format strings, and template strings are mini-interpreters of their own; treat "execute this user-provided pattern" with the same suspicion.

**Red flags that you're about to violate this:**
- "eval is the simplest way to support any expression the user types..."
- "I'll strip the word 'import' from the input first, then eval it..."
- "It's not JSON, it's Python-dict syntax, so json.loads won't work, but eval will..."
- "new Function gives the rule engine maximum flexibility..."
- "The vm module sandboxes it, so the eval is contained..."
- "Only our team writes these formulas, and they're not attackers..."

---

## Why It Works

1. **It maps each legitimate need to its real tool.** The AI evals because it wants parsing, math, or dispatch; handing it `literal_eval`, expression libraries, and lookup maps satisfies the need that was driving the violation.

2. **It demolishes the sandbox illusions by name.** Emptied `__builtins__`, keyword stripping, and Node's `vm` are the three "safe eval" myths the AI will otherwise deploy confidently; each is called out as bypassed.

3. **It catches the disguised evals.** `setTimeout(string)`, `assert()`, `send`, and `new Function` don't contain the letters e-v-a-l, which is exactly how they get past naive rules.

4. **It escalates the genuinely hard case.** "Run user code" is sometimes the actual product requirement; routing that to a deliberate sandboxing decision keeps the rule from being quietly broken to meet a feature request.

## Origin

A spreadsheet-style "computed column" feature needed to evaluate user formulas, and the assistant shipped `eval()` behind a regex that blocked the words `import`, `exec`, and `open`. A user discovered that `getattr(__builtins__, 'ex'+'ec')` wasn't on the list, achieving code execution on the worker fleet from a column definition. The rebuild used an expression library with thirty allowlisted functions; no formula any customer had written needed anything else.

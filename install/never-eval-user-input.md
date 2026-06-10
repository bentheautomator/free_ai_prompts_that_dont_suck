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

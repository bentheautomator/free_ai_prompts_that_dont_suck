### JS Optional Chaining Is Not Error Handling

Use `?.` ONLY where absence is an expected, valid state you are deliberately handling. NEVER use it to suppress a crash on data that is supposed to be there — that converts a located TypeError into silent `undefined` propagating through the system.

- Before writing `?.`, answer: per the data contract, can this legitimately be missing? If yes, `?.` plus an explicit fallback or branch. If no, access it plainly and let it throw, or validate at the boundary and fail with a real error.
- Wrong: `const city = order?.customer?.address?.city ?? ''` when orders always have customers — a broken join now ships blank labels. Right: `order.customer.address` (crash at the bug) or boundary validation that rejects the malformed order loudly.
- `??`/fallback values deserve the same scrutiny: a default is a decision about business behavior, not a crash-prevention tool.
- `callback?.()` silently skips required wiring. Only use it for genuinely optional hooks.
- Do not chain `?.` after the first one reflexively: in `a?.b.c`, if `a` exists then `b` is being asserted to exist — make that assertion match the contract instead of autocompleting `?.` onto every link.
- When unsure whether a field is optional, do not guess with `?.`. Check the type/schema/API docs, or validate explicitly and throw a descriptive error.
- TypeScript: fix the type or narrow it; using `?.` to silence a type error has the same downstream cost.

**Red flags that you're about to violate this:**

- "I'll add `?.` everywhere to be safe."
- "Better to render nothing than to crash."
- "I'm not sure if this field is optional, `?.` covers both cases."
- "The linter/types complained, `?.` makes it green."
- "This fixes the reported TypeError." (It hides it. The data is still wrong.)
- "Defensive coding is good practice."

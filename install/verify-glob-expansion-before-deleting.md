### Verify Glob Expansion Before Deleting

NEVER delete using a wildcard without first seeing exactly what it expands to. The shell expands globs against the real directory; you wrote yours against an imagined one.

The core problem: glob patterns routinely match more than intended — hidden surprises, directories matching file patterns, a stray space turning one argument into two — and `rm` executes the expansion, not the intent.

- Before any wildcard delete, expand the pattern visibly: `ls -d <pattern>` or `echo <pattern>`, and read the full list. Then delete that reviewed list.
- Quote and inspect arguments carefully. `rm fixtures/*.json` and `rm fixtures/ *.json` differ by one space and one catastrophe.
- List the directory first (`ls -la`) so you know what's actually there, including dotfiles and oddly named entries your pattern might catch.
- Prefer the most specific pattern that works: `rm ./build/*.o` over `rm *.o` over `rm *`. Anchor with explicit directories (`./`) rather than relying on cwd.
- Never combine an unverified glob with `-r` or `-f`. Recursion plus a wrong match is how single-file mistakes become directory-tree mistakes.
- If the expansion includes anything you didn't predict — even one entry — stop and resolve the surprise before deleting anything.

**Red flags that you're about to violate this:**
- "The pattern obviously only matches the build outputs..."
- "There's nothing else in that directory anyway..."
- "I'll add -f so it doesn't complain about non-matches..."
- "Expanding it first is an extra step for a one-liner..."
- "Wildcards are standard practice, this is fine..."

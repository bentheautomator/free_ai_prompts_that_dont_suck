### Glob with Intent

ALWAYS know what a glob excludes and includes before acting on its matches. `*` skips dotfiles; `**` includes `node_modules`. Both defaults are wrong for half the things people use them for.

A glob feeding a bulk operation is a query you never reviewed; preview the result set before mutating it.

- Moving or copying "everything"? `*` misses dotfiles. Use the directory itself as the unit (`cp -a src/. dest/`, `mv src dest`, `rsync -a src/ dest/`), or enable `shopt -s dotglob` deliberately.
- Recursing over a repo? Exclude the standing junk: `node_modules`, `.git`, `dist`, `build`, `vendor`, `coverage`, `__pycache__`, `.venv`. Prefer tools that respect `.gitignore` by default (`rg`, `fd`, `git ls-files`) over raw `find`/`grep -r`.
- Before a destructive or bulk-mutating command, preview the match list: `echo <glob>`, `ls -d <glob>`, or run the `find` without `-exec` first. Count it; if "all our source files" comes back as 48,000, your glob found the dependency tree.
- A glob with zero matches passes itself through literally in some shells (a file named `*.bak` is not what you want to operate on). Use `nullglob` in scripts, or check the match count.
- Character ranges and brace expansions deserve a test: `[A-z]` matches punctuation; `{a,b}` is brace expansion, not a glob, and behaves differently in `find -name`.
- In code, know your library's flags: Python `glob` needs `recursive=True` for `**`; many JS globbers need `dot: true` for dotfiles.

**Red flags that you're about to violate this:**

- "Star means everything." (It means everything visible.)
- "I'll run the replace across **/*.ts — that's our source." (And your node_modules.)
- "No need to preview; the pattern is obviously right."
- "The copy succeeded, so everything came across."
- "grep -r * covers the whole tree." (Minus every dotfile and dot-directory at the top.)

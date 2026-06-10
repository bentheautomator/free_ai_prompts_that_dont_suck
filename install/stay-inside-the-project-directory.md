### Stay Inside the Project Directory

NEVER create, modify, or delete files outside the project directory without explicit permission. The task scope is the repo, not the machine.

The core problem: files outside the project — dotfiles, global configs, sibling repos, system paths — have no version control, no review, and other software depending on them. Mistakes there are invisible and unrevertable.

- Treat the project root as a hard write boundary. Reading outside it is fine; writing outside it requires asking first, every time.
- This includes the tempting cases: `~/.bashrc`/`~/.zshrc`, `~/.config/*`, `~/.gitconfig`, `/etc/*`, globally installed packages, and other repos checked out nearby.
- If the correct fix genuinely lives outside the project (a missing PATH entry, a global tool version), say so and show the exact change — let the user apply it or approve it.
- Watch for indirect escapes: scripts with `../` paths, symlinks pointing out of the tree, `$HOME` in variables, install commands with `-g`/`--global`. Resolve where a write will actually land before performing it.
- Never "fix" another project to make this one work. If a sibling repo is the problem, report it.
- When permission is granted to touch an outside file, back it up first (`cp ~/.zshrc ~/.zshrc.bak-$(date +%s)`) and show the diff after.

**Red flags that you're about to violate this:**
- "The real problem is in their shell profile, I'll just patch it..."
- "Adding one export to ~/.zshrc is harmless..."
- "The conflicting package is global, so I'll remove it globally..."
- "That sibling repo has the bug — quicker to fix it there directly..."
- "The config file is technically outside the repo but it's still 'the project'..."

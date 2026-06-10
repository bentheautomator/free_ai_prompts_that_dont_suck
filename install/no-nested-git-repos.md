### No Nested Git Repos

NEVER run `git init` or `git clone` inside an existing repository's working tree without the user explicitly asking for a nested repo or submodule. A repo inside a repo doesn't get tracked; it gets committed as an empty pointer (a gitlink), and clones receive an empty directory.

- Before any `git init`, check where you are: `git rev-parse --show-toplevel`. If it prints a path, you are already inside a repository; initializing here creates a nested one.
- Scaffolding tools (project generators, `create-*` CLIs) often run `git init` themselves. After scaffolding inside an existing repo, check for and remove the stray inner repo: `find <new-dir> -maxdepth 2 -name .git`, then delete that `.git` directory (the code is untouched; only the inner repo metadata goes).
- Need to read another project's code? Clone it OUTSIDE the working tree (`/tmp` or a sibling directory), never into the repo.
- The status tell: a whole directory appearing as a single untracked entry, or staging it producing one `new file (mode 160000)` line instead of many files, means there's an inner `.git`. Stop and remove it before committing.
- If a gitlink already got committed, fix it explicitly: `git rm --cached <dir>` (one level, no `-r` needed for a gitlink), remove the inner `.git`, then `git add <dir>` to track the actual files.
- If the user genuinely wants an embedded repository, that's a submodule conversation (`git submodule add <url> <path>`), not a bare nested clone.

**Red flags that you're about to violate this:**

- "I'll git init the new package directory so it has version control."
- "Cloning the example repo into the project keeps everything together."
- "The generator ran git init, but that's probably harmless."
- "git status shows the directory, so its contents are being tracked."
- "Mode 160000 is just some permission thing."

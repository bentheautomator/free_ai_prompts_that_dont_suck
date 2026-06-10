### Never Commit .env Files or Untracked Secrets

NEVER stage or commit files that contain credentials. Stage files by explicit path; do not use `git add .`, `git add -A`, or `git commit -a` without reviewing exactly what they will pick up.

A committed secret is in history permanently. Removing the file in a later commit does not remove the secret.

- Before any commit, run `git status` and check the untracked list for: `.env` and variants (`.env.local`, `.env.production`), `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `service-account*.json`, `credentials*`, `*.sqlite`/`*.db`/`*.sql` dumps, and editor-created backup copies of any of these.
- If you create a `.env` file during a session, add it to `.gitignore` in the same step, and create a committed `.env.example` with placeholder values instead.
- If a secret-bearing file is already tracked, do not quietly `git rm` it. Tell the user: the credential needs rotation and possibly history rewriting (`git filter-repo`), because every clone already has it.
- Never bypass a gitignore with `git add -f` to "make the build work." Fix the build to read configuration properly instead.
- Pre-commit hooks or secret scanners failing is a stop signal, not an obstacle. Do not amend, skip hooks (`--no-verify`), or rename files to get past them.

**Red flags that you're about to violate this:**
- "git add . is faster and I changed a lot of files..."
- "The .env only has local dev values in it..."
- "I'll commit it now and gitignore it in a follow-up..."
- "The pre-commit hook is blocking the commit, I'll use --no-verify just this once..."
- "It's a private repo, committed secrets aren't a real exposure..."
- "The user told me to commit everything..."

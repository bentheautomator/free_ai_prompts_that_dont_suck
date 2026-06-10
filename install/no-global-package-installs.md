### No Global Package Installs

NEVER install project tooling globally. No `npm install -g`, no `pip install` outside a virtualenv, no `gem install` into the system Ruby for something the project uses. If the project needs a tool, the project's manifest must say so.

- Add tools to the project: `npm install -D <tool>` and run it via `npx <tool>` or a package.json script; `pip install` inside the project's venv and record it in requirements/pyproject; `cargo add`, `bundle add`, etc.
- For one-off executions, prefer ephemeral runners over installation: `npx <tool>`, `pnpm dlx`, `pipx run`, `uvx`. These leave no global state behind.
- Never use `pip install --break-system-packages` or `sudo pip install`. If pip refuses because the environment is externally managed, the fix is a virtualenv, not force.
- Never use `sudo` with any language package manager. If an install seems to need root, the install location is wrong.
- If a global tool already exists on the machine, don't rely on it — the project must work on a machine that doesn't have it. Check the manifest, not the PATH, to determine what's available.
- Exception: tools the user explicitly asks to install globally for their own machine-wide use. Confirm that's the intent before using `-g`.

**Red flags that you're about to violate this:**
- "I'll install it globally so it's available on the PATH."
- "It's just a CLI tool, it doesn't need to be a project dependency."
- "Global install is quicker than editing package.json."
- "pip is refusing, so I'll pass --break-system-packages."
- "sudo will get around this permissions error."

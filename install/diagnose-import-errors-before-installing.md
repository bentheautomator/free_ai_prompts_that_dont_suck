### Diagnose Import Errors Before Installing

NEVER respond to a missing-module error by immediately installing the module. In an existing project, the most common cause is environmental — wrong interpreter, missing install step, wrong directory — and installing into the wrong environment masks the real bug while adding a stray copy.

- First, check whether the project already declares the dependency: look in `package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`. If it's declared, the package is not missing — your environment is wrong, and installing again is the wrong move.
- Identify what actually executed: `which python` / `python -c "import sys; print(sys.prefix)"` to see if the venv is active; check whether the command should be `poetry run`, `pnpm exec`, or run from a different directory.
- For a fresh clone or new shell, the fix is usually the project's setup step — `npm install`, `poetry install`, activating the venv — not adding a package.
- In a monorepo, confirm which workspace owns the failing file before adding anything, and add the dependency to that workspace's manifest, not the root and not whatever directory you're standing in.
- Only when you've confirmed the package is genuinely absent from the project's declarations is installing it the right fix — and then it goes through the project's package manager, into the manifest, like any new dependency.

**Red flags that you're about to violate this:**
- "Module not found — installing it will fix this."
- "Fastest path to unblocking the script is pip install."
- "It's probably just not installed yet." (declared where? checked?)
- "I'll install it here; the environment details don't matter for now."
- "The error literally tells me what package to install."

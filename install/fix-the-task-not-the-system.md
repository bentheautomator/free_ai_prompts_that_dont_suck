### Fix the Task, Not the System

NEVER modify anything outside the project directory to unblock a task without explicit user approval. No global installs, no runtime upgrades, no edits to dotfiles or system config, no starting, stopping, or restarting system services.

The core problem: the error text points at the environment, so changing the environment feels responsive — but the system is shared, your changes to it are invisible to `git diff`, and they outlive the session.

- Solve version problems at project scope: version manager files (`.nvmrc`, `.python-version`), virtual environments, lockfiles, containers. If the project needs Node 20, pin Node 20 for the project — do not move the machine.
- Treat these as requiring explicit user approval, every time: `sudo` anything, global package installs (`npm i -g`, system package managers), edits to files in `$HOME` or `/etc`, service control (`systemctl`, `brew services`, killing daemons), and changes to OS settings.
- When the task genuinely appears blocked on the environment, stop and present it: "The build needs X; the system has Y. Options: (a) project-level pin, (b) you upgrade the system, (c) container. Recommend (a)." The user decides about their machine.
- Never restart or reconfigure a running service to clear an error. You don't know what else depends on it being exactly as it is.
- If you did get approval for a system change, record it in your summary in its own section — system changes don't appear in the diff, so your summary is the only audit trail.

**Red flags that you're about to violate this:**
- "The error says the Node version is too old, so I'll upgrade it..."
- "I'll just install this globally, it's a common tool..."
- "A quick edit to the shell profile will fix the PATH..."
- "Restarting the service should clear this..."
- "sudo will get me past this permission error..."

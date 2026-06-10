### No Machine-Specific Values in Committed Config

NEVER commit a config value that encodes facts about the current machine: absolute paths under a home directory, locally-chosen ports, `*.local` hostnames, usernames, or paths to locally-installed tool versions.

A value that's correct here and meaningless everywhere else doesn't belong in a file everyone shares.

- Paths in committed config must be relative to the project root, or built from a variable (`$HOME`, `${workspaceFolder}`, `%APPDATA%`) — never `/Users/<name>/...` or `C:\Users\<name>\...`.
- Tool locations should be resolved, not pinned: `python3` via PATH, not `/opt/homebrew/bin/python3.11`; if a specific version matters, declare the version requirement (`.tool-versions`, `engines`), not the install path.
- If a value legitimately varies per machine (port, local DB host, browser binary), it belongs in the gitignored local layer (`.env.local`, `*.local.json`, override files) with a portable default in the shared file.
- Hostnames in shared config must be resolvable from every environment that reads them — `localhost` and service names from compose/k8s qualify; `daves-laptop.local` does not.
- Before committing any config change, scan the diff for your own username, home directory, or hostname. Finding one means a value took the wrong exit.

**Red flags that you're about to violate this:**
- "I used the absolute path so there's no ambiguity."
- "I verified this path exists, so the config is correct."
- "The port had to change locally, and committed config is where ports live."
- "Everyone here uses macOS anyway."
- "CI doesn't run this config, so portability doesn't matter."

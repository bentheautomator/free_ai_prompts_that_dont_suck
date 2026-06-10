### No curl-Pipe-bash Package Installs

NEVER install software by piping a remote script into a shell (`curl ... | bash`, `wget -qO- ... | sh`, `iwr ... | iex`). Executing unread remote code with shell privileges, unversioned and unrecorded, is the failure mode package managers were invented to prevent.

- Prefer the tool from a real package manager first: the system one (`apt`, `dnf`, `brew`, `winget`), the language one (`npm`, `pipx`, `cargo install`), or the project's published packages. Most popular tools are available this way; check before defaulting to the script.
- If no packaged form exists, download a pinned release artifact instead: a specific version from the project's releases page, with its published checksum verified (`sha256sum -c`) before anything executes or gets moved onto PATH.
- If the install script is genuinely the only path, download it to a file first, read it, then execute the reviewed copy — and record the version/URL/date somewhere in the repo if the project depends on the tool. Never pipe directly from network to shell, and never pipe into `sudo`.
- In Dockerfiles and CI, the bar is higher, not lower: these run unattended forever. Pin the artifact version and verify the checksum in the build step, so the build fails loudly if the upstream bytes change.
- The vendor recommending the one-liner doesn't change the analysis. It's their happy path for adoption, not a security posture for your infrastructure.

**Red flags that you're about to violate this:**
- "This is the official install command from their homepage."
- "Everyone installs this tool with the curl one-liner."
- "It's a trusted project; the script is fine."
- "Reading the script first is paranoia for a setup step."
- "I'll add sudo since the script needs to write to /usr/local."

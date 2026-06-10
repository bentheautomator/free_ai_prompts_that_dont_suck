### Verify OS and Shell Before Giving Commands

NEVER write commands for an assumed operating system or shell. Confirm the actual platform first — Linux-with-bash is your training-data default, not a fact about this user.

A wrong-platform command costs a failed round-trip at best; a path or deletion command with different semantics on the user's OS can destroy the wrong thing.

**Before giving or running shell commands:**
- Check the environment info your session provides (platform, OS version, shell) — most coding tools state it explicitly
- No environment info? Look for tells: `C:\` paths or `.ps1` scripts mean Windows; `brew` references or `/Users/` paths mean macOS; `/home/` suggests Linux — or just ask
- Match the shell, not just the OS: `export` (bash/zsh) vs `set -x` (fish) vs `$env:` (PowerShell); `&&` chaining is not universal
- Use the platform's package manager: apt/dnf/pacman on Linux, brew on macOS, winget/choco/scoop on Windows — never prescribe `apt-get` cross-platform
- Mind command divergence: BSD vs GNU `sed`/`grep` flags, `rm -rf` vs `Remove-Item -Recurse`, path separators and case-sensitivity
- When writing scripts for the repo (not the user's terminal), match what the repo already contains — a repo full of `.sh` files implies its own target environment

**Red flags that you're about to violate this:**
- "They're a developer, they're probably on Linux or at least WSL..."
- "These commands are basically portable..."
- "I'll write it for bash and they can translate..."
- "sed -i works the same everywhere..."
- "Everyone has grep, curl, and make installed..."
- Writing `apt-get` without having seen a single piece of evidence about the platform

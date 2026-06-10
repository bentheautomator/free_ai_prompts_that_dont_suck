---
title: Validate File Uploads Like They're Hostile
slug: validate-file-uploads
category: security
tags: [universal, security, uploads]
works_with: all
severity: critical
one_liner: "AI accepting any upload and serving it back executable"
---

# Validate File Uploads Like They're Hostile

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI-built upload features that accept anything and serve it from the app's own origin.

**[Copy-paste ready version](../../install/validate-file-uploads.md)** — just the instruction block, no explanation.

## The Problem

An AI-generated upload handler typically does three things: takes whatever multer or the form parser hands it, saves it under the client's original filename, and serves it back from `/uploads` on the application's own domain. That's three vulnerabilities in a trench coat. Trusting the client's `Content-Type` and extension means a `.php` file or an HTML file full of JavaScript gets stored; keeping the original filename invites traversal and overwrites; and serving from your own origin means that uploaded HTML/SVG executes as your site — stored XSS with a file input as the delivery mechanism. SVGs deserve special mention: they pass "images only" checks while being XML documents that can carry scripts.

The AI builds it this way because the tutorial version of file upload is exactly this, and because validation feels like it's about user experience ("only allow images so the gallery looks right") rather than about keeping executable content off your origin. When asked to validate, the AI checks `file.mimetype` — which the client sets — or the filename extension, both attacker-controlled, and calls it secure.

The defenses are well-known and cheap: allowlist real (sniffed) types, rename server-side, store outside the web root or on a separate domain, and serve with headers that forbid execution.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Validate File Uploads Like They're Hostile

NEVER trust anything the client says about an uploaded file. Validate the content, replace the name, and serve uploads so they can't execute.

The client's filename, extension, and Content-Type are all attacker-chosen. An upload feature that trusts them is a stored-XSS and code-upload feature.

- Allowlist file types by sniffing actual content (magic bytes via `file-type`, `python-magic`, or re-encoding images through a library), not by extension or the client's `mimetype` field. Reject anything outside the allowlist; never blocklist "dangerous" extensions and accept the rest.
- Treat SVG as code, not image: it executes scripts when served inline. Either reject it, sanitize it with a dedicated SVG sanitizer, or serve it only as `Content-Disposition: attachment`.
- Discard the original filename. Store under a server-generated name (`uuid4()` plus an extension you chose based on sniffed type); keep the user's name as display metadata only. This kills traversal, overwrite, and trick-extension (`invoice.pdf.exe`, null-byte) games at once.
- Store outside the web root (or in object storage), never in a directory where the web server might execute content. Serve via a handler or, better, a separate cookie-less domain (`usercontent.example.net`), with `Content-Type` set from your sniffed type, `X-Content-Type-Options: nosniff`, and `Content-Disposition: attachment` for anything not strictly needed inline.
- Enforce size limits at the parser level (multer `limits`, nginx `client_max_body_size`), and bound image dimensions before processing — decompression bombs cook servers.
- Never feed the upload's path or name into shell commands (thumbnailing via ImageMagick CLI etc.) by string interpolation; pass argument arrays.
- If the feature stores to S3-style object storage via presigned URLs, constrain the content type and size in the presigned policy, not just in the UI.

**Red flags that you're about to violate this:**
- "Multer already filters by mimetype, that's the validation..."
- "Checking the extension covers the realistic cases..."
- "SVGs are images, and we accept images..."
- "Keeping the original filename makes downloads friendlier..."
- "Serving from /uploads on our domain is simplest, it's all static files..."
- "Size limits can wait until someone actually abuses it..."

---

## Why It Works

1. **It reassigns trust at the source.** The pivotal fact is that mimetype and filename are client-set; once stated, the AI's standard `file.mimetype` check is self-evidently theater rather than validation.

2. **It singles out SVG.** "Images are safe" is the assumption that survives every generic upload rule; calling SVG code-in-an-image-costume blocks the bypass that actually gets exploited.

3. **It bundles serving with storing.** Most instructions stop at validation; execution context (own-origin serving, missing nosniff) is where uploads become XSS, so the rule covers the response path too.

4. **It makes rename-on-store a single move that kills four bugs.** Traversal, overwrite, double extensions, and weird Unicode all die with the server-generated name, which makes the secure pattern feel efficient rather than paranoid.

## Origin

A support portal let customers attach files to tickets, and the assistant's implementation stored them under their original names in a public `/uploads` path, filtered by extension blocklist. A customer attached an HTML file containing a script that ran when a support agent previewed the "attachment" from the portal's own domain, exporting the agent's session. The blocklist had covered `.exe` and `.php`; nobody had thought of `.html` as dangerous, including the model that wrote the list.

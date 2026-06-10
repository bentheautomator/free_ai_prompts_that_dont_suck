---
title: Stream File Uploads Instead of Buffering in Memory
slug: stream-file-uploads-instead-of-buffering-in-memory
category: backend
tags: [universal, backend]
works_with: all
severity: high
one_liner: "Keeps a handful of big uploads from OOM-killing your whole service"
---

# Stream File Uploads Instead of Buffering in Memory

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents upload handlers that read entire files into RAM from letting a few large concurrent uploads take down the process.

**[Copy-paste ready version](../../install/stream-file-uploads-instead-of-buffering-in-memory.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant for an upload endpoint and you'll get some flavor of `const data = await file.arrayBuffer()` or `data = request.files['f'].read()` — slurp the whole file into a byte array, then do something with it. With the 200KB test image, this is fine. The code is short, the test passes, everyone moves on.

Now do the multiplication the assistant didn't. A 500MB video upload is 500MB of heap — sometimes 2–3x that, because the framework buffered the multipart body once, your handler copied it into a variable, and the base64 encoder you fed it made a third copy. Eight users uploading simultaneously is 4–12GB on a pod with a 2GB limit. The OOM killer doesn't politely fail the big upload; it kills the process, dropping every in-flight request from every user, and then the uploader's client retries, killing the freshly restarted process again. One enthusiastic user with a slow connection and a big file becomes a denial of service.

Assistants buffer because the whole-file-in-a-variable API is the one most prominent in documentation and training data, and because memory pressure is invisible at demo scale. The streaming version is barely longer — it's just not the first thing autocomplete reaches for.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stream File Uploads Instead of Buffering in Memory

NEVER read an uploaded file fully into memory. Stream it from the request socket to its destination (object storage, disk, a hashing/scanning pipe) in fixed-size chunks, so memory use per upload is constant regardless of file size.

- Pipe request streams to their destination: multipart streaming parsers (`busboy`/`@fastify/multipart` in Node, `request.stream`/`UploadFile.read(chunk)` in Python, `io.Copy` from `r.Body` in Go) straight into an S3/GCS multipart upload or a temp file. Memory cost: one chunk, not one file.
- Better still, skip your server entirely: issue a presigned URL and let clients upload directly to object storage. Your service handles a small JSON request; the storage provider handles the gigabytes.
- Enforce a maximum body size *before* reading — at the proxy (`client_max_body_size`), the framework limit, or by rejecting on `Content-Length` — and abort mid-stream if a chunked body exceeds the cap. A limit checked after buffering already paid the memory bill.
- Process streamingly too: hash, virus-scan, and validate via stream transforms as bytes pass through. If a step genuinely needs the whole file (image resize), spool to a temp file on disk, and clean it up in a `finally`.
- Validate the type from the first bytes (magic numbers) early so a mislabeled 5GB upload is rejected at chunk one, not chunk last.
- The same applies to downloads and proxying: stream responses out; never load a file into memory just to send it somewhere else.

**Red flags that you're about to violate this:**
- "Files here are small, it's just avatars." (The limit enforcing that is... where?)
- "Reading it into a buffer is so much simpler."
- "I need the whole file to validate it first." (You need the first 16 bytes.)
- "The server has plenty of RAM."
- "I'll base64 it into the JSON payload." (Now it's 33% bigger and buffered twice.)
- "We can optimize for large files later."

---

## Why It Works

1. **It changes the cost model from O(file × concurrency) to O(chunk × concurrency).** Constant per-upload memory means worst-case usage is calculable and small; buffered memory is unbounded and decided by your users.
2. **It blocks the blast radius, not just the bug.** An OOM kill takes out every in-flight request, not just the offending upload — streaming confines a big file's cost to its own connection.
3. **It moves limits ahead of the spend.** A size check after `read()` is a receipt, not a guard; checking at the proxy or first chunk rejects the attack before it costs anything.
4. **It offers the escape hatch for whole-file operations.** "Spool to disk" keeps the rule followable when streaming genuinely can't work, so the assistant doesn't abandon it at the first image-resize.

## Origin

A document-management service buffered uploads to validate PDFs before storing them. A partner integration began syncing scanned archives — 300MB-to-1.2GB files, dozens at a time. Pods OOM-killed in a loop for four hours, and the partner's sync client dutifully retried each failed file, re-triggering the kill on every restart. The handler that replaced it streamed to a temp file and checked four magic bytes; it has held a flat 60MB of memory through every sync since.

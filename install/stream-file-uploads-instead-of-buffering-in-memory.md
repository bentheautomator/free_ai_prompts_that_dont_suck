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

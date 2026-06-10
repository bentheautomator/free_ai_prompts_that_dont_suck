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

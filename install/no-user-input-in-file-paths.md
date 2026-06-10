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

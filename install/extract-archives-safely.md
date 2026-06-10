### Extract Archives Safely

NEVER extract an archive without ensuring every entry resolves inside the target directory. Entry names are untrusted input that extraction executes as write paths.

A hostile entry named `../../.ssh/authorized_keys` or `/etc/passwd`, extracted naively, writes exactly there. This is zip-slip; the result is arbitrary file overwrite.

- In code you write: validate each entry before writing it. Join the entry name to the destination, resolve it (`os.path.realpath`, `filepath.Clean` + prefix check, `Path.resolve()`), and require the result to be inside the destination. Reject absolute paths, `..` components, and drive letters.
- Use the safe API where one exists: Python `tarfile.extractall(path, filter="data")` (refuses traversal, absolute paths, dangerous types); prefer maintained extraction libraries over hand-rolled entry loops in any language.
- Symlinks and hardlinks in archives are part of the attack surface: a link targeting outside the tree, followed by entries extracted through it, escapes your prefix check. The `data` filter handles this; manual code must check link targets too.
- Inspect before extracting anything untrusted: `tar -tf archive.tar.gz | grep -E '^/|\.\.'` and `unzip -l archive.zip` cost seconds and show hostile paths before they execute.
- Extract into a fresh, empty, dedicated directory — never directly into a repo root, `$HOME`, or anywhere a misbehaving entry has interesting targets to overwrite.
- Also sanity-check the unpacked size or entry count for untrusted input; decompression bombs ride the same code path.

**Red flags that you're about to violate this:**

- "It's just a zip from the build artifact store; extractall is fine."
- "Path traversal in archives is a theoretical attack."
- "I'll extract first and clean up anything weird after." (After is too late; the writes happened.)
- "The library probably handles this." (Verify; the stdlib historically didn't.)
- "I'm only extracting it to look inside." (Looking is `tar -tf`. Extracting is writing.)

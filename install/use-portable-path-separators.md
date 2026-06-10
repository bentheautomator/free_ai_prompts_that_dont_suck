### Use Portable Path Separators

NEVER build file paths by concatenating strings with a hardcoded `/` or `\`. Use the language's path API.

A hardcoded separator encodes your current OS into the code; the failure only manifests on the OS you're not testing on.

- Join with the platform API: `os.path.join` / `pathlib` (Python), `path.join` (Node), `filepath.Join` (Go), `Path.Combine` (C#), `PathBuf::push` (Rust).
- Split and compare with the same APIs: `path.sep`, `os.path.normpath`, `filepath.ToSlash`. Never `split("/")` on a path that came from the filesystem.
- Backslashes in string literals are escape sequences in most languages. `"C:\temp\new"` contains a tab and a newline. If you must write a Windows path literal, use raw strings (`r"..."`) or forward slashes where the API accepts them.
- Know the exceptions that are always forward-slash regardless of OS: URLs, glob patterns in most libraries, paths inside zip/tar archives, Docker image paths, import specifiers, and `.gitignore` patterns. Don't "fix" those to `os.sep`.
- In shell scripts and Makefiles, forward slashes are correct; the portability problem there belongs to the tool invocations, not the separator.
- When a path crosses a boundary (written to JSON consumed on another OS, compared against user input), normalize explicitly and say to what.

**Red flags that you're about to violate this:**

- "String concatenation is simpler than importing the path module."
- "This project is Linux-only anyway." (Check whether developers use Windows or WSL.)
- "I'll split on '/' because that's what paths look like."
- "The backslash literal worked when I tested it." (You tested on the OS where it parses.)
- "I'll normalize everything to backslashes for Windows." (Forward slashes work in most Windows APIs; backslashes break everywhere else.)

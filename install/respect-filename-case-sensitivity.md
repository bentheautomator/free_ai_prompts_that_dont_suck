### Respect Filename Case Sensitivity

ALWAYS match the exact on-disk casing in every file reference: imports, requires, asset URLs, include paths, config entries. NEVER infer casing from naming conventions.

Case-insensitive filesystems (macOS and Windows defaults) forgive mismatches that case-sensitive ones (Linux, every CI runner, every container) do not. The bug is undetectable on the machine that wrote it.

- Before writing an import or path reference, verify the real name with a directory listing (`ls`), not from memory and not from the symbol's casing. `userProfile.tsx` and `UserProfile.tsx` are different files on Linux.
- When creating a file, follow the directory's existing casing convention exactly. Don't introduce `PascalCase.ts` into a `kebab-case.ts` directory or vice versa.
- Never rename a file changing only its case in a single step on macOS/Windows; git may miss it. Use `git mv File.js temp && git mv temp file.js`, or `git mv -f` where supported.
- Treat near-miss grep results as alarms: if searching for the exact path returns nothing but a case-insensitive search (`grep -ri`) hits, you have a latent Linux-only break — flag it.
- This applies beyond imports: webpack/Vite asset paths, `#include` headers, Dockerfile `COPY` sources, YAML pipeline file references, and test fixture paths all resolve case-sensitively somewhere in the pipeline.

**Red flags that you're about to violate this:**

- "The component is PascalCase, so the file must be too."
- "It resolved locally, so the path is correct."
- "I'll just rename the file to match my import instead." (Now you've made a case-only rename. See above.)
- "Case doesn't matter for filenames."
- "CI is failing on a module that obviously exists."

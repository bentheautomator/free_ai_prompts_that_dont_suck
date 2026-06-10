### Don't Vendor Packages by Copy-Paste

NEVER copy a library's source code into the repository as a substitute for declaring it as a dependency. A pasted library is an invisible fork: no version, no security scanning, no upstream fixes, and usually a license violation.

- If the project needs a library, declare it in the manifest and install it. If the install fails, fix the install problem — don't route around the package manager by pasting its output.
- Needing one small function from a big library is not a paste license. Either take the dependency, or write your own genuinely original implementation of the small thing. Reproducing the library's implementation from memory is still copying, including its license obligations.
- If vendoring is truly required (offline builds, policy reasons, patched fork), do it properly and visibly: a dedicated `vendor/` directory, the exact upstream version and source URL recorded, the LICENSE file included, and a note on how to update. Vendoring is a documented decision, not a paste.
- Never strip or omit license headers and copyright notices from copied code. For most open-source licenses, keeping the notice is the main condition of being allowed to copy at all.
- If you find pasted-library code in the repo while working, flag it — it's an unpatched, unscannable dependency someone doesn't know they have.

**Red flags that you're about to violate this:**
- "The install is failing, but I can just inline the library's code."
- "We only need one function, so copying it in is leaner than a dependency."
- "I'll reproduce it from memory, so it's not really copying."
- "It's open source; that means I can paste it anywhere."
- "Putting it in utils/ keeps the dependency count down."

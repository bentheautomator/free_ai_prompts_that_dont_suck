### Match the Import Order Convention

ALWAYS insert new imports according to the ordering and grouping convention already present in the file. The import block has structure; find it before you add to it.

Appending to the bottom of the block "because it works" fails lint in enforced projects and rots the convention in unenforced ones.

**When adding an import:**
- Read the existing import block first and identify the scheme: grouping (stdlib / third-party / local), ordering within groups (alphabetical, by path depth), blank-line separators, and style (`import x` vs `from x import y`, default vs named, aliasing patterns)
- Insert the new import into its correct group and position — not at the end of the block, not above the code that uses it
- Match the file's import *style* too: if the file does `from datetime import datetime`, don't add `import datetime`; if it aliases `import numpy as np`, use the established alias
- All imports go at the top of the file in the import block unless the codebase demonstrably uses inline imports for a reason (lazy loading, circularity workarounds) — and then only where it already does
- If the project has an import sorter configured (`isort`, `goimports`, `import/order`, formatter settings), conform to what it would produce; run it on touched files if available

**Red flags that you're about to violate this:**
- "I'll add the import at the end of the list..."
- "I'll import it right here next to where it's used, keeps things local..."
- "The order doesn't matter functionally..."
- "Their grouping looks inconsistent anyway, so anywhere is fine..."
- "The formatter will fix the placement..." (in a project with no formatter)
- Adding an import line without having read the existing block's structure

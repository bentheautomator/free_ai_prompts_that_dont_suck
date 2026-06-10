### Don't Mangle File Encodings

NEVER change a file's encoding or BOM state as a side effect of an edit. The bytes outside your edit must survive the round trip untouched.

Encoding errors are invisible in your own output and catastrophic in production: mojibake in user-facing strings, broken shebangs, parsers rejecting config.

- Before editing a file that contains (or should contain) non-ASCII text, check its encoding: `file -i <path>` or look for a BOM with `head -c 3 <path> | xxd`. Write back in the same encoding.
- Preserve BOM state exactly: if the file starts with `EF BB BF`, your rewrite starts with `EF BB BF`. If it doesn't, do not add one. Never add a BOM to shell scripts, source code, JSON, or YAML.
- If you see `Ã©`, `â€™`, `ï»¿`, or `�` in a file you just wrote, you corrupted it. Stop and restore from the original; do not "fix" the visible symptoms character by character.
- When creating new files, default to UTF-8 without BOM unless the consumer documents otherwise (e.g., some Windows toolchains and Excel-bound CSVs want a BOM).
- Escape sequences are a safe alternative when you can't guarantee the pipeline: in Java `.properties` or JSON, `é` survives any encoding confusion that `é` would not.
- Never run a blanket `iconv` or "convert to UTF-8" over files you didn't fully inspect.

**Red flags that you're about to violate this:**

- "It looks fine in my output, so the encoding must be fine."
- "I'll just save everything as UTF-8; that's the standard."
- "That `Ã©` was probably already there."
- "The BOM is three bytes, who's going to notice."
- "I'll fix the weird characters by replacing them with what they should be."

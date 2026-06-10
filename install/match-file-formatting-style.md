### Match the File's Formatting Style

ALWAYS write new code in the formatting style of the file it's going into — not the style you'd choose. You have formatting preferences from training averages; the file has formatting facts. Facts win.

**Before writing into any file, observe and match:**
- Indentation: spaces vs tabs, and the width — copy it exactly; in Python and YAML a mismatch is a syntax or structure error, not a style nit
- Quotes: single vs double vs backticks, and when each is used
- Semicolons (in languages where they're optional): present or absent, consistently
- Brace and spacing style: same-line vs next-line braces, spaces inside parens/brackets, trailing commas in multiline literals
- Line-length discipline: if the file wraps at ~80, don't write 140-character lines
- Blank-line rhythm between functions and logical sections

**Also:**
- If the project has a formatter config (`.prettierrc`, `.editorconfig`, `rustfmt.toml`, `pyproject.toml [tool.black]`), that config is the answer — follow it, and run the formatter on touched files if it's available
- Never "fix" the file's existing style to match your output; your output matches the file
- If the file is internally inconsistent, match the style of the code immediately surrounding your edit

**Red flags that you're about to violate this:**
- "I'll write this in standard style..."
- "Double quotes are more common, so..."
- "I'll use proper 4-space indentation here..." (in a 2-space file)
- "The formatter will normalize it anyway..." (unverified that one exists)
- "Adding semicolons is harmless..."
- Writing a block without having consciously noted the file's quote, indent, and semicolon choices

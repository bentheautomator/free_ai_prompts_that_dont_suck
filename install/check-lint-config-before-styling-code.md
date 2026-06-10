### Check Lint Config Before Styling Code

ALWAYS write code to the repo's configured style, not your default style. The lint and formatter configs are the team's settled answer to every style question — your job is to comply with them, not to revisit them.

Off-style code costs a lint-failure round-trip when enforcement exists, and a creeping second style when it doesn't.

**Before writing or editing code:**
- Read the style constitution at the root: `.prettierrc*`, `.eslintrc*`/`eslint.config.*`, `.editorconfig`, `ruff.toml`/`setup.cfg`/`pyproject.toml` tool sections, `rustfmt.toml`, `.golangci.yml` — short files, big payoff
- Apply the specifics that diverge most often from defaults: quote style, semicolons, line length, tabs vs spaces, trailing commas, import ordering
- Treat lint rules as behavioral law, not just formatting: no-default-export, naming conventions, and promise-handling rules shape *what* you write, not just how it's spaced
- If the project exposes a format/lint command (`npm run lint`, `make fmt`, pre-commit config), run it on your changes before presenting them — let the tool be the authority
- Never reformat code you weren't asked to change: cosmetic churn buries the real diff and hijacks `git blame` — your edit should touch only the lines your change needs
- No config files at all? Match the style of the surrounding code instead of defaulting to your own

**Red flags that you're about to violate this:**
- "I'll use my usual formatting, it's standard..."
- "Semicolons are correct, whatever their config says..."
- "While I'm in this file, I'll tidy the formatting..."
- "The linter will sort it out later..."
- "Style configs are boilerplate, no need to read them..."
- Writing quotes, indentation, or line lengths you chose rather than looked up

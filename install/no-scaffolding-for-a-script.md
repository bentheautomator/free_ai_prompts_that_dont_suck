### No Scaffolding for a Script

When asked for a script or one-off tool, deliver one runnable file. NEVER wrap it in package structure, project directories, or build configuration.

The core problem: scaffolding inverts a disposable tool's economics, making it slower to run, harder to read, and scarier to delete, while spending effort on ceremony instead of on the logic that actually matters.

- One file, runnable directly (`python script.py`, `node script.js`, `./script.sh`), readable top to bottom
- No `src/` trees, package init files, manifest/setup files, Makefiles, or entry-point configuration for something that will be invoked by hand
- No separate config files; inputs go in argument parsing if requested, or clearly marked constants at the top of the file if not
- No test directories for a one-off unless tests were requested; for data-touching scripts, a dry-run flag or a printed preview of planned actions is worth more and costs less
- Internal structure inside the one file (a few functions, a `main()`) is fine and good; structure across files is the thing nobody asked for
- If the user says it will be reused, shared, installed, or maintained, that changes the artifact class; confirm what they need ("Should this be a proper package?") before scaffolding

**Red flags that you're about to violate this:**
- "I'll structure this properly so it can grow into a real tool..."
- "A package layout makes this more maintainable..."
- "Best practice is to separate the CLI from the core logic..."
- "I'll add a pyproject.toml so it installs cleanly..."
- "Splitting this into modules keeps each file focused..."
- "Future you will thank me for the project structure..."

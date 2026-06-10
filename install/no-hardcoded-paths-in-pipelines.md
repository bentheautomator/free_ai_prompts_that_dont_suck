### No Hardcoded Paths in Pipelines

NEVER bake absolute, machine-specific paths into pipeline or notebook code. A path like `/Users/x/Downloads/data.csv` makes the code runnable on exactly one machine and makes it ambiguous which data produced which result.

- Take data locations from configuration: an environment variable (`DATA_DIR = os.environ["DATA_DIR"]`), a CLI argument (`argparse`/`click`), or a config file checked into the repo with per-environment overrides.
- Build paths relative to a defined root, not the current working directory: `DATA_DIR / "raw" / "customers.csv"` using `pathlib.Path`, where `DATA_DIR` comes from config. Avoid `../../data` relative paths — they break the moment the script is invoked from a different directory.
- Never construct paths with `os.path.expanduser("~")` plus a personal directory layout, and never reference `Downloads`, `Desktop`, or a username in a path. Those names are the smell.
- If the user hands you a literal local path, use it once to locate the data, then immediately parameterize: define the variable at the top of the file or read it from the environment, with the user's path as a documented example default at most.
- Fail loudly and helpfully when the location is missing: `raise FileNotFoundError(f"Set DATA_DIR (looked in {path})")` beats a stack trace from deep inside `read_csv`.
- Output paths follow the same rule — results, models, and caches go under a configured output root, never a hardcoded personal folder.

**Red flags that you're about to violate this:**

- "I'll just use the path the user pasted, it works..."
- "It's only a notebook, nobody else will run it..."
- "Parameterizing is overkill for a quick script..."
- "I'll point it at my Downloads folder for now and fix it later..."
- "Everyone on the team probably has the data in the same place..."

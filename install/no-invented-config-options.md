### No Invented Config Options

NEVER write a configuration key you haven't verified against the tool's actual schema or documentation. Config files are where hallucinations go to hide, because most tools silently ignore unknown keys instead of erroring.

A made-up option doesn't fail loudly. It just does nothing while everyone believes it's working — fake caching settings, fake security flags, fake timeouts.

**Before adding or changing any config option:**
- Verify the exact key name and value type against the tool's documentation, JSON schema, or typed config definitions for the version in use
- Check existing config files in this project for how similar options are spelled and nested — nesting errors (right key, wrong level) are as fatal as wrong keys
- If the tool offers validation (`tsc --showConfig`, `eslint --print-config`, schema-validated YAML, `--check`/`--dry-run` flags), run it after editing
- Never blend option names across similar tools — Jest options into Vitest config, npm fields into pnpm, GitLab CI keys into GitHub Actions
- If you cannot verify a key exists, say so instead of writing your best guess into a file nobody will question

**Red flags that you're about to violate this:**
- "A tool like this would definitely have an option for..."
- "The naming convention suggests the key would be called..."
- "This is how the similar tool spells it, so..."
- "I'll set this to true — that's usually what it's called..."
- "The exact name might differ slightly, but this should work..."
- Writing a config key you've never seen in this project's files or the tool's docs

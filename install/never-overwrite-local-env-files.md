### Never Overwrite Local Env Files

NEVER overwrite an existing `.env` or local config file with a template, example, or regenerated version. These files are gitignored, which means no history and no recovery — and their value is precisely the accumulated real values (keys, credentials, tuned settings) that the template lacks.

The core problem: setup steps like `cp .env.example .env` are written for fresh machines. On a machine that's already set up, the same command destroys months of accumulated working configuration.

- Before any write to `.env*`, `config.local.*`, `settings.local.*`, `*.local.yml`, or similar local-config paths: check whether the file exists. If it exists, you are editing, never replacing.
- To add a variable, append it or do a targeted edit. Never regenerate the file from the example "with the new variable included."
- If a setup procedure says to copy a template, gate it: `[ -f .env ] || cp .env.example .env` — and use that guarded form in any setup script you write.
- If the user explicitly wants the file reset, copy the existing one aside first (`cp .env .env.bak-$(date +%Y%m%d)`) and say where the backup is. Real keys are painful to re-obtain.
- Diff-merge if the template gained new variables: add the missing keys to the existing file rather than the existing values to a fresh template — you'll miss fewer things.
- Extend the same respect to other filled-in local files: IDE workspace settings, local override YAMLs, `docker-compose.override.yml`.

**Red flags that you're about to violate this:**
- "Step one of the README is to copy the example env..."
- "Their env file seems off — I'll regenerate it from the template..."
- "Easiest way to add the new variable is to rewrite .env from .env.example..."
- "It's just config, the values can be filled in again..."
- "I'll reset the env to known-good defaults..."

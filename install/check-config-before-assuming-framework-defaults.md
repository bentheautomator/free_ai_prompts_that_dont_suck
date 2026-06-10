### Check Config Before Assuming Framework Defaults

NEVER assume a framework's default behavior applies to this project without checking its config files. Defaults are what the project does when nobody decided otherwise — config files are the record of everyone who decided otherwise.

Answering from defaults in a configured project gives directions to a building that's been renovated.

**Before relying on any framework default:**
- Read the framework's config file(s) first: `next.config.*`, `vite.config.*`, `angular.json`, `settings.py`, `application.yml`, `webpack.config.*`, framework sections in `package.json` or `pyproject.toml`
- Verify the specific default you're about to lean on — port, output directory, source root, base path, routing convention, environment handling — rather than skimming for vibes
- Check for environment-specific overrides: `.env` files, per-environment configs, CLI flags baked into the `dev`/`build` scripts in `package.json` or the Makefile
- When the config customizes one thing, raise your suspicion about everything else — teams that override a port also override directories
- State which config value you found when it drives your answer ("your vite.config sets port 5180, so...") so a wrong read is catchable

**Red flags that you're about to violate this:**
- "By default this framework serves on..."
- "The build output will be in dist/, as usual..."
- "Routes go in this directory — that's the convention..."
- "They probably haven't changed the defaults..."
- "The config file is mostly boilerplate, no need to read it..."
- Citing any port, path, or directory you didn't see in a config file or script this session

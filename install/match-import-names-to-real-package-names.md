### Match Import Names to Real Package Names

NEVER derive an install command from an import name. The name in `import x` and the name you give the package manager are different namespaces, and guessing the mapping installs the wrong package — or a typosquat planted to catch exactly that guess.

- Before installing to fix an ImportError, find the real distribution name from an authoritative source: the library's official documentation install section, its PyPI/npm registry page, or the project's existing requirements/manifest (the dependency may already be declared under its real name).
- Know that the mismatch is common, not exotic: `PyYAML`/`yaml`, `Pillow`/`PIL`, `opencv-python`/`cv2`, `scikit-learn`/`sklearn`, `python-dateutil`/`dateutil`, `beautifulsoup4`/`bs4`, `@google-cloud/storage` vs its import path. Treat every import-to-install translation as unverified until checked.
- Verify what you're about to install: check the registry page for the expected description, repository link, and download volume. A package whose page is empty, brand new, or unrelated to the library you want is a stop-everything signal.
- If the install succeeds but the import still fails, do not iterate through name guesses (`pip install pil`, `pip install pillow2`, ...). Each guess is another roll of the typosquat dice. Stop and look up the real name.
- The same applies in reverse: when writing requirements files from code, record distribution names, not import names.

**Red flags that you're about to violate this:**
- "The module is called yaml, so the package is called yaml."
- "I'll try installing it under a few likely names."
- "The install succeeded, so it must have been the right package."
- "No time to check the docs; the name is obvious."
- "pip found a package with that name, which proves it exists."

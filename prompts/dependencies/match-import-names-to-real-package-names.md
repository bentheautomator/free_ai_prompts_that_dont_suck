---
title: Match Import Names to Real Package Names
slug: match-import-names-to-real-package-names
category: dependencies
tags: [universal, dependencies, supply-chain]
works_with: all
severity: critical
one_liner: "Stops pip install yaml-style guesses where import name and package name differ"
---

# Match Import Names to Real Package Names

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deriving install commands from import names, which installs the wrong package or a typosquat.

**[Copy-paste ready version](../../install/match-import-names-to-real-package-names.md)** — just the instruction block, no explanation.

## The Problem

In Python especially, the name you import and the name you install are often different: you `import yaml` but install `PyYAML`; `import cv2` but install `opencv-python`; `import PIL` but install `Pillow`; `import sklearn` but install `scikit-learn`; `import dateutil` but install `python-dateutil`. AI assistants fixing a `ModuleNotFoundError` routinely run `pip install <import name>` — deriving the package name from the import by pure string manipulation.

This goes wrong in two escalating ways. The benign version installs the wrong-but-real package, or fails, and wastes a debugging cycle. The dangerous version is that attackers know this exact reflex and register the guessable names: packages squatting on import-name variants of popular libraries have repeatedly been caught carrying credential stealers, because `pip install` runs arbitrary code from `setup.py` at install time. A wrong guess isn't always a 404 — sometimes it's a payload that was placed there waiting for the guess.

The reflex exists because the mapping is irregular and the assistant fills gaps with pattern completion. The import is the only name in the error message, so the import becomes the install argument. The actual mapping is documented — in the project's own requirements file, in the library's install docs, on its PyPI page — but checking requires a step the error-to-command reflex skips.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It declares the two namespaces distinct**, which deletes the assumption underneath the whole failure — that an import name is an install argument.
2. **It names the adversary.** Knowing that guessable names are actively squatted converts "wrong guess" from a harmless retry into a recognized attack surface, which changes how cautious the AI is willing to be.
3. **It bans the guess-and-retry loop explicitly** — the iteration pattern is where one bad guess becomes five, and five guesses across squatted namespace is how payloads get installed.
4. **It points to sources the AI can actually check** (docs, registry page, the project's own manifest), so verification is a concrete action rather than an aspiration.

## Origin

Debugging a `ModuleNotFoundError` in an image-processing script, an assistant ran installs for three guessed variants of the package name in a row. The second guess resolved to a real package on the index — one that had no connection to the imaged library, executed an install-time script, and had been published eleven days earlier. The host was a shared development VM. The security team rotated every credential that had ever touched the machine, which took substantially longer than looking up the correct package name would have.

---
title: No Hardcoded Paths in Pipelines
slug: no-hardcoded-paths-in-pipelines
category: data-and-ml
tags: [universal, data]
works_with: all
severity: medium
one_liner: "Pipelines pinned to /Users/you/Downloads die on every machine but one"
---

# No Hardcoded Paths in Pipelines

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents data pipelines from being welded to one person's laptop via absolute local paths baked into the code.

**[Copy-paste ready version](../../install/no-hardcoded-paths-in-pipelines.md)** — just the instruction block, no explanation.

## The Problem

`pd.read_csv("/Users/maya/Downloads/customers_final_v3 (2).csv")` is how a remarkable amount of production ML begins. The assistant was told "load the customer data," the file was wherever it was, and the absolute path made the cell run. Then the path metastasizes: the notebook writes to `C:\Users\maya\Desktop\output\`, the training script reads from `/home/maya/data/`, and six weeks later this code is "the pipeline."

The cost is paid by everyone who isn't that laptop. CI fails, the scheduled job fails, the new teammate burns an afternoon recreating a directory layout by archaeology. Worse than the loud failures are the quiet ones: a second copy of the file exists at the hardcoded path on someone else's machine — three months staler — and the pipeline happily trains on it. Hardcoded paths don't just break portability; they make it ambiguous *which data* a result came from.

Assistants hardcode paths because the immediate goal is a cell that runs, the user's message often contains a literal path, and parameterizing feels like scope creep. Nothing in the local run punishes the shortcut.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It separates 'where the data is' from 'what the code does.'** Once location is config, the same code runs on a laptop, in CI, and in the scheduler — the three places where hardcoded paths die one at a time.

2. **It removes data-identity ambiguity.** A configured, logged data root means a result can be traced to a specific input; a hardcoded path means the input was "whatever was at that location on that machine that day."

3. **It intercepts the moment of infection.** The rule about user-pasted paths targets exactly how hardcoding enters: the assistant echoing a literal path from the conversation into permanent code.

4. **Helpful failure beats accidental success.** An explicit "set DATA_DIR" error costs seconds; silently reading a stale copy that happens to exist at the hardcoded path costs a wrong model.

## Origin

A scoring job migrated from a data scientist's workstation to a scheduler with the hardcoded path intact. The scheduler's machine happened to have a file at that exact path — a fixture copied during an earlier debugging session, four months old. The job ran green for six weeks, scoring customers against a frozen snapshot, until someone asked why brand-new signups all received the default score: they didn't exist in March's data.

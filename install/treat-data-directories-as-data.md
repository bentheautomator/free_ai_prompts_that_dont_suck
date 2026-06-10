### Treat Data Directories as Data, Not Artifacts

NEVER delete a directory as "generated output" unless you've verified the project can regenerate it from source. Directories like `uploads/`, `storage/`, `data/`, `media/`, `exports/`, and `recordings/` are accumulated data — they arrived from users, jobs, and integrations, and no rebuild brings them back.

The core problem: build artifacts and accumulated data look identical (both gitignored, both absent from fresh clones), but only artifacts are regenerable. Gitignore status signals "don't commit," not "safe to delete."

- Before deleting any untracked directory, answer: what *writes* to it? If the writer is the build system or a compiler, it's an artifact. If the writer is the running application, a user, a scheduled job, or an external system, it's data. When you can't determine the writer, treat it as data.
- Check the evidence: grep the codebase for the directory name (upload handlers, storage config, job output paths point at data), look at file types and timestamps inside (user-named PDFs accumulated over months are not build output).
- Hard list, never delete without explicit user instruction naming the directory: `uploads/`, `storage/`, `data/`, `media/`, `files/`, `exports/`, `backups/`, `recordings/`, anything containing `.sqlite`/`.db` files.
- "Reset the app" means reset *state you were asked to reset* — it does not silently include wiping accumulated user data. Enumerate what a reset will delete and confirm.
- When cleaning disk space, report sizes per directory with your artifact-vs-data classification, and delete only from the artifact column after confirmation.

**Red flags that you're about to violate this:**
- "It's gitignored, so it's generated stuff..."
- "It's not in the repo, so the app must recreate it..."
- "The storage folder is huge — clearing it frees the most space..."
- "A clean reset should include emptying the data directory..."
- "It's only staging, the uploads there don't matter..."

### Double-Check Rsync Direction and Delete Flags

Before any sync command, ALWAYS state which side is the source of truth and which side gets destroyed to match it. Never run a sync whose direction you inferred rather than confirmed.

The core problem: direction lives entirely in argument order — `rsync --delete A B` and `rsync --delete B A` are opposite disasters — and task phrasing like "sync the data" specifies no direction at all.

- Write it out before running: "SOURCE (authoritative): X. DESTINATION (will be made to match, losing anything extra): Y." If the user's request doesn't determine this, ask.
- Sanity-check the source is the *fuller, fresher* side: compare file counts or sizes (`ls | wc -l`, `du -sh`) on both ends first. An empty or near-empty source plus `--delete` means you're about to erase the destination.
- Treat `--delete` (and `--delete-after`, `--mirror` in other tools) as a separate decision from the sync itself. Only add it when the user explicitly wants extraneous destination files removed.
- Run with `--dry-run` first and read the deletions it reports, not just the transfers.
- Verify trailing-slash behavior: `src/` copies contents, `src` copies the directory itself. Get it wrong and files land one level off — or deletions apply one level wider.
- The same applies to `scp -r`, `aws s3 sync`, `gsutil rsync`, `robocopy /MIR`: same direction trap, same rules.

**Red flags that you're about to violate this:**
- "Sync them up — order probably doesn't matter much here..."
- "I'll mirror with --delete so the two sides match exactly..."
- "The local copy must be the newer one..."
- "I just created the destination folder, now sync into... wait, which way..."
- "Trailing slash details are a nitpick, rsync will figure it out..."

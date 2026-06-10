### Verify Copies Before Deleting Originals

NEVER delete source files on the strength of a copy command's exit code. Between copy and delete is the only moment when both copies exist and mistakes cost nothing — verification happens there, every time.

The core problem: "move" decomposes into copy-then-delete, and a copy can finish (exit 0) while being incomplete or mislocated — partial transfers, skipped files, truncation on full disks, or a flawless copy into the wrong destination. The delete makes whatever happened permanent.

- Verify by comparison, not by exit code. Minimum bar: file counts and total bytes on both sides (`find ... | wc -l`, `du -sb`). Better: checksums (`rsync -c --dry-run` reports differences; `diff -r` for local; checksum manifests for remote).
- Verify the *destination is where you think*: list the remote/target path and confirm the files are actually in it — not one level up, not in a directory that auto-created with a different name.
- Open one or two transferred files. A correct-size unreadable file (encoding, truncation, copied symlink) passes count checks and fails reality.
- Keep the delete as a separate, later step — never `&&`-chained to the copy. Ideally let originals survive until the destination has been *used* successfully once, and let the user fire the deletion.
- For large or important moves, prefer tools that verify as they go (`rsync` with `--checksum` over bare `scp -r`) and that report what was skipped.
- If verification finds any discrepancy — one missing file, one size mismatch — nothing gets deleted until it's explained and fixed.

**Red flags that you're about to violate this:**
- "Copy returned success, so I can clear the source now..."
- "I'll chain the rm so the move completes in one command..."
- "Counting files on both ends is excessive for a simple transfer..."
- "The tool would have errored if anything was missing..."
- "It's a move operation, deleting the source is just finishing the job..."

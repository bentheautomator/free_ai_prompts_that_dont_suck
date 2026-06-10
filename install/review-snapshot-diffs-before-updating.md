### Review Snapshot Diffs Before Updating

NEVER run a snapshot update command (`jest -u`, `--ci false` updates, `pytest --snapshot-update`, `UPDATE_SNAPSHOTS=1`, `cargo insta accept`, or equivalents) without first reading the failing diff and confirming every change is intended.

The core problem: updating a snapshot is approving new output as correct. Doing it blind converts the test from a change detector into a rubber stamp for whatever the code currently emits, including your own bugs.

Process when snapshots fail:
- Read the actual diff for each failing snapshot. The test runner prints it; do not scroll past it
- For each change, classify it: expected consequence of the requested change, or unexplained. Anything unexplained is a bug investigation, not an update candidate
- Quote or summarize the diff to the user before updating: what changed, in which snapshots, and why it's correct
- Never bulk-update dozens of snapshots in one pass on the theory that the change was global. Global changes still have diffs worth skimming, and that's where the one wrong one hides
- If a snapshot diff shows data that shouldn't be there (secrets, PII, raw error dumps), stop entirely and report it
- Updating snapshots is acceptable when the diff is read, explained, and matches the intended change. The flag isn't banned; blindness is

**Red flags that you're about to violate this:**
- "These snapshot failures are just noise from my change, I'll regenerate them..."
- "It's 40 failing snapshots, obviously they all changed for the same reason..."
- "Snapshot tests are always stale, updating is routine maintenance..."
- "I'll update them now and verify the output renders correctly later..."
- "The diff is huge, reading it all isn't practical..."

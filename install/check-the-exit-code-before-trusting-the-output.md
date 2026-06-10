### Check the Exit Code Before Trusting the Output

ALWAYS determine a command's exit code before characterizing it as succeeded or failed. The exit code is the command's own verdict; output is narration, and narration lies in both directions.

The core problem: judging success by how the output reads is a literary judgment applied to a machine-readable question. Tools print confident progress text and then fail, fail silently after the text ends, or print "error" strings inside perfectly successful runs.

- After any command whose success you're about to assert, confirm exit code 0 — from your tool's reported status, or explicitly via `echo $?` (or the platform equivalent) immediately after.
- No output is not success and is not failure; it's no information until paired with the exit code. Quiet tools exit nonzero without a word.
- Don't infer failure from the substring "error" either: filenames, grep matches, and log echoes contain it routinely. Direction one of this rule is the famous one, but misreading success as failure wastes cycles too.
- In pipelines and `&&`/`;` chains, know which step's status you're seeing. A pipe reports the last command's exit unless `pipefail` is set; "the chain printed output" says nothing about the middle steps.
- Distrust known liars: some wrappers, CI plugins, and scripts print errors and exit 0, or swallow child failures. Where you've seen that, verify via an artifact (the file exists, the row count changed) in addition to the code.
- When a script you wrote runs other commands, propagate failures (`set -e`/explicit checks) so its own exit code remains meaningful evidence.

**Red flags that you're about to violate this:**
- "The output looks like a normal successful run..."
- "It printed all the progress steps, so it finished..."
- "No error messages means no errors..."
- "Checking $? after every command is excessive..."
- "The last command in the pipe worked, so the pipe worked..."
- "There's the word 'error' — it must have failed..."

### Re-Read Files Before Acting on Old Memory

NEVER reason about or edit a file based on a version you read earlier in the session if anything could have changed it since — your edits, the user's edits, a pull, a generator, a formatter. Your memory of a file is a snapshot with no expiration warning; the filesystem is the only current version.

Acting on a stale snapshot doesn't just produce wrong edits — it silently reverts other people's work, which is the most expensive failure an assistant can commit.

**Operating rules:**
- Re-read any file before editing it if you last read it more than a few messages ago, or if any edit, command, pull, or user action has touched the project since
- After running formatters, codegen, migrations, or `git pull`/`git checkout`, treat ALL prior file knowledge as expired
- If the user says they changed something by hand, re-read every file they might have touched before your next edit
- When an edit fails to match (anchor text not found), that is proof your snapshot is stale — re-read the whole file, never retry with a looser match
- Quote current file contents when explaining code, not contents from earlier in the transcript

**Red flags that you're about to violate this:**
- "I read this file earlier, so I know what's in it..."
- "Nothing important should have changed since then..."
- "I'll just reconstruct the section around my edit..."
- "The match failed — I'll try a fuzzier version of the old text..."
- "The user's change was probably somewhere else in the file..."
- Writing out a full replacement for a file you haven't opened since before the last `git` command

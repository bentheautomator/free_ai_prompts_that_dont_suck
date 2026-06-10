### Don't Clobber Files with Shell Redirection

NEVER redirect a pipeline's output onto its own input file, and never compose a multi-step file with a chain of `>`/`>>` commands when a single write will do.

`>` truncates the target before anything runs: self-redirection empties the input pre-read, and one wrong `>` mid-composition silently discards everything composed so far.

- To transform a file in place: write to a temp file and move it over (`sort data.txt > data.txt.tmp && mv data.txt.tmp data.txt`), or use the tool's in-place mode (`sort -o data.txt data.txt`, `sed -i`). NEVER `cmd file > file`.
- To create a file with known content, write it in one operation: a file-write tool, a single heredoc (`cat > out.txt <<'EOF' ... EOF`), or one `printf`. Multi-command `echo`-chains maximize the chances of a `>`/`>>` slip and leave a partial file if any step fails.
- Before any `>` aimed at an existing file, confirm overwriting is the intent. If you're adding, it's `>>`; if you're replacing, say so to yourself explicitly first.
- `set -o noclobber` in scripts you author makes accidental `>` over an existing file an error (`>|` to override deliberately).
- `tee` reads the same trap: `cmd file | tee file` clobbers too. And `2>file` versus `2>>file` follows the same append/truncate logic for logs.

**Red flags that you're about to violate this:**

- "I'll sort the file and write it right back to itself."
- "Building the file with a series of echo appends keeps each step simple."
- "I'm pretty sure I already wrote the header with >>." (Pretty sure is how files get zeroed.)
- "If I clobber it, I'll just regenerate it." (The input you'd regenerate from may be the thing you clobbered.)
- "It's just a redirect, what could it destroy?"

### Don't Mangle File Encodings

NEVER change a file's encoding or BOM state as a side effect of an edit. The bytes outside your edit must survive the round trip untouched.

Encoding errors are invisible in your own output and catastrophic in production: mojibake in user-facing strings, broken shebangs, parsers rejecting config.

- Before editing a file that contains (or should contain) non-ASCII text, check its encoding: `file -i <path>` or look for a BOM with `head -c 3 <path> | xxd`. Write back in the same encoding.
- Preserve BOM state exactly: if the file starts with `EF BB BF`, your rewrite starts with `EF BB BF`. If it doesn't, do not add one. Never add a BOM to shell scripts, source code, JSON, or YAML.
- If you see `Ã©`, `â€™`, `ï»¿`, or `�` in a file you just wrote, you corrupted it. Stop and restore from the original; do not "fix" the visible symptoms character by character.
- When creating new files, default to UTF-8 without BOM unless the consumer documents otherwise (e.g., some Windows toolchains and Excel-bound CSVs want a BOM).
- Escape sequences are a safe alternative when you can't guarantee the pipeline: in Java `.properties` or JSON, `é` survives any encoding confusion that `é` would not.
- Never run a blanket `iconv` or "convert to UTF-8" over files you didn't fully inspect.

**Red flags that you're about to violate this:**

- "It looks fine in my output, so the encoding must be fine."
- "I'll just save everything as UTF-8; that's the standard."
- "That `Ã©` was probably already there."
- "The BOM is three bytes, who's going to notice."
- "I'll fix the weird characters by replacing them with what they should be."

### Don't Replace Symlinks with Copies

NEVER turn a symlink into a regular file as a side effect of editing. If a path is a link, decide deliberately: edit the target through the link, or edit the target directly — but the link must still be a link afterward.

A symlink replaced by a copy creates a silent fork: two files where the project depends on there being one.

- Before editing, check what you're touching: `ls -l <path>` (look for `->`) or `test -L <path>`. Reads dereference transparently, so content alone won't tell you.
- If it's a link, the real question is "should this change apply to the target?" Usually yes: edit the target file at its real path (`readlink -f`). The link stays untouched.
- Avoid write strategies that replace the path: delete-and-recreate and rename-over-the-top both destroy the link. In-place writes through the link preserve it.
- When copying or moving trees that may contain links, preserve them: `cp -a`/`cp -P` not bare `cp -r` semantics that follow links; `rsync -a` not `rsync -rL`; `tar` defaults are safe, `--dereference` is not.
- After your edit, `git status` showing `typechange` on a path you edited means you broke a link. Restore it (`ln -sfn <target> <path>`) before finishing.
- If the task genuinely requires materializing a link into a real file, say so explicitly; it changes the repo's structure, not just its content.

**Red flags that you're about to violate this:**

- "It opens and reads like a normal file, so it is one."
- "I'll recreate the file with the new content." (You'll recreate it as the wrong kind of file.)
- "The diff shows my content change, looks good." (Check for the typechange line.)
- "Copying the target here makes things simpler."
- "Symlinks are an infrastructure detail, not my problem."

### Don't Rewrite Whole Files for Small Edits

ALWAYS make the smallest edit that accomplishes the task. NEVER regenerate a whole file to change part of it.

A rewrite reproduces every untouched line from your model of the file instead of preserving the actual bytes — every reproduced line is a chance to introduce a silent change, and the resulting diff hides your real edit in noise.

- Use targeted edits (string replacement, line-range edits) rather than full-file writes whenever the file already exists.
- Touch only the lines the task requires. Do not reformat, requote, rewrap, reorder imports, or "clean up while you're in there" unless explicitly asked.
- Match the file's existing style on your new lines, even where that style differs from your defaults or the language's idiom.
- After editing, check `git diff --stat`. If the changed-line count is wildly out of proportion to the task, you rewrote the file; redo it as a minimal edit.
- If the file genuinely needs reformatting, say so and propose it as a separate commit. Mechanical churn and logic changes never share a diff.
- Full-file writes are for new files. Existing files get edits.

**Red flags that you're about to violate this:**

- "It's simpler to just output the whole corrected file."
- "While I'm here, I'll tidy the formatting too."
- "The diff is big, but it's all equivalent code."
- "My version is cleaner than what was there."
- "The formatter would do this anyway."

### Don't Slurp Huge Files to Change One Line

ALWAYS check a file's size before reading it whole. Past a few megabytes, switch from load-everything to stream-or-sample.

Whole-file reads scale with the file; the task usually doesn't. A one-line change to a 4 GB file should cost roughly one line of I/O and memory, not 4 GB.

- Check first: `ls -lh <path>` or `du -h <path>`. Make size a fact, not a surprise.
- To inspect: `head`, `tail`, `wc -l` for shape; `grep -n <pattern>` to locate; `sed -n '100,140p'` to view a region. Never cat a large file into your context to "look around."
- To edit: `sed -i 's/old/new/'` for line-level changes; `awk` for columnar work; for structured big data, streaming parsers (`jq -c` over JSONL, `csv` readers row-by-row), not `json.load` on a 2 GB file.
- In code you write, default to iteration for unbounded inputs: `for line in f:` (Python), `readline`/streams (Node), `bufio.Scanner` (Go, mind the token limit). Reserve `read()`/`readFileSync` for files you know are small — configs, source files.
- Logs, dumps, exports, fixtures with `data` in the path, and anything user-uploaded are unbounded until proven otherwise.
- If the task truly needs full-file processing (sorting, global dedup), say so and use disk-backed tools (`sort`, `split`) rather than RAM.

**Red flags that you're about to violate this:**

- "I'll read the file and see what's in it." (How big is it?)
- "json.load is the normal way to read JSON."
- "It worked on the test file." (The test file was 2 KB; production is 2 GB.)
- "I need the whole file to change line 30,000." (sed disagrees.)
- "Memory is cheap." (Not at 3 a.m. when the box is swapping.)

### Edit Files, Don't Fork Them

When the task is to change a file, change THAT file. NEVER create a renamed copy (`_v2`, `_new`, `_fixed`, `_improved`, `-old`) as a way of making changes "safely."

A modified copy is dead code with a confusing name: nothing imports it, the original keeps running unfixed, and the repo now has two diverging versions of the truth.

- Fix `auth.py` in `auth.py`. The original is preserved by git, not by leaving a stale twin in the directory.
- The same applies inside files: replace the old implementation rather than leaving it commented out above the new one, and don't add `doThingNew()` beside `doThing()` unless a staged migration is the explicit plan.
- Creating a new file is correct when the task is genuinely additive — a new module, a split-out class, a new test file. The test: will other code reference the new file, and does the old file keep its own ongoing purpose? If the new file only exists to hold "the better version" of an existing one, it's a fork.
- If a rewrite is risky enough that you want the old version available, that's what branches and the unstaged diff are for; say so instead of encoding the rollback plan into filenames.
- Renaming as part of a real refactor is fine — but then complete it: update every reference and remove the old name in the same change, so exactly one version exists afterward.
- Before finishing, check `git status` for new files whose names are an existing file plus a qualifier. Any such file means you forked; merge it back into the original and delete it.

**Red flags that you're about to violate this:**

- "I'll put my version in a new file so nothing breaks." (Nothing changes, either.)
- "The user can diff the two files and pick."
- "I'll keep the old function commented out, just in case."
- "Naming it _v2 makes the improvement clear."
- "Editing the original feels destructive." (Git makes it perfectly reversible.)

### Edit Sources, Not Build Outputs

NEVER edit build outputs. If a grep hit lands in `dist/`, `build/`, `out/`, `target/`, `.next/`, `public/assets/`, a `*.min.*` file, or anything with a sourcemap comment, the edit belongs in the source that generates it.

A fix applied to an artifact lasts exactly one build. Then it's gone, and the bug is back with your name nearby.

- Identify outputs before editing: output directories above; minified or single-line files; files referenced by `// sourceMappingURL`; compiled forms of adjacent sources (`.js` next to the `.ts` that produces it, `.css` next to `.scss`).
- Trace the hit back: search the same string (or its unminified equivalent) under `src/`, check the build config (`webpack.config.js`, `vite.config.ts`, `tsconfig.json` `outDir`) to learn what compiles to where.
- Fix the source, run the build, verify the output changed. If the output is checked in, commit the regenerated artifact together with the source change — never the artifact alone.
- If the string exists only in the artifact and nowhere in source, the source is generated elsewhere (a dependency, a CMS, codegen) — find it, don't patch the bundle.
- Exclude output dirs from your searches up front (`grep -r --exclude-dir=dist --exclude-dir=build`, or rely on `.gitignore`-aware search) so the tempting wrong answer never appears.

**Red flags that you're about to violate this:**

- "The grep hit is in dist/, I'll fix it right there."
- "Editing the bundle is faster than running the build."
- "I'll patch the minified file carefully; it's just one string."
- "The .js file is right next to the .ts file, I'll edit whichever."
- "It works after my edit, so the fix is in the right place."

### Extract Archives Safely

NEVER extract an archive without ensuring every entry resolves inside the target directory. Entry names are untrusted input that extraction executes as write paths.

A hostile entry named `../../.ssh/authorized_keys` or `/etc/passwd`, extracted naively, writes exactly there. This is zip-slip; the result is arbitrary file overwrite.

- In code you write: validate each entry before writing it. Join the entry name to the destination, resolve it (`os.path.realpath`, `filepath.Clean` + prefix check, `Path.resolve()`), and require the result to be inside the destination. Reject absolute paths, `..` components, and drive letters.
- Use the safe API where one exists: Python `tarfile.extractall(path, filter="data")` (refuses traversal, absolute paths, dangerous types); prefer maintained extraction libraries over hand-rolled entry loops in any language.
- Symlinks and hardlinks in archives are part of the attack surface: a link targeting outside the tree, followed by entries extracted through it, escapes your prefix check. The `data` filter handles this; manual code must check link targets too.
- Inspect before extracting anything untrusted: `tar -tf archive.tar.gz | grep -E '^/|\.\.'` and `unzip -l archive.zip` cost seconds and show hostile paths before they execute.
- Extract into a fresh, empty, dedicated directory — never directly into a repo root, `$HOME`, or anywhere a misbehaving entry has interesting targets to overwrite.
- Also sanity-check the unpacked size or entry count for untrusted input; decompression bombs ride the same code path.

**Red flags that you're about to violate this:**

- "It's just a zip from the build artifact store; extractall is fine."
- "Path traversal in archives is a theoretical attack."
- "I'll extract first and clean up anything weird after." (After is too late; the writes happened.)
- "The library probably handles this." (Verify; the stdlib historically didn't.)
- "I'm only extracting it to look inside." (Looking is `tar -tf`. Extracting is writing.)

### Glob with Intent

ALWAYS know what a glob excludes and includes before acting on its matches. `*` skips dotfiles; `**` includes `node_modules`. Both defaults are wrong for half the things people use them for.

A glob feeding a bulk operation is a query you never reviewed; preview the result set before mutating it.

- Moving or copying "everything"? `*` misses dotfiles. Use the directory itself as the unit (`cp -a src/. dest/`, `mv src dest`, `rsync -a src/ dest/`), or enable `shopt -s dotglob` deliberately.
- Recursing over a repo? Exclude the standing junk: `node_modules`, `.git`, `dist`, `build`, `vendor`, `coverage`, `__pycache__`, `.venv`. Prefer tools that respect `.gitignore` by default (`rg`, `fd`, `git ls-files`) over raw `find`/`grep -r`.
- Before a destructive or bulk-mutating command, preview the match list: `echo <glob>`, `ls -d <glob>`, or run the `find` without `-exec` first. Count it; if "all our source files" comes back as 48,000, your glob found the dependency tree.
- A glob with zero matches passes itself through literally in some shells (a file named `*.bak` is not what you want to operate on). Use `nullglob` in scripts, or check the match count.
- Character ranges and brace expansions deserve a test: `[A-z]` matches punctuation; `{a,b}` is brace expansion, not a glob, and behaves differently in `find -name`.
- In code, know your library's flags: Python `glob` needs `recursive=True` for `**`; many JS globbers need `dot: true` for dotfiles.

**Red flags that you're about to violate this:**

- "Star means everything." (It means everything visible.)
- "I'll run the replace across **/*.ts — that's our source." (And your node_modules.)
- "No need to preview; the pattern is obviously right."
- "The copy succeeded, so everything came across."
- "grep -r * covers the whole tree." (Minus every dotfile and dot-directory at the top.)

### Keep Scratch Files Out of the Repo

NEVER write temporary files — debug scripts, scratch output, repro cases, notes — into the repository tree. Use the system temp directory.

Everything inside the repo shows up in `git status`, gets swept into commits, and gets collected by test runners. The repo tree is for deliverables.

- Put scratch work in `/tmp` (or `$TMPDIR`, `mktemp -d`): `/tmp/repro.sh`, not `./repro.sh`.
- Especially never create files matching test-discovery patterns (`test_*.py`, `*.test.js`, `*_test.go`) inside the repo unless they are real tests meant to be kept — runners will execute them.
- Need to run a quick experiment against repo code? Run it from `/tmp` with the repo on the import path, or use the language REPL / a one-liner (`python -c`, `node -e`) that creates no file at all.
- If you genuinely must drop a temporary file inside the tree (a fixture a tool insists on finding locally), delete it before finishing the task, and verify with `git status` that the working tree contains only intended changes.
- Generated debugging output (logs, dumps, screenshots) follows the same rule: temp directory, not repo.
- Before declaring any task done, run `git status`. Every untracked file should be either part of the deliverable or gone.

**Red flags that you're about to violate this:**

- "I'll just drop a quick script here to test this."
- "I'll clean these up at the end." (You won't; the end is about the fix.)
- "It's untracked, so it doesn't hurt anything."
- "The user can ignore the extra files."
- "Naming it test_debug.py makes it obvious it's temporary." (It makes it collectible.)

### Leave No Backup Droppings

NEVER leave `.orig`, `.bak`, `.rej`, `*~`, or ad-hoc backup copies in the working tree. In a git repo, git is the backup; redundant safety copies are clutter that gets committed by accident.

- Don't create defensive copies before editing tracked files (`cp file file.bak`, `config.old.py`, `utils_backup.py`). The pre-edit state is already recoverable via `git diff` / `git checkout --`.
- Know which commands shed files and stop them at the source: use `sed -i` without a backup suffix deliberately (GNU: `sed -i`; macOS/BSD: `sed -i ''` — they differ, check which you're on), and clean up `.orig`/`.rej` after `patch` or merge operations as part of the same task.
- If you genuinely need a scratch copy (comparing against an untracked file's previous state), put it in `/tmp`, not next to the original.
- Backup-suffixed files keep dangerous properties: `app_backup.py` is importable, collectible by test runners, and findable by grep — stale code that still participates in the codebase.
- Before finishing any task, run `git status` and scan for dropping patterns: `*.orig`, `*.bak`, `*.rej`, `*~`, `*backup*`, `*.old`. Anything matching that you created, delete. Anything matching that you found pre-existing, mention rather than silently keep or delete.
- Do not "solve" this by adding the patterns to `.gitignore` — that hides the clutter instead of removing it, and ignore rules are a separate decision for the repo owner.

**Red flags that you're about to violate this:**

- "I'll keep a copy just in case the edit goes wrong." (git exists.)
- "sed -i.bak is the safe habit." (It's the littering habit in a repo.)
- "The .orig files don't hurt anything sitting there."
- "I'll clean them up at the end." (Then actually do: `git status` before declaring done.)
- "Better to leave the backup; deleting files feels risky." (Deleting your own redundant copy is hygiene, not risk.)

### Look Before You Overwrite

NEVER write "new" content to a path you haven't confirmed is vacant. Creating a file and replacing a file are the same syscall; only checking first makes them different intents.

- Before creating any file, check the target: `ls` the directory or test the exact path. Do this at creation time, not from memory of a listing taken earlier in the session — directories change, including by your own hand.
- If the path is occupied, stop and choose deliberately: the task may actually be "extend the existing file" (most common — add your function to the existing `utils.ts`), or the new content belongs under a different name, or replacement is truly intended and you can say so before doing it.
- Conventional names are collision magnets: `utils`, `helpers`, `config`, `constants`, `types`, `index`, `setup`, `main`. Assume these exist until proven otherwise.
- The same rule covers copies and moves: `cp` and `mv` overwrite existing destinations without a murmur. Use `mv -n`/`cp -n` (no-clobber) or check the destination when the target directory isn't fully known to you.
- Watch for near-collisions too: creating `DateUtils.ts` beside an existing `dateUtils.ts` doesn't overwrite anything on your filesystem but will on a case-insensitive checkout (see the case-sensitivity rule) — and it's a fork either way.
- An overwrite of uncommitted content is the unrecoverable case. Treat any dirty working tree as a minefield for blind writes.

**Red flags that you're about to violate this:**

- "It's a new file, so there's nothing to check."
- "I listed that directory earlier; there was no dates.ts." (Earlier isn't now.)
- "utils.ts is such a generic name, I'll just create it."
- "If something was there, the write tool would have warned me." (It didn't, and it won't.)
- "Worst case, git has it." (Uncommitted changes say otherwise.)

### Match File Extensions to Content

ALWAYS make the extension tell the truth about the format. Every downstream tool — parsers, loaders, linters, editors, test discovery — dispatches on the suffix and trusts it completely.

- The strict ones bite hardest: `.json` means strict JSON — no comments, no trailing commas, one top-level value. Comments need `.jsonc`/`.json5` (only if a consumer actually supports it); line-delimited records need `.jsonl`/`.ndjson`.
- Don't follow directory peer pressure: content in format X gets X's extension even if every sibling file is format Y.
- Executable content gets an executable's extension: shell scripts are `.sh` (or extensionless with a shebang), not `.txt`. Python is `.py`, not `.txt` "notes that happen to run."
- `.ts` vs `.js`, `.tsx` vs `.jsx`, `.scss` vs `.css`: these are different languages to the toolchain. Type annotations in a `.js` file and JSX in a `.js` file (in configured-strict projects) are build failures.
- Templated files name both layers: `config.yaml.j2`, `index.html.erb` — naming it `.yaml` invites someone (or some tool) to parse the template syntax as YAML.
- Honor project-specific conventions you observe (`.spec.ts` vs `.test.ts`, `.module.css`) — these suffixes trigger different pipelines, not just different names.
- Before finishing, sanity-parse anything you created: `jq . <file>.json`, `bash -n <file>.sh`, a YAML load. If the canonical parser rejects it, the content or the name is wrong; fix whichever lies.

**Red flags that you're about to violate this:**

- "I'll add a few comments to this .json config for clarity."
- "The other configs here are .json, so this one should be too." (It's YAML.)
- ".txt is fine; the user will know to run it as a shell script."
- "It's mostly JSON." (Parsers don't grade on a curve.)
- "The extension is cosmetic."

### Never Append to Structured Files

NEVER append to a file in a structured format (JSON, XML, TOML, YAML, INI, HTML) with `>>` or any blind append. Insert at the structurally correct position instead.

Strict formats have closing delimiters and positional meaning; bytes after `}` or `</root>` invalidate the entire file, and "the end" is almost never where new content belongs.

- For JSON/XML/TOML: read the file, insert inside the correct object, array, or element, write the result. Better, use the format's own tooling: `npm pkg set`, `jq`, `yq`, `crudini` — they cannot produce unparseable output.
- For YAML and INI, position is semantics. A key appended at the bottom is top-level (YAML) or in the last section (INI), not where you intended. Insert under the right parent.
- True append-friendly formats exist: logs, JSONL/NDJSON, and usually CSV. Even there, confirm the file ends with a newline first, or your first appended record merges with the last existing one.
- Same rule for "prepend": shebang lines, XML declarations, BOMs, and `"use strict"` directives must stay first; never insert above them.
- After any structural edit, validate: `jq . file.json`, `python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))"`, `xmllint --noout`. One second of parsing beats a broken build.

**Red flags that you're about to violate this:**

- "Appending is safer because I'm not modifying existing content."
- "I'll echo the new entry onto the end; the format is forgiving." (JSON forgives nothing.)
- "It's just one config key, no need to parse the whole file."
- "The new YAML key can go at the bottom."
- "I'll skip validation; the change was tiny."

### Never Edit Binary Files as Text

NEVER read, write, or string-replace a binary file with text tools. Binary formats have offsets, checksums, and length fields; a text-pipeline round trip corrupts them even when the visible change looks right.

- Check before touching anything that isn't clearly source/config: `file <path>` identifies the format; `grep -Il . <path>` (capital i, lowercase L) prints the name only for text. Extensions help but lie — check when in doubt.
- Binary includes the disguised cases: `.docx`/`.xlsx`/`.pptx` (zip archives), `.pdf`, `.sqlite`/`.db`, `.pyc`, `.class`, `.woff2`, `.ico`, pickles, protobuf blobs. "I can see strings in it" does not mean "I can edit strings in it."
- Modify binary formats with their own tooling: `sqlite3` for SQLite, `python-docx`/`openpyxl` for Office files, image libraries for images, `zip`/`tar` for archives. If no tool is available, say so — don't improvise with sed.
- Keep binaries out of bulk text operations: filter `find`-driven `sed`/replace runs by extension or by `grep -Il`, and never run "normalize line endings/whitespace" over a directory containing binaries.
- Copy binaries with byte-faithful tools (`cp`, `rsync`), never through text-mode reads, shell `$(cat ...)` capture, or anything that decodes.
- If you've already mangled one: restore from git or backup. There is no hand-fixing a corrupted binary.

**Red flags that you're about to violate this:**

- "I can see the string I need right there in the grep output."
- "It's mostly text with some weird characters."
- "sed across the whole directory will catch all the configs." (And the .png in the fixtures folder.)
- "The file still opens, so the edit worked." (Some formats fail lazily, on the page you didn't check.)
- "I'll just fix the byte I changed back." (The write already re-encoded the rest.)

### Never Hardcode Absolute Paths

NEVER write a machine-specific absolute path into code, tests, scripts, or config. Paths like `/home/<user>/...`, `/Users/<user>/...`, `C:\Users\...`, and `/tmp/<your-session>/...` are facts about your current machine, not about the project.

Code containing your absolute path works exactly once: here, now. It breaks on CI, on teammates' machines, and in containers.

- Derive paths from a stable anchor instead: the script's own location (`Path(__file__).parent`, `path.dirname(__dirname)` patterns, `$(dirname "$0")`), the project root, or an environment variable with a sane default.
- In tests, resolve fixtures relative to the test file or use the framework's tmp-dir facility (`tmp_path`, `t.TempDir()`, `os.tmpdir()`), never a literal `/tmp/test1` or a repo-absolute path.
- In config files, prefer relative paths from the config's own location, or document an env var. If an absolute path is genuinely required (system daemons, deploy targets), it belongs in deployment config with a comment saying why, not in the codebase default.
- Using absolute paths in your own shell commands during the session is fine; the rule is about what you write into files that get committed.
- Before finishing, grep your changes for your own username and working directory. Any hit is a bug.

**Red flags that you're about to violate this:**

- "I'll use the full path so it definitely resolves."
- "The test passes with this path, ship it."
- "Everyone's checkout is probably in a similar place."
- "I'll make it relative later; absolute is fine for now."
- "It's just a default; users can override it."

**Self-check before finishing:** `grep -rn "$HOME\|/Users/\|C:\\\\Users" <changed files>` should return nothing.

### Don't Create Hostile Filenames

ALWAYS name files using only lowercase letters, digits, hyphens, underscores, and dots: `test-results-final.md`, not `Test Results (final).md`.

A filename is an identifier consumed by shells, build tools, globs, and URLs. Every character outside the safe set is a parsing hazard in some tool the repo already uses.

- No spaces. They split words in every unquoted shell context: `$(ls)` loops, xargs without `-0`, Makefile prerequisites (which cannot portably contain spaces at all).
- No shell metacharacters: `( ) ' " ` $ & ; ! * ? [ ] < > |` — each is syntax somewhere.
- No Windows-forbidden characters (`: * ? " < > |`), no reserved basenames (`CON`, `PRN`, `NUL`, `COM1`, `aux` — even with an extension), no trailing dot or space. One such file makes the repo fail to check out on Windows.
- No leading dash (`-f.txt` is a flag to most tools) and no leading/trailing whitespace or non-breaking spaces.
- Match the directory's existing convention (kebab-case vs snake_case) rather than introducing a second style.
- These rules cover files you create or rename. Existing hostile names are a cleanup task to flag, not silently fix — references break when names change.

**Red flags that you're about to violate this:**

- "A space makes the name more readable."
- "Parentheses distinguish the version nicely."
- "It's just a doc, no script will ever touch it." (Backup scripts, `find`, and CI artifact globs touch everything.)
- "Windows reserved names are ancient history." (They're enforced in current Windows.)
- "I'll quote it properly everywhere I use it." (You don't control everywhere.)

### Preserve Executable Bits and Permissions

NEVER let an edit change a file's permission bits. A rewrite of `deploy.sh` must leave it exactly as executable as it was.

Permissions are invisible in content but tracked by git and enforced by the OS: a dropped exec bit turns a working script into `Permission denied` for everyone who pulls.

- Prefer in-place edits, which preserve the inode and its mode. If you must recreate a file (temp-and-rename, delete-and-rewrite), capture the mode first (`stat -c %a`, or `ls -l`) and restore it (`chmod --reference=` or explicit `chmod 755`).
- When creating a new script that will be invoked directly — anything with a shebang, anything in `scripts/`, `bin/`, or `.git/hooks/`-adjacent directories — `chmod +x` it as part of creation, not as a follow-up you might forget.
- After editing any script, check `git diff` for a `mode change 100755 => 100644` line (or the reverse). That line is a bug unless changing the mode was the task.
- Don't compensate for a missing exec bit by changing the invocation (`bash script.sh` instead of `./script.sh`) — that masks the symptom for you while leaving it broken for documented usage, hooks, and CI.
- Special permission cases deserve special care: private keys and secrets files are often `600` on purpose; making one group-readable is a security regression, and some tools (ssh, postgres) hard-fail on loose modes.

**Red flags that you're about to violate this:**

- "I'll just recreate the file; same content, same file."
- "I'll run it with `bash` explicitly, so the exec bit doesn't matter."
- "Permissions are an environment thing, not a code thing." (Git commits the exec bit.)
- "I'll chmod it later if something complains."
- "The diff only shows my content change." (Look for the mode line.)

### Preserve Line Endings When Editing

NEVER change a file's line endings unless changing line endings is the explicit task. An edit to line 40 must leave the line endings of lines 1 through 39 and 41 onward byte-identical.

Line endings are invisible in most views but fully visible to git, parsers, and interpreters. Normalizing them as a side effect turns a one-line fix into a whole-file diff and can break scripts outright.

- Before editing, detect what the file uses: `file <path>` or `grep -c $'\r' <path>`. Match it.
- If the file is CRLF, your new or edited lines must also be CRLF. Do not write LF lines into a CRLF file "because the diff will be normalized anyway" — check `.gitattributes` before assuming that.
- Shell scripts (`.sh`), shebang'd files, and Makefiles must stay LF. Windows batch files (`.bat`, `.cmd`) and some `.sln`/`.csproj` tooling expect CRLF. When creating a new file, follow the platform convention of its consumers, then `.gitattributes`, then the repo majority, in that order.
- After editing, verify the diff: if `git diff --stat` shows the whole file changed for a small edit, you almost certainly flipped line endings. Fix it before moving on, not after the user notices.
- A file with mixed line endings is suspicious but not yours to clean. Preserve the mix unless asked.

**Red flags that you're about to violate this:**

- "I'll normalize to LF while I'm in here; CRLF is legacy anyway."
- "The diff shows every line changed, but my edit is in there somewhere, so it's fine."
- "Git will sort out line endings on commit."
- "It's easier to rewrite the file with consistent endings than match the existing ones."
- "Nobody can see line endings, so nobody will care."

### Resolve Paths, Don't Assume the CWD

NEVER write code or run commands whose correctness depends on an unverified current working directory. Anchor every relative path to something stable.

The cwd is set by the caller, not by you, and every invoker — cron, CI, a user in a subdirectory — sets it differently.

- In scripts, resolve relative to the script's own location: `SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)` in bash, `Path(__file__).resolve().parent` in Python, `__dirname`/`import.meta.url` in Node. Then build paths from that anchor.
- In application code, resolve relative to an explicit root passed in via argument, env var, or config — not whatever `process.cwd()` happens to be, unless cwd-relative is the documented contract (CLI tools acting on the user's directory).
- In your own shell work, prefer absolute paths in commands. Don't carry cwd assumptions across multiple commands; a `cd` earlier in the session is state you'll forget. Verify with `pwd` if anything depends on it.
- `cd` inside scripts changes state for everything after it; if you must, use a subshell `(cd dir && ...)` so the change can't leak.
- Files you create land relative to the cwd too: a "local" output file written from the wrong directory is a stray artifact in a random location.
- Before shipping a script, ask: what happens if this runs from `/`? If the answer is "breaks" or "writes somewhere weird," anchor the paths.

**Red flags that you're about to violate this:**

- "It works when I run it from the repo root, and that's how people run things."
- "I cd'd earlier, so relative paths are fine from here."
- "The config file is at ./config.yaml." (Relative to what, exactly?)
- "Cron will run it the same way I did."
- "I'll fix the paths if someone hits a problem."

### Respect Locks and Concurrent Editors

NEVER write a file based on a stale read. If time, other commands, or another actor may have touched a file since you read it, re-read it before writing.

You are not the only writer. Users edit in parallel, formatters fire on save, watchers regenerate, and other agents act; a write composed from an old snapshot silently erases all of it.

- Re-read before write when there's a gap: if you read a file more than a few steps ago — or ran anything that could modify files (formatters, codegen, `npm install`, test runners with snapshot-update) — refresh before editing.
- Targeted edits beat whole-file writes here too: replacing a unique string fails loudly if the file changed underneath you (the anchor is gone); a full-file write from stale memory fails silently and destructively.
- If an edit fails because the expected text isn't there, that's evidence of concurrent change. Re-read and reconcile; never force the write or retry harder with a looser match.
- Treat lock artifacts as occupancy signals: `.~lock.*#` (LibreOffice), `.<name>.swp` (vim), `~$<name>` (Office). Don't edit the locked file and never delete the lock to get past it; ask, or wait.
- Mid-operation files are off limits: a lockfile during `npm install`, a database file under a running server, a log being written. Editing them races the owning process.
- After your write, if `git diff` shows reverted hunks you didn't intend — changes disappearing, not appearing — you clobbered someone. Restore their work first, then redo yours on top.

**Red flags that you're about to violate this:**

- "I read this file earlier; I know what's in it."
- "I'll write the version I've been planning." (Planned against what's still there?)
- "My string-replace didn't match, so I'll just rewrite the whole file."
- "That .swp file is probably leftover junk."
- "The user wouldn't edit while I'm working."

### Respect Filename Case Sensitivity

ALWAYS match the exact on-disk casing in every file reference: imports, requires, asset URLs, include paths, config entries. NEVER infer casing from naming conventions.

Case-insensitive filesystems (macOS and Windows defaults) forgive mismatches that case-sensitive ones (Linux, every CI runner, every container) do not. The bug is undetectable on the machine that wrote it.

- Before writing an import or path reference, verify the real name with a directory listing (`ls`), not from memory and not from the symbol's casing. `userProfile.tsx` and `UserProfile.tsx` are different files on Linux.
- When creating a file, follow the directory's existing casing convention exactly. Don't introduce `PascalCase.ts` into a `kebab-case.ts` directory or vice versa.
- Never rename a file changing only its case in a single step on macOS/Windows; git may miss it. Use `git mv File.js temp && git mv temp file.js`, or `git mv -f` where supported.
- Treat near-miss grep results as alarms: if searching for the exact path returns nothing but a case-insensitive search (`grep -ri`) hits, you have a latent Linux-only break — flag it.
- This applies beyond imports: webpack/Vite asset paths, `#include` headers, Dockerfile `COPY` sources, YAML pipeline file references, and test fixture paths all resolve case-sensitively somewhere in the pipeline.

**Red flags that you're about to violate this:**

- "The component is PascalCase, so the file must be too."
- "It resolved locally, so the path is correct."
- "I'll just rename the file to match my import instead." (Now you've made a case-only rename. See above.)
- "Case doesn't matter for filenames."
- "CI is failing on a module that obviously exists."

### Respect Trailing Newline Discipline

Preserve each file's final-newline state exactly, unless changing it is the task. When creating files, end text files with exactly one newline.

The last byte is invisible in every rendered view and visible to git, linters, snapshot tests, and every line-oriented Unix tool.

- When editing the last line of a file, reproduce its terminator state: if the file ended with a newline, it still does; if it didn't, it still doesn't. `tail -c 1 <path> | xxd` settles any doubt.
- Watch the diff: a `\ No newline at end of file` marker appearing in (or disappearing from) `git diff` on a file where you didn't intend to touch the ending means you flipped it. Fix before finishing.
- New text files: one trailing newline, no more. Multiple blank lines at EOF are churn bait for formatters.
- Honor project config: if `.editorconfig` sets `insert_final_newline` or Prettier governs the file, follow it for new content but still don't mass-fix existing files you weren't asked to touch.
- Files compared byte-for-byte — golden files, snapshots, fixtures with `expected` in the name — are exact artifacts. Never "normalize" their endings; you'll fail the very tests they exist for.
- Shell heredocs and `printf`-composed files are easy to get wrong by one `\n`. Verify the last byte when composing files that other tools parse.

**Red flags that you're about to violate this:**

- "A missing final newline is a mistake; I'll fix it while I'm here."
- "That diff marker about no newline is noise."
- "One newline, two newlines, whatever ends the file."
- "Snapshot files are text like any other text."
- "The file looks identical, so it is identical."

### Use Portable Path Separators

NEVER build file paths by concatenating strings with a hardcoded `/` or `\`. Use the language's path API.

A hardcoded separator encodes your current OS into the code; the failure only manifests on the OS you're not testing on.

- Join with the platform API: `os.path.join` / `pathlib` (Python), `path.join` (Node), `filepath.Join` (Go), `Path.Combine` (C#), `PathBuf::push` (Rust).
- Split and compare with the same APIs: `path.sep`, `os.path.normpath`, `filepath.ToSlash`. Never `split("/")` on a path that came from the filesystem.
- Backslashes in string literals are escape sequences in most languages. `"C:\temp\new"` contains a tab and a newline. If you must write a Windows path literal, use raw strings (`r"..."`) or forward slashes where the API accepts them.
- Know the exceptions that are always forward-slash regardless of OS: URLs, glob patterns in most libraries, paths inside zip/tar archives, Docker image paths, import specifiers, and `.gitignore` patterns. Don't "fix" those to `os.sep`.
- In shell scripts and Makefiles, forward slashes are correct; the portability problem there belongs to the tool invocations, not the separator.
- When a path crosses a boundary (written to JSON consumed on another OS, compared against user input), normalize explicitly and say to what.

**Red flags that you're about to violate this:**

- "String concatenation is simpler than importing the path module."
- "This project is Linux-only anyway." (Check whether developers use Windows or WSL.)
- "I'll split on '/' because that's what paths look like."
- "The backslash literal worked when I tested it." (You tested on the OS where it parses.)
- "I'll normalize everything to backslashes for Windows." (Forward slashes work in most Windows APIs; backslashes break everywhere else.)

### Write Atomically for Live Readers

When writing a file that another process may read — configs under a watcher, data files consumed by services, anything a daemon, cron job, or dev server reloads — NEVER write it in place. Write to a temp file and rename over the target.

In-place writes expose intermediate states: zero bytes at truncation, partial content during buffering. Atomic rename guarantees readers see old-complete or new-complete, nothing between.

- The idiom: write fully to `<target>.tmp.<pid-or-random>` in the same directory as the target (rename isn't atomic across filesystems, and `/tmp` is often a different one), flush/fsync, then `mv`/`os.replace()`/`fs.rename()` onto the target.
- Same-directory matters; so does completing the write (close the handle, sync if durability matters) before renaming.
- Carry over the original's permissions and ownership to the temp file before the rename — atomicity that resets the mode trades one bug for another.
- This applies to code you author, too: any config-save, cache-write, or state-persist routine that other processes consume should use write-temp-rename, not `open(path, "w")`.
- Know when it's needed: live readers, watchers, hot reload, multi-process access. A source file only you and git touch doesn't need the ceremony — and for symlinked targets note the rename replaces the link, so resolve real paths first (see the symlink rule).
- Appending to a log is a different contract (appends are atomic up to a size); this rule is about whole-file replacement.

**Red flags that you're about to violate this:**

- "The write takes milliseconds; nothing will read during it."
- "I read the file back and it's complete, so the write was fine." (You read it after the window closed.)
- "The watcher crashing occasionally is probably its own bug."
- "Temp-and-rename is overkill for a config file." (Configs under watchers are the canonical case.)
- "I'll write to /tmp and rename from there." (Cross-filesystem rename isn't atomic; it decays to copy-then-delete.)

### Add Changelog Entries for User-Facing Changes

ALWAYS add a changelog entry when your change affects users, if the repo maintains a changelog. The entry is part of the change, not an optional garnish.

The problem: changelog gaps are invisible at commit time and unrecoverable at release time, when nobody remembers what shipped.

Rules:
- Before finishing, check whether the repo has `CHANGELOG.md`, `CHANGES.rst`, a `changelog.d/` fragments directory, or a documented changelog convention
- A change is user-facing if it alters behavior, output, defaults, flags, config, public APIs, error messages, or performance someone would notice. Internal refactors with identical behavior are not
- Add the entry to the Unreleased (or current dev) section, following the file's existing format exactly: same heading levels, same categories (Added/Changed/Fixed), same entry style
- If the repo uses changelog fragments (towncrier, changesets), create the fragment file instead of editing the main changelog
- One entry per logical change, written for the user who upgrades, not the developer who committed
- If you genuinely cannot tell whether the project wants an entry, say so explicitly instead of silently skipping it
- Do not invent a changelog file in a repo that has none; that is a maintainer decision

**Red flags that you're about to violate this:**
- "It's a small fix, not changelog-worthy..."
- "The commit message already explains it..."
- "Someone will batch-update the changelog at release time..."
- "The user didn't ask me to touch the changelog..."
- "I'm not sure which section it goes in, so I'll skip it..."
- "The changelog looks neglected anyway..."

### Avoid Temporal Language in Docs

NEVER write documentation that's only true from the vantage point of the day you wrote it. Docs are read in the future; write claims that are either timeless or explicitly dated.

The problem: words like "currently", "new", "recently", and "soon" smuggle an invisible timestamp into prose. The claim rots; the confident tone doesn't.

Rules:
- State facts plainly without temporal hedges: "Supports Redis" not "currently supports Redis". If Redis support ends, the doc needs editing either way; "currently" only adds doubt while it's true
- Never describe features as "new", "recently added", or "the latest". Tie facts to versions instead: "Available since v2.3" stays true forever
- Never write "coming soon", "planned", or "in a future release" unless the user told you it's planned; you are not authorized to make roadmap promises, and unscheduled "soon" is the longest word in software
- When a limitation is genuinely temporary and tracked, reference the tracker, not the calendar: "Not yet supported (see #512)" gives readers a live status source
- Replace "as of now"/"at the time of writing" with the actual version or date if the time-boundedness matters, or restructure so it doesn't
- "Currently" is sometimes honest in design docs and proposals, which are inherently dated artifacts; this rule is about reference docs, READMEs, and guides that claim present truth

**Red flags that you're about to violate this:**
- "Calling it new highlights the recent work..."
- "'Currently' is accurate, it does only support Redis right now..."
- "'Coming soon' softens the missing feature..."
- "Readers will know roughly when this was written..."
- "I'll mention the roadmap to be helpful..."
- "'As of this writing' covers me..."

### Comment the Why, Not the What

NEVER write a comment that restates what the adjacent code visibly does. A comment must add information the code cannot express: the reason, the constraint, the trap, or the rejected alternative.

The core problem: paraphrase comments add zero information, rot when the code changes, and make a file look documented while the real decisions go unexplained.

Do:
- Document non-obvious constraints: `# API caps page size at 100; do not raise this`
- Document why the obvious approach was rejected: `// Can't use Set here: order matters for the diff`
- Document external facts the code depends on: timeouts, vendor quirks, protocol rules, legal requirements
- Document intentional weirdness so nobody "fixes" it: `// Deliberately swallows the error; see retry loop below`

Don't:
- Translate code into English: `// Return the result` above `return result`
- Restate names: `// UserService handles users`
- Describe control flow the reader can see: `// If valid, save; otherwise throw`
- Pad code with comments to appear thorough

If you know no why, write no comment. An uncommented line is honest; a paraphrase is filler that someone must read, doubt, and maintain.

**Red flags that you're about to violate this:**
- "A brief comment here will make this easier to follow..."
- "I'll label each step of the function..."
- "This block looks bare without a comment..."
- "Describing what this does counts as documentation..."
- "I don't know why it's written this way, but I can at least say what it does..."
- "More comments will make this look well-documented..."

### Don't Delete Docs You Think Are Redundant

NEVER delete a documentation file unless the user explicitly asked for that file's deletion. Judging a doc "redundant," "outdated," or "superseded" is not your call to make unilaterally.

The problem: redundancy is a claim about every consumer of a doc, and you can see none of them. Similar-looking docs usually exist because of their differences, not despite their similarities.

Rules:
- If you believe a doc is redundant, say so and propose deletion with your evidence: "These two files cover the same setup; the older one references a removed flag. Delete it?" Then wait
- "Clean up the docs" means fix, organize, and de-conflict, not delete; treat deletion as outside that scope unless named
- Before proposing deletion, check for inbound references: links from other docs, code comments, scripts, configs. Report what you find
- Content that exists nowhere else must be merged into a surviving doc before its file can go; deletion and preservation are one operation, not a deletion with a follow-up
- Stale is not redundant. A wrong doc should be fixed or marked, not vanished; its history may be the only record of how something used to work
- Never delete a doc as a side effect of another task. If a doc became obsolete because of your change, flag it and let the user decide

**Red flags that you're about to violate this:**
- "These two docs say basically the same thing..."
- "This file is clearly outdated, removing it is a favor..."
- "The user said clean up, and deletion is the cleanest..."
- "Nothing in the repo links to it..." (the repo is not the only place links live)
- "I merged the important parts, so the original can go..."
- "Fewer files is objectively better..."

### Don't Document Behavior You Haven't Verified

NEVER write documentation stating how the system behaves unless you verified that behavior against the actual code, config, or output. Plausible is not verified.

The problem: documentation hallucination produces confident, specific, wrong claims that readers treat as ground truth precisely because they are written down.

Rules:
- Before documenting a default, limit, timeout, ordering, or format, find the line of code or config that defines it, and document what that line says
- Before documenting what a command or endpoint returns, run it or read the code path that produces the response; do not document from the function name
- Distinguish your sources in your own head: read-the-code facts, ran-it facts, and assumed facts. Only the first two go in docs as statements
- If something can't be verified right now (external service, missing credentials), either omit it or mark it visibly: "Unverified: appears to retry 3 times based on `MAX_ATTEMPTS`"
- Never let general knowledge fill gaps. What caching layers, queues, or ORMs "usually do" is not what this one does
- Specific numbers are the highest-risk claims. Every concrete value in your doc needs a concrete source in the repo

**Red flags that you're about to violate this:**
- "This is how these systems typically work..."
- "The function name implies it returns JSON..."
- "I'll fill in a reasonable default value..."
- "Checking the actual code would take too long for a doc..."
- "It almost certainly retries; everything retries..."
- "The doc reads better with a specific number..."

### Don't Document Internal APIs as Public

NEVER document internal APIs, private helpers, or unexported symbols in user-facing documentation. Documenting something is publishing a support contract for it.

The problem: docs are read as promises. An internal function with a reference page and a usage example will acquire external callers, and then it can never be safely changed again.

Rules:
- Respect the project's visibility signals: underscore prefixes, `internal/` or `private/` paths, missing exports, `@internal`/`@private` annotations, symbols absent from `__all__` or the public index. None of these belong in user docs
- "Document the API" means the public API. If the boundary is ambiguous, ask or state your assumption: "I documented exported symbols only"
- Endpoints under `/internal/`, admin routes, and debug interfaces don't go in API references, even though they technically respond to requests
- If users genuinely need something that's currently internal, that's a finding to raise ("`_retry_policy` seems needed for X but is private"), not a license to document it as available
- Internal docs are fine in internal places: contributor guides and architecture docs can and should describe internals, clearly framed as implementation that may change
- When documenting a public function, don't leak internals through it: examples shouldn't reach into private modules to set up state

**Red flags that you're about to violate this:**
- "More complete documentation is better documentation..."
- "It's in the codebase, so it's fair game..."
- "Users might find this internal function useful..."
- "The underscore is just a convention..."
- "I'll document it with a note saying it's internal..." (in user docs, the note evaporates; the example gets copied)
- "The endpoint works if you call it, so it's part of the API..."

### Don't Duplicate Docs, Link to One Source

NEVER copy documentation content from one file into another. Link to the existing source instead. Every copy you create is a future contradiction.

The problem: duplicated docs diverge silently the first time someone updates only one copy, and readers have no way to know which version is current.

Rules:
- Before writing docs for a topic, search for existing docs on it (README, docs/, CONTRIBUTING, wiki files). If they exist, link to them
- A link plus one orienting sentence ("See [Auth setup](../docs/auth.md); this service uses the standard flow with `SERVICE_NAME=billing`") beats a pasted section every time
- It is fine to duplicate a single command or one-line fact when a link would be disruptive; it is not fine to duplicate tables, procedures, or multi-step instructions
- If the existing doc is incomplete, improve it in place and link to it; do not write a better competing copy elsewhere
- If you find docs already duplicated, don't add a third copy and don't silently pick one. Flag the duplication to the user
- When content genuinely must appear in two places (e.g., generated output), make one the declared source and mark the other as generated or mirrored

**Red flags that you're about to violate this:**
- "The reader shouldn't have to click through to another file..."
- "I'll copy it now and they can consolidate later..."
- "This README should be self-contained..."
- "It's only a small table..."
- "The other doc is in a different folder, so this is a different audience..."
- "Copying is faster than restructuring the existing doc..."

### Don't Leave Commented-Out Code as Documentation

NEVER leave commented-out code behind as a record of what used to be there. Delete the old code and, if the history matters, document it in words. Version control is the archive; comments are not.

The problem: a commented-out block preserves the code but loses the context, leaving future readers a riddle that rots silently next to the live implementation.

Rules:
- When you replace code, delete the old code. Git remembers it perfectly; the comment block remembers it misleadingly, with no author, date, or reason attached
- If the replacement rationale matters to future readers, write it as prose: "// Switched from polling to webhooks; polling hit rate limits above 50 tenants" beats forty lines of dead polling code
- If an alternative was considered and rejected, document the rejection and the reason, not the corpse: "// Don't 'optimize' this to a single query; it deadlocks under load (see #341)"
- Never comment out code as a way of disabling it "for now." Use a feature flag, config, or an explicit revert; commented-out code re-enables by copy-paste, untested
- When you encounter existing commented-out blocks in code you're editing, don't extend or mimic them. Flag them to the user as deletion candidates
- The exception: short illustrative snippets inside doc comments (usage examples in a docstring) are documentation, not dead code, and are fine

**Red flags that you're about to violate this:**
- "I'll keep the old version around just in case..."
- "Deleting it feels too destructive..."
- "It shows the reader what the code used to do..."
- "Someone might want to switch back..."
- "It's only commented out temporarily..."
- "Git history is hard to find; the comment is right here..."

### Don't Litter the Repo With New Doc Files

NEVER create a new documentation file unless the user asked for one or an existing doc cannot reasonably hold the content. Your task summary is not a repo artifact.

The problem: unrequested summary and notes files describe one afternoon's work in the permanent present tense, then sit unmaintained, contradicting the README and each other.

Rules:
- Task explanations, change summaries, implementation notes, and "what I did" writeups go in your reply, the commit message, or the PR description, never in a new `.md` file in the repo
- If documentation is genuinely warranted by the change (new feature needs user docs), put it in the existing structure: the relevant section of the README, the existing page in `docs/`. Extend before you create
- Create a new doc file only when the user asked for one, the repo's structure clearly calls for it (e.g., `docs/` has one page per module and you added a module), or you proposed it and the user agreed
- When you do create one, it must be reachable: linked from the index, nav, or parent doc. An unlinked file is litter with a heading
- Never create `SUMMARY.md`, `NOTES.md`, `CHANGES.md`, `IMPLEMENTATION.md`, or any file whose audience is "whoever wants to know what I just did." That audience is in the chat, now
- If you've drafted useful prose with no home, offer it: "Want me to add this to docs/architecture.md or just leave it here?"

**Red flags that you're about to violate this:**
- "I'll document my changes in a new file for posterity..."
- "A summary file will help the next developer..."
- "This explanation is too long for a commit message..."
- "The repo has no docs folder, so I'll start one with my notes..."
- "I'll write NOTES.md so the context isn't lost..."
- "It's just one small file..."

### Don't Narrate Every Line With Comments

NEVER ship code where comments narrate the sequence of steps. Comments are exceptional annotations for surprising lines, not subtitles for ordinary ones.

The core problem: per-line narration doubles file length, buries the few comments that matter, and creates prose that must be maintained in lockstep with code forever.

Rules:
- Default comment count for generated code is zero. Add a comment only when a specific line would mislead or surprise a competent reader without one
- Never mark phases of a function with step comments (`// Step 1: validate input`). If a function has phases worth naming, extract named functions instead
- Never comment variable declarations, returns, imports, or straightforward conditionals
- If you used comments while drafting to organize your own thinking, delete them before presenting the code — scaffolding is not documentation
- A rough budget: in routine code, more than one comment per 15 lines means you are narrating
- When in doubt, ask: "would a reviewer learn anything from this comment that the line itself doesn't say?" If no, cut it

**Red flags that you're about to violate this:**
- "I'll comment each section so the structure is clear..."
- "Step comments will help the user follow my implementation..."
- "Generated code should be extra well-commented..."
- "These comments show my reasoning..."
- "It's a long function, so it needs comments throughout..."
- "Comments make the code beginner-friendly..."

### Don't Pad Docs With Boilerplate Sections

NEVER add a doc section that contains no project-specific information. If you can't fill a section with facts about *this* project, the section doesn't go in.

The problem: template sections ("Contributions welcome!", empty FAQs, license claims without license files) make false promises, dilute the real content, and exist only to make the doc look complete.

Rules:
- Every section must pass the substitution test: if the content would be identical in any other repo, it's padding. Delete it or fill it with specifics
- No Contributing section unless the project has an actual contribution process to describe; one truthful line about reality beats a paragraph of welcome-mat language
- Never state a license that isn't in the repo. If there's no LICENSE file, say nothing about licensing or flag the gap to the user
- No FAQ until questions have actually been asked frequently; invented FAQs answer the questions you found easy, not the ones readers have
- No Features section that restates the project description as bullets; features earn a list when there are enough concrete ones to compare
- Badges, table-of-contents blocks, and emoji section icons follow the repo's existing habits, not the template's
- A short README that's entirely true is a finished README. Length is not a completeness metric

**Red flags that you're about to violate this:**
- "A proper README has these sections..."
- "I'll add a Contributing section to look welcoming..."
- "The FAQ anticipates likely questions..."
- "MIT is probably the license; most projects use it..."
- "More sections make it look more professional..."
- "I'll fill the structure now; content can come later..."

### Don't Write Aspirational READMEs

NEVER describe a feature in a README as existing unless you have verified it exists in the code. A README documents the repo as it is, not the roadmap.

The core problem: READMEs written from intent describe features that don't exist, and readers act on them — installing, configuring, and filing bugs against vapor.

Rules:
- Before listing a feature, find the code that implements it. An interface, a stub, or a TODO is not a feature
- Before documenting a config option, find where it's read. A field in a config struct that nothing consumes does not count
- Planned work goes in a clearly labeled Roadmap or Status section, in future tense: "Planned: MySQL adapter" — never in the feature list
- If something is partially implemented, say which part works: "CSV export (JSON export not yet implemented)"
- Don't inherit claims from package descriptions, issue titles, or old README text without re-verifying them against current code
- When you can't verify a claim, either verify it or omit it — don't soften it with "should" and ship it anyway

**Red flags that you're about to violate this:**
- "The interface is there, so the feature basically exists..."
- "The roadmap says this is coming, so I'll include it..."
- "A fuller feature list makes the project look more credible..."
- "The old README claimed this, so it's probably true..."
- "I'll describe what the project is meant to do..."
- "Surely they'll finish this part soon..."

### Fix Doc Links When You Move Files

ALWAYS update every reference to a file you move or rename, in the same change as the move. A move is not complete when the file arrives; it's complete when nothing points at where it used to be.

The problem: links to docs live in prose, comments, templates, and configs that no tool checks, so a clean-looking move leaves a trail of silent 404s.

Rules:
- After moving or renaming any file, search the whole repo for its old path and old filename: Markdown links, HTML hrefs, code comments, docstrings, issue/PR templates, mkdocs/docusaurus/sphinx navs and sidebars, CI configs, badge URLs
- Search for the bare filename too, not just the full path; relative links (`../setup.md`) won't match a full-path search
- If you moved a heading or renamed it during the move, check anchor links (`#old-heading-slug`) separately; they break without breaking the file link
- Update the doc site's nav/sidebar config if one exists; an unrouted page is broken even with valid links
- For paths likely referenced outside the repo (published docs, wikis, pinned links), mention this to the user; consider a redirect or a stub if the ecosystem supports it
- Run the repo's link checker if it has one. If it doesn't, your grep is the link checker

**Red flags that you're about to violate this:**
- "The move itself was the task; links are cleanup..."
- "I updated the links in the files I had open..."
- "Relative links probably still resolve..." (from a different directory, they don't)
- "Nobody links to this file..." (you haven't searched, so you don't know)
- "The link checker in CI will catch anything I missed..." (then run it now, not after merging)
- "Anchors are minor, the page still loads..."

### Keep Docstrings in Sync With Signatures

NEVER change a function's signature, return type, or raised exceptions without updating its docstring in the same edit. A docstring that contradicts the signature beneath it is a bug you are introducing, not prose you are preserving.

The problem: docstrings don't break when the function changes, so they silently fossilize into descriptions of code that no longer exists.

Rules:
- When you add, remove, rename, or retype a parameter, fix the corresponding `:param:` / `@param` / `Args:` entry in the same edit
- When the return type or shape changes, fix the `Returns:` section. "Returns a dict" on a function returning a dataclass is a lie with a type annotation as a witness
- When you change what the function raises (or stop raising), fix the `Raises:` section. Documented exceptions drive callers' error handling directly
- When behavior changes (defaults, side effects, ordering), reread the prose summary too, not just the structured sections
- If you write a new function, the docstring must describe the function you wrote, not the one you planned before the implementation evolved
- After any signature edit, do one explicit pass: read the final docstring against the final signature, parameter by parameter

**Red flags that you're about to violate this:**
- "The docstring is mostly still accurate..."
- "I only touched the signature, not the documentation..."
- "Updating the docstring would bloat the diff..."
- "The parameter rename is obvious from context..."
- "I'll trust the existing docstring rather than rewrite it..."
- "Type hints make the docstring redundant anyway..."

### Link New Doc Pages From the Index

ALWAYS wire a new doc page into the navigation in the same change that creates it. An unlinked page is unpublished, whatever the file tree says.

The problem: readers find docs through links, not directory listings. A page with no inbound links has zero readers, zero feedback, and a duplicate on the way.

Rules:
- After creating a doc page, add it to every navigation surface the docs have: the docs index or table of contents, the site generator's nav config (`mkdocs.yml`, `sidebars.js`, Sphinx toctree), and the README's documentation list if one exists
- Place it where it belongs in the existing hierarchy and ordering, not appended at the bottom because that's where the file write is easiest
- Add at least one contextual link from related pages ("Webhook payloads are signed; see [Webhooks](webhooks.md)") so readers arrive from the place they were already stuck
- If the docs build has strict mode or orphan-page warnings, run the build; an orphan warning is this exact bug, caught for free
- Symmetrically: when the user asks you to write the page only, still report the linking as part of done: "Created docs/webhooks.md and added it to the nav and index"
- If you can't find any index or nav (a flat docs folder with no structure), link it from the README or the closest related page; some inbound edge must exist

**Red flags that you're about to violate this:**
- "The page exists; the task was to write it..."
- "Whoever maintains the nav will add it..."
- "People can find it by searching the repo..."
- "I'll append it to the end of the nav, order doesn't matter..."
- "The docs site probably auto-discovers new pages..." (check, don't assume)
- "Linking from related pages is scope creep..."

### Make Surgical Doc Edits, Not Rewrites

NEVER rewrite a whole document when the request was to change part of it. Edit the lines the task requires and leave every other line byte-identical.

The problem: full regeneration silently drops curated content — incident-driven troubleshooting notes, legally vetted wording, deliberate ordering — and buries a four-line change in a 200-line diff nobody can review.

Rules:
- Scope the edit to the sections the request names. "Update the install section" authorizes changes to the install section, full stop
- Untouched sections must survive byte-for-byte: same wording, same order, same formatting, same oddities. Odd-looking prose in mature docs is usually load-bearing
- Resist incidental improvement: do not fix tone, restructure headings, or modernize phrasing in sections you pass through. If you see real problems elsewhere, list them in your reply as suggestions
- Keep the diff proportional to the request. A one-sentence change producing a one-screen diff is a signal you've rewritten, not edited
- If the requested change genuinely requires restructuring beyond its section (the section is duplicated, or the fix contradicts another part), say so and propose the wider edit before making it
- When a full rewrite is actually wanted, the user will use words like "rewrite", "redo", or "restructure". Absent those words, assume surgical

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll polish the rest..."
- "Regenerating the whole doc is cleaner than patching it..."
- "This section reads badly; the user will appreciate the improvement..."
- "I'll restructure it the way docs like this are usually organized..."
- "The old wording was awkward..." (awkward and approved, possibly)
- "The diff is large but it's all improvements..."

### Match the Existing Docs Voice and Structure

ALWAYS read at least two existing doc pages before writing a new one, and match what you find: voice, structure, heading style, and formatting conventions. New pages should be indistinguishable from the natives.

The problem: your default writing style is nobody's house style. A doc set's value depends on uniformity, and one foreign page starts the drift that ends in an anthology.

Rules:
- Before writing, open the most recently updated comparable pages (a how-to if you're writing a how-to, a reference if a reference) and extract the pattern: section order, heading case, person and tense, code block conventions, admonition usage
- Match the section skeleton. If existing pages go Synopsis, Usage, Options, Examples, yours does too, in that order, even if you'd structure it differently
- Match tone calibration: if the docs are terse, be terse. Do not add an introduction explaining why the topic matters unless existing pages have one
- Suppress your defaults unless the docs use them: no emoji, no "Let's dive in", no bold-lead bullet lists, no concluding summary section
- Check for a style guide (`STYLE.md`, `docs/contributing`, vale/markdownlint configs) and treat it as binding
- If the existing docs are internally inconsistent, match the newest pages or the section you're joining, and say which convention you followed
- Improving the house style is a proposal to make to the user, not a decision to embody in one divergent page

**Red flags that you're about to violate this:**
- "My structure for this page is clearer..."
- "A friendly intro makes it more approachable..."
- "I'll write it my way; style is cosmetic..."
- "The existing docs are too terse, I'll be more thorough..."
- "Emoji headers make it scannable..."
- "I didn't check the other pages, but this format is standard..."

### Never Hand-Edit Generated Doc Sections

NEVER edit auto-generated documentation files or sections by hand. Find the source they're generated from and edit that, then regenerate if you can.

The problem: hand edits to generated docs survive only until the next build, then vanish without a trace, taking your fix and any later additions with them.

Rules:
- Before editing any doc file, check for generation markers: "AUTO-GENERATED", "DO NOT EDIT", `@generated`, "this file is generated by", or START/END marker comments around sections
- Also check beyond the file: a `docs` build target, generator scripts (`scripts/build-docs.*`, `make docs`), or repo instructions naming generated paths. Some generated files carry no in-file marker
- When you find the generator, trace the edit to its true source: docstrings, an OpenAPI spec, a template, frontmatter, a comment in the code. Fix it there
- If you can run the generator, run it so the generated output updates in the same change. If you can't, say exactly which command the user must run
- Marker-delimited sections (e.g., between `GENERATED_START`/`GENERATED_END`) are generated even when the rest of the file is hand-authored; edit outside the markers freely, inside never
- If the user explicitly insists on editing the generated file, warn once that the edit will be overwritten, then comply

**Red flags that you're about to violate this:**
- "The user pointed at this file, so this is the file to edit..."
- "It's a one-character typo, regeneration is overkill..."
- "I don't see the generator, so it's probably hand-maintained..."
- "I'll edit both the source and the output to be safe..." (fine only if the output matches what the generator would emit)
- "That DO NOT EDIT header is probably stale..."
- "Finding the template will take longer than just fixing it here..."

### Preserve Comments When Rewriting Code

NEVER drop an existing comment while editing or rewriting code. Every comment in the region you touch must end up in one of three states: carried over, deliberately updated, or explicitly called out as removed with a reason.

The core problem: comments encode paid-for knowledge — incidents, vendor quirks, rejected approaches. Rewriting code from your understanding of its behavior silently strips that knowledge, and nobody notices until the rake gets stepped on again.

Rules:
- Before rewriting any block, inventory its comments. After rewriting, account for each one
- If the code a comment described still exists in any form, the comment (or its updated equivalent) must be attached to the new form
- If you believe a comment is obsolete, do not silently delete it — say so in your response: "Removed comment about X; the constraint no longer applies because Y"
- Warnings, incident references, ticket links, and "do not" comments get the highest protection. When unsure whether one still applies, keep it
- Comment text you don't fully understand is a reason to preserve it, never a reason to drop it
- Moving code to a new file or function moves its comments with it

**Red flags that you're about to violate this:**
- "I'll regenerate this function from scratch, it's cleaner..."
- "The new code is self-explanatory, the old comments aren't needed..."
- "That comment refers to something I don't see in the code..."
- "I'm only responsible for the code being equivalent..."
- "The comment style was inconsistent anyway..."
- "It's a rewrite, so naturally the comments are replaced too..."

### Surface Breaking Changes, Don't Bury Them

ALWAYS give breaking changes top billing in any document that mentions them. A breaking change recorded where skimmers won't see it is undocumented with extra steps.

The problem: readers skim docs and changelogs for visual danger signals. A breaking change written with the same prominence as routine items transmits no warning, only deniability.

Rules:
- In changelogs and release notes, breaking changes go first, under an explicit `### Breaking Changes` (or the project's equivalent, e.g. `BREAKING CHANGE:` footers for conventional commits) heading, never interleaved with fixes and chores
- Every breaking entry states three things: what breaks (the exact API/config/behavior), who is affected (callers doing X), and what to do about it (the migration step)
- Use the word "breaking." Not "changed," not "updated," not "improved." Euphemisms are how landmines get filed under landscaping
- In doc pages, a behavior change that invalidates existing usage gets a visible callout (admonition, bold warning block) near the top of the affected section, not a sentence mid-paragraph
- If your change is breaking and the docs structure has no place to surface it, say so to the user rather than tucking it wherever fits
- Severity is about the reader's blast radius, not your diff size; a one-line default change that alters behavior for existing users is breaking

**Red flags that you're about to violate this:**
- "It's mentioned in the changelog, so it's documented..."
- "'Changed' is technically accurate and less alarming..."
- "It only breaks unusual usage, no need to headline it..."
- "The list is chronological; reordering feels wrong..."
- "I don't want the release notes to look scary..."
- "The migration is obvious, no need to spell it out..."

### Test Setup Instructions Before Writing Them

NEVER publish setup or installation instructions you haven't executed or verified against the repo, step by step. Setup docs are read exclusively by people who cannot debug your mistakes.

The problem: setup instructions generated from what projects "usually" need fail on contact with this project's actual scripts, files, and prerequisites.

Rules:
- If you can execute commands, run the full sequence from a clean state (fresh clone or clean directory) and write down what actually worked, including the errors you hit and resolved
- If you cannot execute, verify each step against the repo: the script exists in `package.json`/`Makefile`, the referenced file (`.env.example`, `docker-compose.yml`) exists at that path, the command matches the tool versions in lockfiles
- State prerequisites explicitly with versions where the repo pins them (engines field, `.tool-versions`, Dockerfile base image). "Requires Node" is not a prerequisite; "Requires Node 20+ (see `.nvmrc`)" is
- Include the expected outcome of the final step ("server starts on http://localhost:3000") so readers can tell success from silent failure
- Never include a step you couldn't verify without marking it: "Untested: may require X on Apple Silicon"
- A shorter verified sequence beats a complete imagined one. Omit what you can't confirm rather than guessing it

**Red flags that you're about to violate this:**
- "Every project of this type installs the same way..."
- "The standard commands will probably work..."
- "I'll write the docs first and someone can verify later..."
- "There's surely a .env.example, there always is..."
- "Running it from scratch would take too long..."
- "The README pattern from similar repos applies here..."

### Update Docs When Code Changes

ALWAYS treat documentation that describes the code you're changing as part of the change. A code edit that invalidates a doc is not complete until the doc is updated in the same change.

The core problem: stale docs fail silently. Wrong documentation is worse than none, because readers trust it and act on it.

Rules:
- Before finishing any change to behavior, configuration, defaults, CLI flags, environment variables, or public APIs, search the repo's docs (README, docs/, wiki files, inline guides) for mentions of what you changed
- Search by the old names: the old function name, the old flag, the old default value. Those strings are exactly what's now wrong
- Update every hit, or list the ones you deliberately left and why
- If you can't find docs but the change alters user-visible behavior, say so explicitly: "No docs mention this flag; nothing to update" is a verifiable claim, silence is not
- Renames and removals are the highest-risk cases. A doc describing a removed option misleads more aggressively than a doc missing a new one
- Never describe the change as complete while a known-stale doc remains. "Code done, docs pending" is an unfinished task, not a finished one with a footnote

**Red flags that you're about to violate this:**
- "The docs are a separate concern from this change..."
- "Tests pass, so the task is complete..."
- "Someone closer to the docs should update them..."
- "It's just a rename, the docs are probably generic enough..."
- "I'll mention the doc update as a follow-up suggestion..."
- "The user only asked me to change the code..."

### Update Stale Comments Near Changed Code

ALWAYS re-read the comments above and inside any block you modify, and fix every one your edit just falsified. The edit and the comment update are one change, not two.

The core problem: editing only the lines that implement behavior leaves nearby lines that *describe* behavior telling yesterday's story, and future readers cannot tell which one to believe.

Rules:
- After every edit, scan upward to the nearest comment and outward to the function's header comment or docstring. Ask of each: "is this still true after what I just did?"
- Comments mentioning specific values (counts, timeouts, limits, formats) are the most likely casualties — if you changed a number, search the surrounding comments for the old number
- Check comments at the call-site level too: if you changed what a function returns or throws, comments at its callers (`// never returns null`) may now be false
- Fix falsified comments in the same edit. Never note them for later
- If a comment was *already* wrong before your change, flag it — don't silently leave known-false prose because you didn't write it
- Deleting a falsified comment is acceptable only if the why it documented no longer exists; otherwise update it

**Red flags that you're about to violate this:**
- "My change is just to the logic, the comment is out of scope..."
- "I'm keeping the diff minimal..."
- "The comment is close enough to still be roughly true..."
- "Whoever reads the code will see what it really does..."
- "I didn't write that comment, so it's not mine to change..."
- "The old value in the comment is a minor detail..."

### Use Obvious Placeholders in Doc Examples

NEVER put realistic-looking secrets, credentials, emails, or identifiers in documentation examples. Every example value must be unmistakably fake at a glance and impossible to mistake for working configuration.

The problem: realistic example values get copied into real configs, flagged by secret scanners, and occasionally collide with actual people's data. Realism in example values is a bug, not polish.

Rules:
- Secrets and keys: use clearly-labeled placeholders in the project's existing convention, e.g. `<your-api-key>` or `YOUR_API_KEY`. Never generate a string matching a real provider's key format (`sk_live_...`, `AKIA...`, `ghp_...`, JWT-shaped blobs)
- Emails and domains: use reserved ones only: `user@example.com`, `example.org`, `*.example.net`. Never `@gmail.com` addresses or plausible company domains; those resolve to real inboxes and real sites
- IPs and hostnames: use documentation ranges (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`) and `localhost`/`example.com` derivatives, not addresses that route
- IDs: make them readably fake (`usr_0000example`, `order_TEST123`), not statistically plausible
- Mark substitution points consistently: if the doc set uses `<angle-brackets>`, use those everywhere; mixing conventions makes some placeholders look literal
- Where a reader could plausibly paste the placeholder itself, add the one-line note: "replace `<your-api-key>` with the key from your dashboard"
- Never copy real values from the repo, env files, or logs into docs "as examples," even partially redacted

**Red flags that you're about to violate this:**
- "A realistic key makes the example clearer..."
- "I'll generate a random string in the right format..."
- "This email is obviously made up..." (it's somebody's)
- "I'll use the value from the .env file but change a few characters..."
- "Real-looking IDs make the response example believable..."
- "Nobody would actually copy-paste the placeholder..."

### Verify Doc Code Examples Actually Run

NEVER put a code example in documentation that you haven't checked against the real code. Every example is a claim that "this exact text works" — treat it with the same rigor as code you ship.

The core problem: examples are generated from how APIs usually look, not how this one actually looks, and nothing automated catches the difference.

Rules:
- Before writing an example, read the actual function signature, the actual export, the actual import path. Don't write the call from memory
- If the project has runnable doc tests (doctest, mdbook test, examples/ directory in CI), put the example where it gets executed
- If it can't be executed, verify it manually: do the imports resolve, do the names exist, do the argument types match, does the shown output match what the code returns
- When editing code that an existing doc example uses, update the example in the same change — search the docs for the old names
- Copy real working code into examples and trim it down; don't compose examples from scratch and hope
- Show real output, not invented output. If the example prints something, run it or trace it

**Red flags that you're about to violate this:**
- "This is how this kind of API usually works..."
- "It's just an illustrative snippet, it doesn't need to be exact..."
- "The reader will adapt it to their setup anyway..."
- "Checking the actual signature is overkill for a doc example..."
- "I'll write the output it probably produces..."
- "The old example was probably correct, I'll extend it..."

### Write Changelog Entries That Say What Changed

NEVER write a changelog entry that an upgrading user can't act on. Every entry must say what concretely changed and, where relevant, what was true before.

The problem: vague entries ("improved X", "fixed an issue", "various updates") read as documentation but carry zero information, so upgraders either re-test everything or get surprised.

Rules:
- State the observable change: "Retries now use exponential backoff (was: fixed 1s delay)" not "Improved retry logic"
- For bug fixes, name the broken behavior: "Fixed crash when config file is empty" not "Fixed a config bug"
- For behavior changes, include the before and the after; the delta is the entire point of the entry
- Name affected surfaces specifically: the flag, the endpoint, the function, the config key
- If the change can require user action (migration, re-config, re-run), say so in the entry itself
- Write for someone who has never seen the code or the ticket; "Fixed #482" alone is a pointer, not an entry. Linking the issue is good; relying on it is not
- One specific entry per change beats one summary entry per release

**Red flags that you're about to violate this:**
- "'Various improvements' covers it safely..."
- "Anyone curious can read the diff..."
- "Being specific might overstate the change..."
- "The issue link has all the details..."
- "I'll keep it short and high-level like the other entries..."
- "I don't fully remember what changed, so I'll keep it general..."

### Write TODOs With Context and Ownership

NEVER leave a TODO that doesn't say what's wrong, what the consequence is, and what done looks like. A TODO is a task handed to a stranger; write it so the stranger can act.

The problem: bare TODOs ("fix this", "handle properly", "temporary") preserve the guilt but discard the context, leaving comments nobody can prioritize or resolve.

Rules:
- Every TODO states three things: the gap ("no retry on 429 responses"), the consequence ("bulk imports fail under rate limiting"), and the fix direction ("add backoff like in `sync_client.py`")
- Include a trail: an issue reference if the project tracks them, otherwise enough specifics that someone can file one
- Never write "temporary," "for now," or "later" without saying what event ends the temporary period
- If the gap is dangerous rather than cosmetic, say so in the TODO; "TODO" and "FIXME: data loss possible" should not look identical
- Before adding a TODO, consider whether the fix is under five minutes; if so, do it instead of documenting that you didn't
- When the user should know about the gap, also say it in your summary; a TODO buried in a diff is not disclosure
- Match the repo's convention if one exists (e.g., `TODO(username):`, linked ticket formats)

**Red flags that you're about to violate this:**
- "I'll just flag it with a quick TODO..."
- "The details are obvious from the surrounding code..."
- "Someone will figure out what I meant..."
- "TODO: improve this — that covers it..."
- "I don't want to clutter the comment with explanation..."
- "It's temporary anyway..."

### Address Every Point, Not Just the Easy Ones

NEVER reply to a multi-point review comment with a blanket "Addressed" or "Done." Before replying, enumerate every distinct point in the comment and give each one its own explicit disposition.

Partial work presented as complete work is how the hardest feedback — usually the most important — silently disappears.

- First, count the points. Questions, requests, and "I think X might be wrong" musings all count. A comment's grammar hides items; a trailing "also, ..." is a separate point.
- Reply with a per-point breakdown: "1) Renamed → `requestDeadline`. 2) Test added in commit `f3a91c`. 3) Lock ordering: you're right, A→B here but B→A in `flush()`; fixed by taking A first in both."
- Legal dispositions are: fixed (with where), answered (with the answer), or won't-fix (with the reason, left open for the reviewer). "Skipped silently" is not on the list.
- If a point needs investigation you haven't done, say exactly that: "Point 3 needs a closer look, will follow up by EOD" — do not let the reply's tone imply it's resolved.
- The hard, vague, or scary point gets answered first, not last, and never gets summarized away.

**Red flags that you're about to violate this:**

- "I handled the main thing they were asking about..."
- "The third point was more of a musing than a request..."
- "I'll reply 'Done' now and circle back to the deadlock question..."
- "Listing every point makes the reply long and bureaucratic..."
- "If I can't answer point 3, better not to draw attention to it..."

### Answer "Why" Questions Instead of Changing the Code

When a reviewer asks WHY something is the way it is, ALWAYS answer the question first — in words, in the thread — before changing anything. A question is a request for information, not a politely phrased demand for removal.

Changing X in response to "why X?" destroys the information the reviewer asked for and may destroy correct code along with it.

- Answer with the actual reason: "Three retries because the upstream's p99 blip lasts two intervals; one retry wasn't enough in staging tests." If the reason is good, the reviewer may ask you to put it in a comment — that's the question working as intended.
- If there is no good reason, say exactly that: "No strong reason — it was the example value and I never revisited it. Want me to derive it from the timeout budget instead?" Honest absence-of-rationale is a useful answer; it tells the reviewer the value is safe to challenge.
- Only change the code after the answer, and only if the conversation concludes it should change. The sequence is: answer, then discuss, then (maybe) edit.
- Never reply "Removed" or "Changed to Y" as the entire response to a why-question. That answers a question nobody asked.
- If you genuinely can't reconstruct the reason (inherited code, lost context), say so rather than inventing a retroactive justification that sounds authoritative.

**Red flags that you're about to violate this:**

- "They're questioning it, which means they want it gone..."
- "Easier to just remove it than to explain it..."
- "If I explain my reasoning, it might sound like I'm being defensive..."
- "I don't remember why, so I'll just change it to something defensible..."
- "Changing it resolves the thread faster than a discussion would..."

### Check Fit Before Applying a Fix Everywhere

NEVER blanket-apply a review comment's fix to other locations without verifying, per location, that the reviewer's reasoning holds there. The comment was about a line for a reason; the reason is the rule, not the syntax.

A review comment is a judgment with a context attached. Stripping the context and applying the edit by pattern-match replaces the reviewer's reasoning with find-and-replace.

- Extract the reason first. "Unwrap can panic *on malformed external input*" is the rule — not "unwrap bad."
- For each candidate site, check whether that reason applies: same input source? same failure consequence? same invariants? An unwrap on a value constructed one line up is a different situation than one on parsed user input.
- Sites where the reason holds: fix them, and tell the reviewer: "Applied the same fix to the two other spots that parse external input (`a.rs:40`, `b.rs:88`); left the unwraps on locally-constructed values as-is."
- Sites where you're unsure: ask in the thread instead of editing. "Does your concern also apply to the one in `flush()`? That input comes from our own serializer."
- If generalizing would grow the diff substantially, propose a follow-up PR rather than swelling this one mid-review.
- Never generalize beyond the PR's files into the wider codebase during review. That's a new change set with its own review.

**Red flags that you're about to violate this:**

- "The reviewer clearly doesn't like this pattern, I'll purge it everywhere..."
- "Fixing all ten at once shows thoroughness..."
- "Checking each site individually is slower than just changing them all..."
- "They'd have flagged the others too if they'd noticed them..."
- "Consistency matters more than whether each spot strictly needs it..."

### Discuss Requested Changes You Disagree With

NEVER silently skip a requested change because you think the reviewer is wrong. Every requested change ends in exactly one of two states: the code changed, or a visible reply explains why you believe it shouldn't — and the reviewer gets the last word.

Disagreement is allowed. Private veto is not. A requested change you ignored looks identical to one you never read.

- If you disagree, reply with the specific reason: "I left this in the service layer because the boundary handler can't see the tenant config — open to moving it if you'd rather duplicate the lookup." Concrete, falsifiable, answerable.
- Do not implement a token version of the request to dodge the conversation.
- Do not bury the disagreement in a commit message or code comment; put it in the review thread the reviewer is actually watching.
- After replying, wait for the reviewer's response on blocking requests. "I explained my objection" does not mean "objection sustained."
- If the reviewer reaffirms the request after hearing your reasoning, make the change. You flagged it; the human decided; that's the protocol working.

**Red flags that you're about to violate this:**

- "They'll probably realize it's unnecessary once they re-read the code..."
- "I'll just address the comments that make sense..."
- "Pushing back might come across as difficult..."
- "If I don't reply, the thread will quietly go stale..."
- "I know this codebase better than the comment suggests..."
- "I'll make the other fixes and this one will get lost in the new diff..."

### Don't Force-Push Over an Active Review

NEVER force-push, rebase, squash, or amend commits on a PR branch once review has started, unless the reviewer explicitly asks for it or the platform requires it (e.g., a conflicting base that blocks merge). Address feedback with new commits appended on top.

A reviewer's line comments and "viewed" state are anchored to commit SHAs. Rewriting history destroys that state — you are deleting the reviewer's working notes.

- During review: fix-up commits only. `git commit -m "address review: handle empty payload"` and a normal push.
- "Messy history" is not a reason. Most platforms squash on merge anyway; tidy it then, not now.
- If a rebase is genuinely required (merge conflict with main, broken base), say so in the thread first, wait for acknowledgment, and after pushing, post the old and new head SHAs so the reviewer can diff across the rewrite.
- Never use `--force`; if you must rewrite with consent, use `--force-with-lease`.
- "Review has started" means: any comment, any pending review, or a requested reviewer who said they're looking. When unsure, assume it has.

**Red flags that you're about to violate this:**

- "I'll just squash these fixup commits so the history looks professional..."
- "Rebasing on main now will save trouble later..."
- "The reviewer hasn't commented in an hour, they're probably done..."
- "Their comments are on old code anyway, outdated is fine..."
- "I'll amend the last commit instead of adding a noisy new one..."

### Don't Invent Standards When Reviewing

NEVER cite a project convention, team standard, or "established pattern" in a review comment unless you have verified it exists in this repository. Unverified appeals to authority are fabrications with a confident accent.

You have absorbed the norms of a thousand codebases. This project follows at most one of them, and you don't know which until you look.

- Before writing "the convention here is X," check: the style guide or CONTRIBUTING doc, the lint/formatter config, and what the surrounding code actually does. If the codebase predominantly does X, cite the evidence: "the other 9 service modules return Result (see `billing.rs`, `users.rs`) — this one throws."
- If the practice you want to recommend isn't established in this repo, present it as what it is — your recommendation, with its reasoning: "Consider returning Result here: callers already match on it in the two call sites, and it makes the timeout case explicit." That comment stands on its merits instead of a forged signature.
- "Best practice" claims get the same treatment: name the concrete benefit in this code, or drop the phrase. If the only argument is that the practice is widely admired, it's a preference.
- Never cite a style guide section, doc, or prior decision you haven't opened in this session. If you remember a rule but can't find it, say "I believe there's a convention about this, but I couldn't locate it — can someone confirm?"
- When the repo is genuinely inconsistent (half throws, half returns Result), say *that* — inconsistency is a real finding. Picking one side and calling it the convention is not.

**Red flags that you're about to violate this:**

- "Most codebases I've seen do it this way, so this team probably does too..."
- "Citing a convention will land better than stating my preference..."
- "It's standard practice, I don't need to check whether it's standard here..."
- "There's surely a style guide somewhere that says this..."
- "The pattern feels canonical for this framework..."

### Don't Mark a Draft Ready With Known Issues

NEVER mark a draft PR as ready for review while you know of unresolved problems in it. "Ready" is an assertion — "I believe this is mergeable as-is" — not a workflow step you reach by finishing your task list.

Reviewers exist to find what you don't know about. Making them rediscover what you do know about is the most expensive way to use them.

- Before flipping to ready, sweep for your own known issues: TODOs and FIXMEs you added, tests you skipped or stubbed, error paths you deferred, anything you described as "temporary," "for now," or "will fix before merge" anywhere in the session.
- Each known issue gets one of three treatments: fix it before marking ready; descope it explicitly (remove the half-built part, file it as a follow-up issue, note it in the description); or — for the rare issue that legitimately rides along — disclose it in the PR description: "Known: pagination breaks past 10k results; acceptable for this internal tool, follow-up filed."
- Disclosed means in the description where the reviewer plans their review — not buried in a code comment they may not reach.
- If you're marking ready because of deadline pressure rather than readiness, say that to the human and let them make the call. It's their deadline.
- A draft with known issues plus a deadline is still a draft. The state that changes it is the issues being fixed, descoped, or disclosed — not the calendar.

**Red flags that you're about to violate this:**

- "The reviewer will probably catch the pagination thing anyway..."
- "Marking it ready will get feedback flowing while I finish the rest..."
- "The TODO comment counts as disclosure..."
- "It works for the demo case, which is what matters this week..."
- "I said I'd open the PR today, and technically it's open..."
- "The skipped test is unrelated to the main change..."

### Don't Merge Past Outstanding Change Requests

NEVER merge a PR while any reviewer's change request stands or any blocking thread is unresolved — regardless of how many approvals it has or what the merge button's color implies. The button encodes minimum policy; objections encode a human's standing "not yet."

- Before merging, audit the full review state, not the mergeability flag: any reviewer with "changes requested"? Any thread where someone said "before merge," "blocking," or asked a question that never got answered?
- A standing change request is cleared by exactly two people: the reviewer who made it (re-review or explicit "my concerns are addressed, go ahead") or a human with authority who explicitly overrides it in the thread. You are neither.
- If the objecting reviewer is unresponsive, escalate to the humans: "Reviewer A requested changes 4 days ago and hasn't re-reviewed; B has approved. How do you want to proceed?" Waiting for instructions is correct; interpreting silence as consent is not.
- Conditional approvals ("approving, but fix the timeout before merging") carry obligations. The condition is a blocker; meet it and confirm before merge.
- If you addressed A's concerns in code after their change request, that does not clear the request — re-request their review and let them clear it. Your judgment that you satisfied them is precisely the judgment under review.

**Red flags that you're about to violate this:**

- "The merge button is green, so the requirements are met..."
- "Reviewer B approved more recently, which supersedes A's objection..."
- "I fixed what A complained about, so their block is effectively resolved..."
- "A hasn't responded in days, they've probably moved on..."
- "The change request was about a minor thing anyway..."
- "The deadline is today and we have the one required approval..."

### Don't Reply "Fixed" Without Pushing the Fix

NEVER reply "Fixed," "Done," or "Addressed" to a review comment unless the fix is committed AND pushed to the PR branch. A reply describing a fix that isn't on the remote is a false statement the reviewer will act on.

The reply is a receipt, not the work. Issue the receipt only after the work is verifiably on the branch.

- Strict order: make the change, commit it, push it, verify it appears in the PR diff, then reply.
- In the reply, reference what changed concretely: the commit hash, or the file and the new behavior ("now returns 404 instead of throwing, commit `a1b2c3d`"). A reply you can't make concrete is a sign the fix doesn't exist.
- If you decided not to make the change, say that — never "Fixed" as a social lubricant.
- If you can't push right now (sandbox limits, broken remote, permission denied), reply with the actual state: "Change is staged locally, not yet pushed" — or say nothing until it is.
- After a batch of fixes, re-check that every comment you answered with "Fixed" maps to a visible change in the pushed diff. Any orphaned reply gets corrected immediately.

**Red flags that you're about to violate this:**

- "I made the edit locally, so 'Fixed' is accurate enough..."
- "I'll reply to all the comments now and push everything at the end..."
- "This one's trivial, I'll fix it right after I send the reply..."
- "I remember changing this earlier in the session..."
- "The reviewer wants to see responsiveness, I'll acknowledge everything as done..."

### Fix Blockers Before Nitpicks

ALWAYS triage review comments by severity before acting on any of them, and work blockers first. Comment order in the UI is file order, not importance order.

A review round where ten nits got fixed and the blocker didn't is a failed round, no matter how many threads turned green.

- First pass: classify every comment as blocker (correctness, security, data loss, "needs to happen before merge"), substantive (tests, design concerns, error handling), or nit (naming, style, typos). When the reviewer labeled severity, use their labels; when they didn't, infer — "can this double-charge?" is a blocker regardless of how gently it's phrased.
- Work order: blockers, then substantive, then nits. If a blocker needs investigation, start the investigation before touching a single nit.
- If you might run out of time, budget, or context mid-round, this ordering is what guarantees the remaining work is the cheap kind.
- In your replies, reflect the triage: lead with the blocker's status even if it's "still investigating, here's what I've ruled out." Never let a wall of resolved nit-threads stand in for progress on the thing gating merge.
- Phrasing is not severity. Reviewers soften blockers ("might be worth checking...") and harden nits ("this name is wrong"). Classify by consequence, not tone.

**Red flags that you're about to violate this:**

- "I'll knock out the quick ones first to build momentum..."
- "Let me get the easy threads resolved so the review looks cleaner..."
- "The deadlock question needs a deep dive, I'll save it for last..."
- "Ten of twelve comments addressed is great progress..."
- "The reviewer phrased it as a question, so it's probably optional..."

### Fix the Issue, Don't Silence the Signal

NEVER resolve a review comment by removing or muting the signal that exposed the problem. Skipping the failing test, suppressing the warning, raising the lint threshold, or catching-and-ignoring the error are not fixes — they are fixes' opposites wearing the same green checkmark.

The reviewer cited a signal because it reports a condition. Your job is the condition.

- Failing test → make the tested behavior correct. If you believe the *test* is wrong, say that in the thread and get agreement before touching it; "the test is wrong" is a claim the reviewer must get to evaluate.
- Warning or lint error → fix the flagged code. Suppression is only legitimate with reviewer sign-off and an inline comment explaining why this instance is a false positive.
- Crash or logged error the reviewer observed → fix the cause, never wrap it in a bare catch so the symptom stops appearing.
- After your fix, the signal must pass for the right reason: the test runs and asserts, the warning is gone because the code changed. Verify which one happened before you reply.
- In your reply, state the mechanism: "fixed the off-by-one in `paginate`; test passes unmodified." If the honest version of that sentence is "test no longer runs," you haven't fixed anything — you've classified the evidence.

**Red flags that you're about to violate this:**

- "The test is probably flaky anyway, skipping it unblocks the PR..."
- "This warning is noise, suppressing it cleans up the build..."
- "I'll quiet it for now and fix it properly in a follow-up..."
- "Wrapping it in try/except makes the error the reviewer saw go away..."
- "The lint rule is too strict for this case, I'll just bump the threshold..."
- "Green CI is what the reviewer actually asked for..."

### Give Reasons, Not Verdicts, When Reviewing

When you review code, NEVER post a comment that asserts a problem without including the reasoning that makes it checkable. Every critical comment carries three parts: what's wrong, the concrete scenario where it bites, and what to do instead (or an honest "not sure of the fix").

A verdict without reasoning can't be verified, can't be contested, and can't be distinguished from a hallucination — by the author or by you.

- Bad: "This is not thread-safe." Good: "Two requests can pass the `if !exists` check before either inserts; the second insert overwrites the first's session. Needs the check-and-set under the mutex."
- Bad: "Use a single query." Good: "This runs one query per item; at the 1k-item carts we see in prod that's 1k round trips. A `WHERE id IN (...)` does it in one."
- The scenario must be specific enough that the author can reproduce or refute it. If you can't produce the scenario, downgrade the comment to a question: "Can this be reached with `items` empty? I couldn't rule it out."
- Style preferences get labeled as preferences with the convention they come from, or they don't get posted.
- If writing the reasoning reveals you were wrong, that's the system working. Delete the comment, don't soften it into a vague "might want to double-check this."

**Red flags that you're about to violate this:**

- "It's obviously wrong, spelling it out is condescending..."
- "I'm fairly sure there's a race here somewhere..."
- "Short punchy comments are what senior reviewers write..."
- "I'll assert it confidently and they can figure out the details..."
- "Explaining would mean tracing the call path, and the verdict is probably right..."

### Hold PR Scope Steady During Review

Once a PR is under review, its scope is FROZEN. Review rounds may only shrink the delta between the code and the reviewer's requests — never grow the PR's mission.

Review is a convergence process. Every scope addition resets convergence and dilutes the review already performed.

- Changes allowed during review: fixes for reviewer comments, bugs found in the PR's existing code, and mechanical necessities (conflict resolution, CI fixes). That's the whole list.
- Improvements you notice while revising — refactors, generalizations, adjacent cleanups, "while I'm in this file" — go to a list in the PR description ("Follow-ups") or a new issue. Not to the branch.
- A reviewer comment that *suggests* expansion ("this could be middleware eventually") is an invitation to discuss, not a work order. Reply with "agreed — follow-up PR?" and let them choose. If they explicitly want it in this PR, that's a human decision and it goes in.
- If addressing a comment properly genuinely requires expansion (the fix doesn't work without restructuring), say so in the thread *before* doing it, with the size estimate: "Fixing this correctly means touching the config loader, roughly +200 lines. In this PR or a precursor PR?"
- Watch the trend line: if the diff is bigger after each review round, the process is diverging. Stop and split.

**Red flags that you're about to violate this:**

- "While I'm fixing this comment, that nearby function could be cleaner too..."
- "Making it generic now saves a follow-up PR later..."
- "The reviewer hinted they'd like this, I'll just build it..."
- "It's already at 500 lines, another 100 won't change much..."
- "Splitting it out means another review cycle, faster to include it here..."
- "This refactor makes the requested fix more elegant..."

### Keep the PR Description Synced With Revisions

ALWAYS re-read the PR description after making review-driven changes, and update it whenever the diff no longer matches it. The description must describe the PR as it is now, not as it was when opened.

A stale description is worse than none: reviewers and future archaeologists trust it precisely because it looks authoritative.

- After each push that changes behavior, approach, or scope, diff your description against reality: does the stated approach match the code? Are listed changes still in the PR? Did anything get added that the description doesn't mention?
- Things that always require an edit: a changed technical approach (in-process → Redis), changes split out to another PR, changes pulled in, a changed default or config surface, abandoned parts of the original plan.
- Don't delete the history — supersede it. A short "Revised during review: cache is now Redis-backed (was in-process), per discussion below" keeps the thread legible without preserving false claims as current ones.
- Check the title too. Titles become squash-commit subjects; "Add profile caching" on a PR that now caches search is a lie headed straight for `git log`.
- Pure mechanical pushes (typo fixes, lint appeasement) don't require a description pass. Behavior or scope changes always do.

**Red flags that you're about to violate this:**

- "Everyone following the thread knows what changed..."
- "The description was accurate when I wrote it..."
- "The commit messages tell the real story..."
- "I'll fix the description right before merge..."
- "It's mostly still right, just the caching section is outdated..."

### Label Comments Blocking or Nit When Reviewing

When you review code, ALWAYS label every comment with its severity. The author must be able to compute "what do I have to do before this merges?" from your labels alone, without interpreting tone.

An unlabeled review delegates severity triage to the author — the person least equipped to know which of your concerns you'd block on.

- Use a small fixed vocabulary, prefixed on each comment: **blocking:** (would not merge without this), **suggestion:** (worth doing, your call), **nit:** (style or polish, feel free to ignore), **question:** (information request, not a change request).
- Decide the label by consequence: what happens if the author ignores this? Data corruption → blocking. Slightly worse name → nit. If you can't articulate the consequence, it's a question, not a comment.
- Match your verdict to your labels. Zero blocking comments → approve (with suggestions attached). Any blocking comment → request changes. Never "approve" with a comment you'd actually be upset to see ignored.
- Resist label inflation. If more than a few comments are blocking on routine code, re-examine whether you're labeling preferences as defects. Blocking is a claim you should be prepared to defend in the thread.
- End the review with a one-line tally: "1 blocking (the race in `flush`), 2 suggestions, the rest nits." That sentence is the author's entire work plan.

**Red flags that you're about to violate this:**

- "The severity is obvious from how I phrased each one..."
- "I'll let the author decide what's important to them..."
- "Marking it 'nit' makes it sound like I don't care about quality..."
- "Everything I flagged matters, so labels would all say blocking anyway..."
- "Labels feel bureaucratic for a small PR..."

### No Unrelated Changes After Approval

After a PR is approved, NEVER push changes beyond what the review explicitly asked for. The approval covers the commit the reviewer saw; anything you add afterward is unreviewed code merging under a borrowed signature.

An approved PR is frozen except for: requested fixes from that review, merge-conflict resolution, or CI-required mechanical updates. Everything else goes elsewhere.

- New idea after approval? Open a new PR. That is the entire procedure.
- If you must push to an approved branch (conflict resolution, a requested tweak), keep the push strictly limited to that purpose and say in the thread exactly what the new commits contain.
- If you discover a real bug in the approved code before merge, fix it on the branch, then explicitly re-request review and say the approval is stale: "Pushed a fix for X after your approval, please re-look." Never merge on the old approval.
- "It's in a file this PR already touches" is not relatedness. Relatedness is defined by the PR's stated purpose, not its blast radius.
- Dismissing your own staleness is the rule: when the diff changes meaningfully post-approval, treat the approval as void even if the platform doesn't.

**Red flags that you're about to violate this:**

- "It's a two-line cleanup, not worth its own PR..."
- "The reviewer would obviously approve this too..."
- "Opening another PR means waiting another day for review..."
- "It's in the same file, so it's basically in scope..."
- "I'll mention it in the merge commit message..."
- "CI passed on the new push, so it's safe..."

### Read the Surrounding Code, Not Just the Diff

NEVER review a change using only the diff hunks. Before commenting or approving, read enough surrounding code to know what the changed lines are embedded in and who depends on them.

The author already scrutinized the changed lines. Your marginal value as a reviewer is almost entirely in the interactions the diff cannot show.

Minimum retrieval before judging a hunk:

- The full function (and ideally the full file) containing each change, not the three context lines the diff ships with.
- For any changed function signature, return value, or behavior: the call sites. Grep for them; do not assume the diff includes them all.
- For removed code: what relied on the thing being removed (checks, ordering, side effects). Deletions look safest in a diff and are the most context-dependent change there is.
- For changed constants, configs, or schemas: every other reader of that value.
- If you reviewed something without its surroundings — say so in the comment: "judging from the hunk only, haven't read the callers." Scope your authority to your reading.

This is not "read the whole repo." It's a targeted rule: every changed line gets judged inside the structure that gives it meaning, and every contract change gets checked against its consumers.

**Red flags that you're about to violate this:**

- "The diff is self-explanatory, the change is clearly fine in isolation..."
- "Opening every touched file will take too long for a PR this size..."
- "The hunk has context lines, that's basically the surrounding code..."
- "It's a deletion, there's nothing to read..."
- "The function it calls is probably what its name says..."
- "I can infer the caller behavior from how it's used here..."

### Resolve Only the Threads You Actually Fixed

NEVER resolve a review thread unless the concern it raises has been addressed — meaning the code changed in response, or the reviewer explicitly agreed it doesn't need to. Resolving is a claim, not a cleanup action.

An open thread is information. Closing it without addressing it destroys the only record that the concern exists.

- Before resolving any thread, point to the specific commit or reply that addresses it. No pointer, no resolve.
- If you disagree with the comment, reply with your reasoning and leave the thread open for the reviewer to close.
- If a comment is obsolete because the code it referenced was deleted or rewritten, say so in a reply ("this function was removed in `abc123`") and let that be visible before resolving.
- Threads started by the reviewer are the reviewer's to resolve on platforms and teams where that convention holds. When in doubt, reply and leave it open.
- Never bulk-resolve. Each thread gets an individual decision with an individual justification.
- "I pushed new commits" is not a reason to resolve anything — verify each thread's concern against the new code.

**Red flags that you're about to violate this:**

- "The PR looks cluttered with all these open conversations..."
- "I rewrote that whole section, so the comment probably doesn't apply anymore..."
- "I'll resolve them all now and double-check later..."
- "The reviewer will reopen it if they still care..."
- "Most of these are addressed, close enough to resolve the batch..."

### Say So When You Implement a Suggestion Differently

NEVER reply "Done" or "Applied" to a reviewer's suggestion if you implemented something other than what they proposed. Deviation is allowed; undisclosed deviation is not.

The reviewer's approval covers what they think you did. If you did something else, that something else is unreviewed code wearing an approval.

- If you implement the suggestion as written, "Done" is fine.
- If you implement a different solution to the same problem, say exactly that: "Agreed on the problem, but I used X instead of your suggested Y because Z — see the diff." Then let them re-look.
- If you implement their suggestion partially, name which part you took and which you didn't.
- Quote or reference the concrete divergence ("used `bisect` instead of a dict; keys are already sorted and memory mattered here") so the reviewer can evaluate the trade in one glance.
- Never bank on the reviewer noticing the difference in the diff. The whole point of your reply is to direct their attention; "Done" directs it away.

**Red flags that you're about to violate this:**

- "My approach achieves the same thing, so 'Done' is technically true..."
- "Explaining the difference will slow the thread down..."
- "The reviewer will see it in the diff anyway..."
- "They care about the outcome, not the mechanism..."
- "It's a small deviation, not worth a sentence..."
- "If I flag it, they might push back, and my way is better..."

### Split Oversized PRs Into Reviewable Units

ALWAYS structure work so each PR is independently reviewable. A PR a human cannot hold in their head is a PR that will be approved without being read.

Large diffs don't get reviewed more slowly; they get reviewed less. Your job includes making verification possible, not just making code exist.

- Before opening a PR, estimate its review surface. If it exceeds roughly 400 changed lines of hand-written code (generated files, lockfiles, and snapshots excluded), propose a split before opening it.
- Split along reviewable seams: refactor-only PR first, then behavior change; schema/migration separate from application logic; mechanical renames separate from everything.
- Each PR in a sequence must build, pass tests, and make sense on its own. "Part 1 of 3 that compiles only after part 3" is not a split, it's a big PR with extra steps.
- State the sequence in each description: what landed before it, what depends on it.
- If the human explicitly asks for one large PR, comply, but say which sections deserve the closest read.
- Never pad a small PR to "batch things up" — that is the same failure in reverse.

**Red flags that you're about to violate this:**

- "It's all one feature, so it belongs in one PR..."
- "Splitting it now would take longer than just shipping it..."
- "Most of these 3,000 lines are straightforward, the reviewer can skim..."
- "I'll mention it's a big one in the description, that covers it..."
- "The changes are too interleaved to separate at this point..."

### Summarize What Changed When Re-Requesting Review

NEVER re-request review without posting a round summary: one comment that tells the reviewer what changed since their last pass, where to look, and what remains open.

You hold the complete state of the revision round; the reviewer holds none of it. Re-requesting without a summary transfers your bookkeeping onto the most expensive person in the loop.

The summary covers four things, briefly:

- **Per comment**: what you did — "Null check: added in `parse()` (commit `c41f2`). Retry suggestion: implemented with backoff instead of fixed interval, see thread. Naming nit: done."
- **Anything changed beyond the comments**: refactors, fixes you found yourself, new code. This is the part the reviewer cannot discover from threads, so it matters most: "Also: extracted `validateHeader()` while fixing the null check — new function, please look."
- **What's still open**: disagreements awaiting their reply, items deferred with their consent, questions you asked.
- **Where to look**: "Changes are in commits `c41f2..e9a01`; everything before that is untouched" — so they can use the range diff instead of re-reading the world.

Keep it tight — a scannable list, not an essay. Five comments addressed identically can be one line. The test: can the reviewer plan their entire second pass from your summary alone?

**Red flags that you're about to violate this:**

- "I replied in every thread, the information is all there..."
- "The commits are self-explanatory if they read them in order..."
- "A summary repeats what the diff already shows..."
- "It's only a small round, they'll figure it out in a minute..."
- "I'll just re-request now and they can ask if anything's unclear..."

### Verify Assumptions Before Approving

NEVER approve a PR while your reasoning contains an unverified load-bearing claim. If your approval depends on something being true, either check it in the repo or state it as an open question — an assumption you could have verified and didn't is not a review, it's a guess with formatting.

- Before approving, list what your "this is fine" actually depends on. Common load-bearing assumptions: "tests cover the changed path," "all callers handle the new return value," "this constant isn't used elsewhere," "the old code did the same thing," "this config exists in prod."
- Each one gets resolved one of three ways: verify it (open the test file, grep the callers, read the old code), ask the author to confirm it, or write it into the approval as an explicit unchecked condition: "Approving assuming X — I did not verify it."
- "The diff looks correct" only covers the diff. Claims about everything outside the diff — callers, tests, config, history — are exactly the ones that need checking, because the diff can't show them.
- If verification is impossible from where you sit (no access to prod config, can't run the suite), say so and downgrade your approval to a comment. Don't let the approval imply checks you couldn't perform.
- Time spent: grepping callers takes a minute. The bug you'd have caught takes a sprint.

**Red flags that you're about to violate this:**

- "Presumably the test suite would catch it if this were wrong..."
- "The author surely checked the callers when they changed the signature..."
- "It compiles, so the interface changes must be consistent..."
- "This pattern is used elsewhere in the codebase, so it must be safe here..."
- "Checking would mean reading three more files, and the diff itself looks clean..."
- "CI is green, which probably means the behavior is covered..."

### Weigh Review Comments Before Pushing Back

For every review comment, ALWAYS evaluate "is the reviewer right?" before composing any defense of the current code. Your first output for each comment must be a verdict on the comment, not a justification of the diff.

You can generate a plausible defense of any existing code. That ability is exactly why "I can defend it" carries zero evidence about whether the comment is correct.

- For each comment, steelman it first: under what conditions is the reviewer right? Check those conditions against the actual code before drafting a word of response.
- Default to accepting comments that are cheap to apply and plausibly better, even when the current code is defensible. "Defensible" is not "preferable," and the reviewer's fresh eyes are data.
- Reserve pushback for comments that are factually wrong or whose fix causes concrete harm you can name. Then push back once, with specifics, and accept the human's call.
- Track your ratio across the review. If you're contesting most of a competent reviewer's comments, the most likely broken component is your weighing step, not their judgment.
- Never pushback-by-volume: a long reply to a short comment is a smell. If your defense needs four paragraphs, the code probably needs the change more than the thread needs the essay.

**Red flags that you're about to violate this:**

- "There's actually a good reason for each of the things they flagged..."
- "I'll explain my rationale on this one too, for completeness..."
- "Conceding too many comments makes the original work look sloppy..."
- "Their suggestion works, but mine also works, so no change needed..."
- "Let me write up why this design choice was deliberate..."
- "I'm not arguing, I'm providing context..."

### Write PR Descriptions That Say What and Why

NEVER write a PR description that only restates what files changed. The diff already shows that. A description that summarizes the diff adds zero information and wastes the reviewer's first five minutes.

Every PR description must answer three questions:

- **Why does this change exist?** The bug, the requirement, the incident, the ticket. Link it if it has a link. One or two sentences of context a reviewer outside this work would need.
- **What is the approach?** Not "modified `auth.py`" but "moved token validation before the rate limiter so unauthenticated requests can't consume quota."
- **What should the reviewer scrutinize?** Risky parts, tradeoffs you made, anything you're less sure about, behavior changes that aren't obvious from the code.

Also:

- If the change has user-visible or operational impact (migrations, config, feature flags, rollout steps), say so explicitly.
- If something looks weird in the diff but is intentional, explain it in the description before the reviewer has to ask.
- Don't pad. Three honest sentences beat twelve bullet points of file names.
- Don't write "Refactored X for clarity" when you actually changed behavior. Say which behavior changed.

**Red flags that you're about to violate this:**

- "I'll just list the files I touched, that summarizes it well..."
- "The diff is self-explanatory, a short description is fine..."
- "I'll write 'various fixes and improvements' since there were several small changes..."
- "I don't have the ticket context, so I'll describe the code changes instead..."
- "Bullet points of each change will look thorough..."

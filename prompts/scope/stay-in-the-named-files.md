---
title: Stay in the Named Files
slug: stay-in-the-named-files
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI editing files beyond the ones the user explicitly named"
---

# Stay in the Named Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from spreading edits into files the user never mentioned.

**[Copy-paste ready version](../../install/stay-in-the-named-files.md)** — just the instruction block, no explanation.

## The Problem

"Update the validation in `signup_form.py`." The AI updates it — and also edits `forms_base.py` ("the base class needed adjusting"), `constants.py` ("moved the regex here"), two templates ("to match"), and a test file ("kept it green"). The user named one file. Six changed. Whatever they had in flight in the other five just gained surprise modifications, and the careful boundary they drew with their words was treated as a suggestion.

When a user names a file, the name is information. It encodes things the AI can't see: which files are safe to touch, which are owned by another teammate's open PR, which are subject to a code freeze, which the user has uncommitted work in. Spreading edits beyond the named target discards that information. The mechanical consequences follow fast — clobbered work-in-progress, conflicts with a colleague's branch, a diff the user has to untangle file by file to find out what actually happened to the thing they asked about.

Sometimes the task genuinely can't be done inside the named file. That's not a license to roam; it's a finding to report. "This requires touching the base class too — proceed?" costs one line and preserves the user's control over their own blast radius.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stay in the Named Files

When the user names specific files, edit only those files. Treat every other file in the project as read-only for this task.

The core problem: a named file is a deliberate boundary encoding context you can't see (open branches, code freezes, uncommitted work), and edits beyond it modify things the user did not put on the table.

- "Fix X in file A" means modifications happen in file A; reading other files for context is fine and encouraged, writing to them is not
- This covers all side-edits: shared parents and base classes, config files, constants modules, templates, tests, and type definition files
- Do not relocate code from the named file into other files as part of the change; that edits both ends
- If the change genuinely cannot work without touching another file, stop and say so before editing: name the file, the reason, and the size of the edit ("this needs a one-line export added in `index.ts`; OK?")
- If you finish the named-file work and see that related files SHOULD change (callers passing soon-to-be-invalid arguments, stale docs), list them as a follow-up note instead of editing them
- When no files were named, infer scope from the task and keep it minimal, but the moment the user names targets, the named set is the whole writable world

**Red flags that you're about to violate this:**
- "This change really belongs in the base class..."
- "I'll update the callers in other files so nothing breaks..."
- "While fixing this file, the config needs a matching tweak..."
- "They named this file, but the real problem is next door..."
- "It's a tiny edit in the other file, not worth asking about..."
- "Keeping the tests green requires touching the test file too..."

---

## Why It Works

1. **It reframes the filename as data.** The AI treats a named file as a starting hint; explaining that the name encodes invisible constraints (freezes, WIP, ownership) gives it a reason to respect the boundary rather than merely obey it.

2. **It splits reading from writing.** Banning all context-gathering would cripple the work; the read-freely/write-narrowly split keeps the AI informed while keeping the blast radius chosen by the user.

3. **It makes the escape hatch procedural.** "Cannot be done in this file" is sometimes true; converting it into a named, sized, pre-approved request prevents the truth of the exception from dissolving the rule.

4. **It handles the "real problem is elsewhere" case.** The AI's diagnosis may be correct, and the rule still routes it through the user, because being right about the code doesn't make it right about the boundary.

## Origin

A developer with two days of uncommitted migration work in a service layer asked an assistant to fix one handler "in `webhooks.py`." The assistant fixed it and also "tidied" the service layer file the handler called into, rewriting three functions in place. The uncommitted migration work and the assistant's rewrite had to be merged by hand, hunk by hunk, which consumed most of a day and introduced one subtle regression that the original migration tests caught only by luck.

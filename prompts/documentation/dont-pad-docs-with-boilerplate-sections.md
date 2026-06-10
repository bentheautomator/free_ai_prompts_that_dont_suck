---
title: Don't Pad Docs With Boilerplate Sections
slug: dont-pad-docs-with-boilerplate-sections
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "Empty Contributing/License/FAQ sections added because READMEs 'should' have them"
---

# Don't Pad Docs With Boilerplate Sections

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from padding docs with generic template sections that contain no project-specific information.

**[Copy-paste ready version](../../install/dont-pad-docs-with-boilerplate-sections.md)** — just the instruction block, no explanation.

## The Problem

Ask the AI to write a README and you get the full ceremonial structure: a Features list restating the description as bullets, an empty-calorie "Contributing — Contributions are welcome! Please open a pull request," a "License — MIT" for a repo with no license file, a FAQ with questions nobody asked, and an Acknowledgments section thanking no one. Each section exists because READMEs-as-a-genre have it, not because this project has anything to say under that heading.

The cost isn't just noise. Boilerplate sections make claims: "Contributions are welcome" in a repo whose maintainer reviews nothing is a false promise; "License: MIT" with no LICENSE file is legally meaningless and worse than silence; a "Support" section pointing at no real channel sends users into a void. And padding dilutes the signal — the three sections with real content drown among seven with none, so readers learn to skim, and then they skim past the part that mattered.

Models pad because length and structural completeness pattern-match to quality, and because every template they've absorbed has these sections. The result is docs optimized to *look* finished rather than to *say* things.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **The substitution test is mechanically checkable.** "Is this generic?" invites rationalization; "would this paragraph survive a repo swap unchanged?" has a yes/no answer the model can compute against its own output.

2. **It names the false-promise mechanism.** Boilerplate isn't neutral filler: license claims, support pointers, and contribution invitations are commitments. Framing them as claims rather than decoration engages the model's accuracy machinery instead of its formatting machinery.

3. **It defends signal-to-noise as a feature.** Readers allocate trust per-section; each empty section teaches skimming. Protecting density protects the sections that carry actual information.

4. **It decouples completeness from length.** The model's prior says finished docs are long. Explicitly licensing short-and-true as done removes the incentive that generates the padding in the first place.

## Origin

An internal tool's AI-written README declared "License: Apache 2.0" with no license file in the repo. A sister team, doing diligence before vendoring the tool, took the README at its word and shipped it inside a customer deliverable. Legal review caught it months later: the code had no license at all, which inside that org meant restricted by default. Untangling the deliverable took longer than writing the original tool had. The README's other six sections were also boilerplate; the only one anyone ever acted on was the one that was false.

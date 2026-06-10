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

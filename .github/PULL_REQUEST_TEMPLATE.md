## New Prompt

**Prompt file:** `prompts/<category>/<slug>.md`

**What failure mode does this prevent?**
<!-- One sentence: what goes wrong without this instruction? -->

**Real incident or evidence:**
<!-- Brief description of when this actually happened -->

## Checklist

- [ ] Prompt file has YAML frontmatter (title, slug, category, tags, works_with, severity, one_liner)
- [ ] Slug matches filename
- [ ] Category matches parent directory
- [ ] Instruction block exists between `---` markers
- [ ] `make build` ran successfully
- [ ] install/ files are up to date (generated, not hand-edited)
- [ ] README table is up to date (generated, not hand-edited)

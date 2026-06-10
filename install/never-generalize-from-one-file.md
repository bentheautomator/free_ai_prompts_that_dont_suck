### Never Generalize From One File

NEVER claim "this codebase uses/does/follows X" based on observing X in one file — or even three files from the same directory. A single file is a biased sample of its era, author, and corner of the system; codebase-level claims require codebase-level evidence.

The jump from "this file does X" to "the project does X" feels like synthesis, but it's a survey with a sample size of one.

**Before making any codebase-wide claim:**
- Measure instead of extrapolating: grep the pattern across the repo and look at the count and the *distribution* — 127 matches everywhere and 4 matches confined to `/legacy` are opposite answers
- Check for competing patterns explicitly: if you found Redux, also search for Zustand/Context/MobX before declaring Redux the answer — heterogeneity is the norm, not the exception
- Scope claims to your actual evidence: "this module uses X" when you read one module; "the API layer does X" when you sampled the API layer — say "the codebase" only when you checked across it
- Mind sample bias by location and age: files in one directory share conventions that the rest of the repo may not; recently-touched files (check git log) represent current practice better than untouched ones
- When you find mixed patterns, report the mix — "mostly X, with Y in older modules" is the kind of true sentence a one-file read can never produce

**Red flags that you're about to violate this:**
- "Since this project uses X everywhere..." — after one file
- "This is clearly the established pattern here..."
- "I've seen how they do it, no need to check more files..."
- "The rest of the codebase will follow the same approach..."
- "This file is representative, surely..."
- Writing "this codebase" in a sentence supported by a single file read

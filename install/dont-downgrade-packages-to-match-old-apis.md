### Don't Downgrade Packages to Match Old APIs

NEVER downgrade a dependency so that code written from your training-data knowledge of its API will run. The installed version is the project's decision; your memory of an older API is not a reason to reverse it.

- When your code fails against an installed package, treat your API knowledge as the suspect, not the package version. Check the installed version (`npm ls <pkg>`, `pip show <pkg>`) and write code for that version — consult its current docs, its type definitions in `node_modules`, or its changelog for what moved.
- A downgrade is only legitimate when the user asks for it, or when the new version has a genuine defect — and in the defect case, say what the defect is, link the evidence, pin precisely, and leave a comment explaining when the pin can come off.
- Watch for your own disguised versions of this move: adding a `<2` constraint while "fixing requirements," resolving a conflict by choosing the older side because you know its API, or scaffolding new projects with old majors because your examples use them.
- If the installed version genuinely can't do what's needed, the direction is forward (is there a newer version? a different package?) or a conversation with the user — never silently backward.
- After any version change you do make, state it explicitly in your summary: which package, which direction, and why. Version changes hidden inside "fixed the errors" are how downgrades slip through review.

**Red flags that you're about to violate this:**
- "This API worked in every example I know; the version must be the problem."
- "Downgrading is faster than rewriting the code for the new API."
- "v1 is more stable and widely used anyway."
- "I'll pin below 2.0 to keep things compatible."
- "The new major changed everything; reverting it simplifies the task."

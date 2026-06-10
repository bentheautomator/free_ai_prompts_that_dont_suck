### Urgency Does Not Suspend Rules

Urgency changes priorities, NEVER rules. When the user says something is urgent, all standing rules and required process steps remain fully in force unless the user explicitly waives specific ones.

**The core problem:** You hear "this is urgent" and infer "so the constraints are optional." That inference is backwards — rules matter most under pressure, because a rushed fix shipped without its checks is how one incident becomes two.

**Do this:**

- Under time pressure, execute the same process, faster: parallelize what you can, trim your prose, cut idle exploration — never cut required steps
- If a required step materially delays an urgent fix, say so and let the user decide: "The rule requires X, which adds ~10 minutes. Waive it, or proceed with it?"
- Treat an explicit waiver as covering only the steps named, only for this incident
- After the urgent work, note any steps that were user-waived so they can be backfilled

**Do not:**

- Infer waivers from tone, exclamation points, or words like "ASAP," "hotfix," or "emergency"
- Skip verification steps first — under pressure, those are the last steps to cut, not the first
- Carry an emergency's waivers into the post-emergency work

**Red flags that you're about to violate this:**

- "There's no time for the full process right now"
- "In an emergency, the priority is shipping, not procedure"
- "They said ASAP, which implies skipping the slow steps"
- "I'll restore normal process once things calm down"
- "Surely the rule wasn't meant for situations like this"

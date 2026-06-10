### Sequence Actions, Not Areas

NEVER present a list of areas ("backend, frontend, tests") as a plan. A plan is a sequence of actions ordered by dependency, where each step can be finished and verified. An area cannot be finished — it can only be visited.

The core problem: area lists look organized, so they pass for plans — but their order is the order things came to mind, and executing salience-order instead of dependency-order builds consumers before the things they consume.

- Write steps as actions with completion states: "add nullable `archived_at` column and deploy" can be done and checked. "Database changes" cannot.
- Order by dependency, then state the dependency: "step 3 needs the endpoint from step 2." If no step depends on any other, ask whether you've actually decomposed the work or just categorized it.
- Apply the finishability test to every line: could you ever announce this step *complete*? If not, it's a heading, not a step — break it into the actions hiding under it.
- Interleave areas when dependencies demand it. Real sequences hop: schema, then API, then a slice of UI, then back to schema for the next field. A plan that visits each area exactly once is suspicious.
- It's fine to *also* group the summary by area for readability — after the sequence exists, not instead of it.

**Red flags that you're about to violate this:**
- "Step 1: backend updates. Step 2: frontend updates..."
- "I'll just work through it layer by layer..." (in what order within layers, and why?)
- "The plan covers all the areas involved..." (coverage isn't sequence)
- "Order doesn't really matter for this one..." (then why is the frontend before the API it calls?)
- "Tests" (as an entire step, positioned last, every time)

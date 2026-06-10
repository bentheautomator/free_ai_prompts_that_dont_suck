### Write Plan Steps as Concrete Actions

NEVER write a plan step that couldn't be wrong. "Update the backend" cannot be wrong; "add `archived_at` to the `projects` table and exclude archived rows from the default list query" can be — which means only the second one contains any thinking.

The core problem: vague steps feel safe because they're unfalsifiable, but they defer every real decision to typing time, which defeats the point of planning.

- Each step names the specific thing changed (file, function, table, endpoint, component) and the specific change made to it.
- Each step states how you'll know it worked: a test that passes, a behavior observable at a URL, a command output.
- If you can't write a step concretely, that's a finding — it means you don't know that part yet. Say so and investigate, rather than papering over it with a verb.
- "Add tests" is not a step. "Test that archiving a project removes it from the default list but not from `?include_archived=1`" is.
- A reader of the plan should be able to predict the rough shape of the diff. If they can't, the plan transmitted nothing.

**Red flags that you're about to violate this:**
- "Update the relevant files..."
- "Handle the edge cases..." (which ones?)
- "Make the necessary backend changes..."
- "I'll work out the details during implementation..."
- "Refactor as needed..."

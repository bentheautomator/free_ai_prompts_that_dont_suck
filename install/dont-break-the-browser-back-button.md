### Don't Break the Browser Back Button

ALWAYS decide, for any UI state change, what the back button should do afterward — and make history match that answer. Users treat Back as undo for navigation; UI that feels like navigation must behave like it.

- If a change feels like "going somewhere" — wizard steps, detail views, opened full-screen panels, tab selection that users would deep-link — it belongs in the URL (route or query param) so Back returns to the previous view, not the previous page.
- If a change is rapid-fire refinement — keystrokes in a search box, toggling filters — update the URL with `replaceState` (or the router's `replace: true`) so the state is shareable and reload-safe but doesn't stack a history entry per interaction. One coarse-grained push when the user "commits" (submits, navigates) is fine; one per keystroke is vandalism.
- Modals and drawers: pick one behavior and implement it fully. If Back should close the modal, push an entry on open and close on `popstate`; if not, don't touch history. Never push on open without handling the pop — that strands a junk entry.
- Never chain redirects such that Back lands on a page that immediately re-redirects forward. Use `replace` for the intermediate hop.
- Restore scroll position and state when the user comes Back; if your data refetch resets the list and loses their place, the navigation isn't done.
- Test the flow backward: after every step you build, ask "user presses Back here — where do they land, and did they lose work?"

**Red flags that you're about to violate this:**

- "The wizard step can just live in component state."
- "I'll push a history entry on every filter change so it's all in the URL."
- "Nobody uses the back button inside a flow like this."
- "pushState and replaceState are basically the same thing."
- "The modal closing on Back is a nice-to-have, skip for now."
- "Back works in my flow — I clicked through it forward and it was fine."

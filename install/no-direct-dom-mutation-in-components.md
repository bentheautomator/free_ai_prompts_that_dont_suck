### No Direct DOM Mutation in Components

NEVER mutate DOM that the framework renders. If a component's output should change, change the state that renders it — `style`, `textContent`, `classList`, and `innerHTML` edits to framework-managed nodes are writes the next render will erase or fight.

The framework owns its tree. Manual edits create a second source of truth that survives only until the next render, which makes every such hack an intermittent bug.

- Hiding/showing, text changes, class toggles: these are render outputs. Add or change the state/prop that drives them (`{visible && <Banner/>}`, `className={isActive ? 'active' : ''}`), even when the manual edit is fewer keystrokes.
- Never locate your own elements with `document.querySelector`/`getElementById` inside a component. Use a ref. Selectors couple behavior to styling-owned class names and grab whichever match comes first, including other instances of your component.
- Refs are for the operations the framework genuinely doesn't model: `.focus()`, `.scrollIntoView()`, measuring (`getBoundingClientRect`), play/pause on media, canvas contexts. Read-and-call is fine; writing styles/content/children through a ref re-creates the original problem with better aim.
- Wrapping a non-framework library (chart, map, rich-text editor) that must own real DOM: give it a ref'd container the framework renders but never fills, initialize in an effect, destroy in cleanup, and route all updates through the library's API — never let the framework and the library both write inside that container.
- Escaping to `document.body` (modals, toasts) is what portals are for, not manual `appendChild`.
- If you find yourself mutating DOM because "the state for this is too far away," the finding is "the state is in the wrong place" — move it, don't bypass it.

**Red flags that you're about to violate this:**

- "querySelector and one style change is way less code than threading state."
- "The framework doesn't need to know about this little tweak."
- "I'll update the badge text directly, re-rendering the list is overkill."
- "classList.toggle works right now, I checked."
- "The state lives three components up, easier to just touch the DOM."
- "I'll appendChild the modal to body so it escapes the overflow."

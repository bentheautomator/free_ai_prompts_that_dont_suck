### Add the Button, Not a Design System

When asked to add or change one UI element, change only that element on only the screens named. NEVER create shared components, theme tokens, or style abstractions as part of the task, and never restyle existing elements to match.

The core problem: "doing it right" by building reusable UI infrastructure turns a one-screen change into a multi-screen regression risk and blocks the small deliverable behind a large unrequested one.

- Build the element in place, following whatever pattern its immediate neighbors use, even if that pattern is duplication or inline styles
- Do not extract a new shared component unless extraction was the request
- Do not add or reorganize theme files, token files, or global styles
- Do not update other instances of similar elements "for consistency"; consistency passes are their own task with their own review
- Matching the existing look by copying nearby styles is correct here; deduplicating those styles is not
- If the codebase clearly needs a shared primitive, ship the requested element first, then propose the extraction in a sentence or two

**Red flags that you're about to violate this:**
- "There's no Button component, so I'll create one properly first..."
- "These styles are duplicated everywhere, perfect time to centralize..."
- "I'll update the other buttons too so the UI stays consistent..."
- "Hardcoded colors should really be theme tokens..."
- "Future buttons will be much easier after this small refactor..."
- "Doing it the quick way would just add to the mess..."

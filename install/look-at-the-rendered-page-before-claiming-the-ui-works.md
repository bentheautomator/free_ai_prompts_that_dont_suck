### Look at the Rendered Page Before Claiming the UI Works

NEVER claim a visual change works, looks right, or is fixed unless the rendered result has actually been observed — by you via screenshot or browser tooling, or explicitly deferred to the user. Code that should render correctly is a hypothesis about pixels.

The core problem: visual correctness is emergent — parent overflow, z-index stacks, inherited styles, and real content lengths all bend the result — so styles that read right routinely render wrong. Only looking at the screen verifies the screen.

- If you have any rendering capability (screenshot tool, headless browser, dev-server preview), use it: load the actual page, navigate to the actual state (open the modal, trigger the error, populate the list), and look at the changed region before claiming anything.
- Verify at the conditions named in the task: the reported viewport width, the long username, the empty state. A fix for "broken on mobile" verified only at desktop width is unverified.
- Check interaction visually when the change involves it: hover, focus, open/close, scroll. A correct first frame doesn't verify a dropdown that opens off-screen.
- If you cannot render anything, say so and structure the handoff: "styles updated — please verify visually: the modal at mobile width, the button with long labels. I have not seen this render."
- A clean console does not substitute for looking: a console with no errors over a broken layout is still a broken layout.
- Describe what you observed, not what the code intends: "screenshot shows the button fully visible at 375px" beats "the button should no longer be cut off."

**Red flags that you're about to violate this:**
- "The flexbox values are right, so the layout is right..."
- "The component renders in the test, so it looks fine..."
- "I'll describe the fix as done; the user will see it anyway..."
- "Checking one viewport is enough — CSS scales..."
- "The styles are simple; no way they interact badly with the parent..."
- "Spinning up a browser for a padding change is overkill..."

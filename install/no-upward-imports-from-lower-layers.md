### No Upward Imports From Lower Layers

NEVER import from a higher layer while editing a lower one. Dependencies point in one direction only: UI imports application, application imports domain, domain imports shared/core. The reverse direction is forbidden at every step.

A lower layer that imports upward drags the entire upper layer into everything that depends on the lower one, and it is the standard first step toward an import cycle.

- Before importing a symbol, note which layer it lives in; if it is above the file you are editing, do not import it
- If a lower layer needs a constant, type, or helper that currently lives above it, MOVE that symbol down to the lower layer (updating the original call sites), or duplicate a trivial constant; never reach up for it
- If a lower layer needs to trigger upper-layer behavior (send a notification, invalidate a UI cache), expose a hook: emit an event, accept a callback, or define an interface the upper layer implements and injects
- Shared/util/core modules are the bottom; they import only the standard library, third-party packages, and each other, never feature or app code
- If you cannot tell which layer a module belongs to, check what the project's existing files in that directory import and match the direction

**Red flags that you're about to violate this:**
- "The error class I need is defined in the API layer, I'll import it from there..."
- "It's just a constant, the direction of the import doesn't matter..."
- "Moving the symbol down means editing files outside my task..."
- "The util can call the notification service directly, it's only one call..."
- "Search found it in features/, but an import is an import..."

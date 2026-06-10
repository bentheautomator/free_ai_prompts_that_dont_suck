### Stop Feeding the God Module

NEVER add new responsibilities to a class or module that is already the largest in its area and already spans multiple unrelated concerns. The fact that everything else lives there is the symptom, not the precedent.

God modules grow one reasonable-looking method at a time, and every addition raises the cost of testing, reviewing, and eventually splitting them.

- Before adding a method to a class, check its size and scan its existing public surface; if it already covers several unrelated domains (auth + export + notifications, say), your method goes somewhere else
- Put the new logic in a small, focused module named for what it does (`InvoiceExporter`, `session_renewal.py`), even if that means creating a file; have the god module delegate to it if callers expect the old entry point
- Do not justify placement with "the dependencies are already injected here"; wire the two dependencies your new code actually needs into its new home
- You are not required to refactor the god module — that's a separate task needing explicit approval — but you are required to stop enlarging it
- If genuinely everything in the codebase routes through this class and there is no other viable seam, say so in your summary instead of silently adding method 148

**Red flags that you're about to violate this:**
- "All the related logic is already in this class..."
- "It already has the database client injected, so it's the easiest place..."
- "One more method on a big class doesn't change anything..."
- "Creating a new file for one function feels like overkill..."
- "I'll add it here now and someone can move it during the big refactor..."

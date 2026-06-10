### Fix Every Instance Not Just the Flagged One

When the user flags a violation at one location, ALWAYS search your work for other instances of the same violation and fix them all. The flagged line is an example, not the extent.

**The core problem:** Corrections arrive with a location attached, so you scope the fix to the location. But the user flagged one instance of a *pattern* — they're telling you about the pattern, and they expect you to find its other occurrences, not to flag each one individually.

**Do this:**

- On any correction, first extract the pattern behind it ("swallowed exceptions" — not "line 52")
- Then sweep everything you've touched this session for the same pattern: other lines, other functions, other files — and fix every instance
- Report the sweep with your fix: "Fixed on line 52, plus 3 more instances of the same pattern (lines 88, 130, and in payments.py)"
- Check near-variants too: if bare `except: pass` was flagged, `except Exception: return None` deserves a look — flag-worthy patterns have cousins

**Do not:**

- Fix exactly the flagged location and stop
- Assume the user reviewed everything and flagged all instances — finding one is usually when they stopped reading and told you
- Wait to be asked "are there others?" — the sweep is part of the fix

**Red flags that you're about to violate this:**

- "Fixed the line they pointed at — done"
- "If the other spots were a problem, they'd have flagged those too"
- "Their comment was specifically about this function"
- "Searching the whole change for this pattern wasn't requested"
- "I'll fix others if they come up"

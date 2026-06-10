### Stop Dumping Code Into Utils

NEVER add a function to a `utils`, `helpers`, `common`, `misc`, or `shared.py`-style grab-bag module, and never create a new one. Every function gets a home named after what it's about.

A module named "utils" has no admission criteria, so it accumulates everything, gets imported by everything, and becomes the file nobody can find anything in or ever safely split.

- Name the concept, then name the module after it: date math goes in `dates.py`, money formatting in `money.py`, slug logic in `slugs.py` — small, single-topic modules, even if today they hold one function
- If the helper is only used by one module, it isn't shared yet; keep it private in that module until a second caller exists
- If the function touches your domain (knows about orders, users, plans), it isn't a utility at all — it's domain logic that belongs in the module that owns that concept
- Grab-bag modules must stay dependency-clean: nothing in a leaf helper module imports the ORM, the web framework, or feature code. If your helper needs those, it has a domain and therefore a real home
- An existing fat `utils.py` is precedent for the disease, not the cure; put your function in a properly named module and leave the pile its current size

**Red flags that you're about to violate this:**
- "It doesn't fit anywhere specific, so utils is the natural place..."
- "There's already a utils.py with stuff like this in it..."
- "A whole new file for one small function seems excessive..."
- "I'll put it in helpers for now and find it a real home later..."
- "It's sort of generic if you squint..."

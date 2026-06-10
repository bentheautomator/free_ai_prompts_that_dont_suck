### Match the Codebase Slicing Axis

ALWAYS determine how the codebase is sliced — by feature (`checkout/`, `billing/`, each self-contained) or by technical layer (`models/`, `services/`, `controllers/`) — before creating any file, and place new code on the same axis. NEVER introduce the other axis.

A codebase's structure is a lookup function; one off-axis addition breaks it for every future search and licenses the next contributor to break it further.

- Before creating a file, list the top one or two directory levels and identify the axis. Then ask: where does the most recently added comparable feature live? Put yours in the same kind of place
- Feature-sliced codebase: a new feature gets a new feature folder with its own models/services/routes inside, mirroring an existing folder's internal layout. Do not create or grow top-level `services/` or `models/` directories
- Layer-sliced codebase: the feature's parts go into the existing layer directories, named consistently with their siblings. Do not create a self-contained feature folder on the side, however much tidier it feels
- Mirror the internal conventions too: if every feature folder has `routes.py`, `service.py`, `models.py`, yours has those names, not `api.py`, `logic.py`, `entities.py`
- If the codebase is mid-migration (both axes present), match the newer pattern — usually findable from recent commits — and say which one you matched

**Red flags that you're about to violate this:**
- "Standard practice is a services layer, so I'll add a services folder..."
- "This feature is cleaner as its own self-contained module..."
- "The tutorial structure for this framework puts models in models/..."
- "I'll organize my new code properly even if the rest isn't..."
- "It's just one file in a new folder, the structure can absorb it..."

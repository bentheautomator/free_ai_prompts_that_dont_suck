### Version-Check Concurrent Updates

Every read-edit-save flow MUST carry a version: reads return it, writes assert it. A write based on stale data must fail visibly, never overwrite silently.

Blind last-write-wins means concurrent editors destroy each other's work with no error anywhere.

- Add a version (integer or timestamp) to mutable records. Update with `UPDATE t SET ..., version = version + 1 WHERE id = ? AND version = ?` and check rows-affected; zero rows means conflict, and conflict is a result to handle, not a row to assume.
- Thread the version through the full loop: API responses include it (field or ETag), edit forms carry it, save requests send it back, the server asserts it (`If-Match` for HTTP APIs). A version checked only server-side against a server-side read guards the wrong gap — the race is across the *user's* edit session.
- On conflict, do something honest: return 409/412 with the current state, let the caller re-fetch, re-apply, or merge. Never auto-retry by re-reading and re-saving the same payload — that's last-write-wins with extra steps.
- Partial updates reduce collisions but don't eliminate them: PATCHing one field still needs a version when the validity of the change depends on state the editor saw.
- Same rule outside databases: document stores (use the native CAS/sequence number), config files, object storage (conditional puts), in-memory stores (compare-and-set). Anywhere two writers can hold copies of one record.
- Background jobs editing records that humans also edit need versions most of all; the job won't file a ticket when its update evaporates.

**Red flags that you're about to violate this:**
- "Two people editing the same record at once basically never happens."
- "Last write wins is a reasonable default; the newest edit is probably right." (Newest *save*, not newest *information*.)
- "Adding version plumbing through the API is a lot of ceremony for a CRUD form."
- "We can add conflict handling later if users complain." (They can't tell what happened, so they won't complain — they'll just lose data.)
- "The ORM's save() handles concurrency." (Check. Most write all fields, unconditionally.)

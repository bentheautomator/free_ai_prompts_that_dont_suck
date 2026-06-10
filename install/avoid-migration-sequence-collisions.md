### Avoid Migration Sequence Collisions

ALWAYS generate migration identifiers with the project's migration tool, and NEVER edit or renumber a migration that may have run anywhere but your machine. The migration sequence is shared with every developer and environment; your local files are not the whole picture.

- Use the framework's generator (`rails g migration`, `alembic revision`, `manage.py makemigrations`, `migrate create`, etc.) to create migrations. It exists largely to mint non-colliding identifiers.
- Never hand-pick "the next number" by looking at the local directory. Unmerged branches are claiming numbers you can't see; current-time timestamps from the generator collide far less than guessed sequences.
- Never backdate or reorder a migration to sort before someone else's. If ordering matters, declare an explicit dependency the tool understands, or coordinate through the human.
- Never modify a migration that has been merged, or that has plausibly run on any shared environment or teammate's machine. Write a new migration that alters the result instead.
- Never rename or delete applied migration files; the tracking table references them by name/ID.
- After pulling or merging, if two migrations share a number or both claim to be "latest," surface the conflict rather than resolving it by editing either file silently.

**Red flags that you're about to violate this:**
- "I'll just create the file myself; the generator is overkill."
- "The last migration is 0042, so mine is 0043."
- "I'll tweak the migration I wrote yesterday instead of adding another."
- "Backdating the timestamp makes it run in the right order."
- "These migration filenames are inconsistent; I'll rename them."

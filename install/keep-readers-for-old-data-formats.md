### Keep Readers for Old Data Formats

NEVER remove or simplify code that reads an old data format because nothing writes that format anymore. Writers follow the code; readers follow the data, and old data outlives old code by years. A v1 reader is dead only when the last v1 record is dead.

Before touching format-handling, deserialization, or migration-on-read code:

- Ask the data question, not the code question: do records in this format still exist anywhere — live tables, cold storage, archives, backups, dead-letter queues, files on customer devices? If you can't verify, the reader stays.
- Distinguish writers from readers explicitly. Retiring a writer is routine; retiring a reader requires evidence that the format is extinct in all storage, including storage outside your reach (anything customers downloaded is forever).
- Check backup and restore paths. Data restored from a snapshot predates every migration that ran after the snapshot; the reader is the only thing standing between a restore and a corruption.
- Treat "lazy migration" code (upgrade-on-read) as load-bearing until the migration is verified complete — meaning someone confirmed zero unmigrated records, not "the migration job ran."
- If asked to remove a legacy format path, propose the safe sequence: measure remaining records, backfill-migrate them, verify zero, then remove the reader. Removal is the last step, never the first.

**Red flags that you're about to violate this:**
- "Nothing has written this format in four years."
- "The migration ran ages ago, all the data is converted."
- "This version check never matches anymore."
- "Old backups don't count, we'd never restore something that old."
- "Files customers downloaded aren't our problem to keep reading."
- "I'll simplify the deserializer to handle only the current format."

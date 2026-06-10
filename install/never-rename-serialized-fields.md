### Never Rename Serialized Fields

NEVER rename a field, property, or enum value on any type that is serialized: to JSON or XML APIs, message queues, document databases, caches, config files, cookies, localStorage, or disk. Those names exist in data you do not control, and the rename orphans every byte already written.

The compiler verifies code against code. Nothing verifies code against stored data; that's your job.

- Before renaming any field, check whether its type flows through serialization: `json.dumps`/`JSON.stringify`, ORM/ODM mappings, protobuf/Avro/Thrift definitions, queue publishers, cache writes, API response builders. If yes, the in-data name is frozen.
- The safe pattern is rename-with-mapping: change the code-level name and pin the serialized name explicitly (`@JsonProperty("usrId")`, `serde rename`, `Field(alias=...)`, ORM `column_name=`). Code gets cleaner; bytes stay compatible.
- Enum values stored in databases or messages are field names' evil twin: renaming `PENDING_REVIEW` breaks every row holding the old string. Same rule, same mapping fix.
- Don't reorder or renumber fields in positional formats (protobuf tags, tuple-based encodings). Position is name.
- Dict keys used as message or cache schemas count, even with no class in sight. `event["usr_id"]` is a wire contract.
- If a true wire-format migration is wanted, that's a project with dual-read/dual-write phases, not a refactor. Propose it separately; never do it inline.

**Red flags that you're about to violate this:**

- "I'll make these field names consistent with the style guide."
- "The rename is safe; the compiler found every usage."
- "This DTO is internal, it just mirrors the API model."
- "Old messages will have drained from the queue by now."
- "Deserialization is lenient, missing fields just default."

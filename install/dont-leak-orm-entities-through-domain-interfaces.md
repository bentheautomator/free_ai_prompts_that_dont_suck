### Don't Leak ORM Entities Through Domain Interfaces

NEVER put infrastructure types — ORM entities, database rows, HTTP request/response objects, framework context objects, message-queue payloads — in the signature of a domain function, service method, or domain interface. Domain code takes and returns plain values and domain types.

Every infrastructure type in a domain signature couples the core to a framework it shouldn't know exists, and drags that framework into every test of the logic.

- Convert at the boundary: the handler/repository maps the entity or request into a domain object (or plain parameters) before calling domain code, and maps the result back on the way out
- A repository's public methods return domain types, not ORM entities; the entity stays inside the repository file
- Passing the entity "because it has all the fields" is the trap — list the fields the function actually uses and pass those; the narrow signature is documentation
- Don't subclass or duck-type around it (a domain type that inherits from the ORM base class is still the ORM)
- If the codebase already passes entities everywhere, follow its convention for this task and note the coupling in your summary — but never extend the leak into a module that is currently clean

**Red flags that you're about to violate this:**
- "The entity already has every field I need, mapping is busywork..."
- "I'll just take the request object so I don't have to pick parameters..."
- "It's basically a data class, the ORM base class doesn't really count..."
- "Defining a separate domain type duplicates the model..."
- "The test can just spin up SQLite, it's fast enough..."

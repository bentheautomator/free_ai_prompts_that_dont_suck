### Never Deserialize Untrusted Data With Unsafe Loaders

NEVER use a deserializer capable of instantiating arbitrary objects on data that crosses a trust boundary. Default to JSON or another data-only format.

Unsafe deserialization is remote code execution: the payload runs during parsing, before your validation code ever sees the data.

- Banned on external or attacker-influenceable data: `pickle.loads`, `yaml.load` (use `yaml.safe_load`), `eval`/`ast.literal_eval` confusion (only `literal_eval` is safe, and prefer JSON anyway), PHP `unserialize`, Java `ObjectInputStream` on raw input, Ruby `Marshal.load`, `node-serialize`/`serialize-javascript` round-trips.
- "Attacker-influenceable" is broad: cookies and anything client-supplied, cache entries (Redis/memcached) if any other process writes them, queue messages, uploaded files, cross-service payloads, and database blobs other code paths can write. Your own storage is not a trust boundary if inputs ever flow into it.
- Default serialization format: JSON. For schemas/performance use protobuf, msgpack (without object extensions), or CBOR. These parse data, not constructors.
- Pickle is acceptable only for same-process or fully internal artifacts (e.g., a local model file you built), and even then prefer formats like safetensors where they exist. Never unpickle anything downloaded.
- If a session/cookie must round-trip server data, sign it (HMAC, or the framework's signed-cookie mechanism) and verify before parsing, and still keep the payload JSON.
- When you encounter existing `yaml.load` or `pickle.loads` in code you're editing, switch to the safe variant or flag it; do not propagate the pattern to new call sites.

**Red flags that you're about to violate this:**
- "Pickle handles arbitrary Python objects, JSON would need a schema..."
- "We wrote this cache entry ourselves, so it's trusted data..."
- "yaml.load is what the older docs show, and it works..."
- "The cookie is ours, the client just stores it for us..."
- "It's an internal queue, only our services publish to it..."
- "I'll validate the object right after deserializing it..."

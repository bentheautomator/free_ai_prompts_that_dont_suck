### Match Existing Response Shapes

NEVER design a response shape for a new endpoint. The API already has one — find it and conform. Same rule for inputs: request body conventions, query parameter naming, and pagination style are inherited, not chosen per endpoint.

Clients consume this API generically through shared unwrappers and error interceptors. An endpoint with its own shape breaks every one of those, and turns uniform client code into per-endpoint special cases.

**Before writing any new endpoint or handler:**
- Read 2-3 existing endpoints — ideally the most recently written ones — and extract the contract: envelope structure, error format, status code usage, pagination scheme, field casing (camelCase vs snake_case), timestamp format, null vs absent-field conventions
- Reuse the existing serializers, response builders, presenter classes, or schema types rather than constructing response dicts/objects inline — if a `make_response()` helper or base serializer exists, that's the API contract in code form
- Your framework's default error format is not the API's error format unless the codebase demonstrably uses it — check how existing handlers return errors before letting the framework answer for you
- Errors conform too: same envelope, same code/message structure, same status-code conventions as the rest of the API
- If the requested feature genuinely can't fit the existing shape, say so and ask — don't quietly ship the exception

**Red flags that you're about to violate this:**
- "I'll return the list directly, simple and clean..."
- "The framework's standard error response is fine here..."
- "I'll add page/limit params for pagination..." (in a cursor-paginated API)
- "Building the response inline is more readable than their serializer machinery..."
- "snake_case is more standard for JSON..." (in a camelCase API)
- Writing a handler without having read what any sibling endpoint returns

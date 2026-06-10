### Check Endpoint Shapes Against the Handlers

NEVER write code against this project's own API from REST convention or intuition. Internal APIs diverge from the textbook in routes, envelopes, field names, pagination, and error contracts — and the actual contract is sitting in the repo.

A guessed shape fails at runtime, one undefined field at a time, each one its own debugging session.

**Before writing any call against a project endpoint:**
- Find the contract's best source, in order: a schema if one exists (OpenAPI/Swagger spec, GraphQL SDL, tRPC/ts-rest routers, zod/joi response schemas, generated API clients), else the handler itself
- Read what the handler actually serializes — the return statement or response builder, including the envelope (`{ data }`? `{ ok, data, meta }`? bare object?) and exact field names with their casing
- Check the error contract separately: status codes used, error body shape, and whether failures can arrive as 200s — error handling written for the wrong contract silently swallows failures
- Confirm route, method, and auth from the router/middleware: path prefixes (`/api/v2`), the actual verb, required headers — not from what a RESTful design would choose
- Look for an existing client call to the same endpoint elsewhere in the codebase and match it — prior art beats both convention and your reading of the handler
- For pagination, match the project's actual mechanism (cursor, offset, page/perPage, Link headers) — pagination is where guessed shapes die quietly

**Red flags that you're about to violate this:**
- "It'll be a standard REST endpoint: GET /api/users/:id..."
- "The response will have the obvious fields..."
- "Errors will come back as 4xx with an error message..."
- "I'll assume camelCase, it's a JS project..."
- "Pagination is probably page and limit params..."
- Writing `response.data.something` for an endpoint whose handler you never read

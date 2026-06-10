### Keep Business Logic Out of HTTP Handlers

NEVER put business rules, calculations, or state transitions inside an HTTP handler, controller, or route function. Handlers translate between the wire and the domain — they do not decide anything.

Logic written in a handler is callable only via HTTP, testable only through the framework, and destined to be copy-pasted into the next entry point that needs it.

- A handler may: parse/validate the request shape, call ONE domain function or service method, and translate the result (including domain errors) into a response. That's the whole job
- Put the actual rule in a domain/service function that takes plain values or domain objects — never the request — and returns a result the handler converts to a status code
- If the handler is growing branches (`if user.plan == "pro" and order.total > ...`), that conditional is domain logic; move it before it grows a sibling
- Database queries that embody business decisions (which records qualify, in what order, with what cutoff) belong behind the domain function too, not inline in the route
- The test for "is the rule correct" must be writable without an HTTP client or test server; if it isn't, the logic is in the wrong place

**Red flags that you're about to violate this:**
- "It's only a few lines of logic, a separate function is ceremony..."
- "The request data is already parsed right here, why pass it along..."
- "This rule is only ever needed by this endpoint..."
- "I'll extract it later if another caller shows up..."
- "The framework docs put logic in the handler in their examples..."

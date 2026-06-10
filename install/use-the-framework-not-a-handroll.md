### Use the Framework, Not a Handroll

NEVER hand-implement functionality that the project's framework or installed dependencies already provide. Before writing infrastructure-flavored code — pagination, validation, serialization, auth checks, caching, retries, date math, query building, escaping, parsing — check whether the stack already does it.

Your hand-rolled version will be longer, less correct, and permanently owned by this team. The framework's version has had its edge cases beaten out of it by years of other people's incidents.

**Before writing such code:**
- Check what the framework offers: ORMs paginate, validate, and escape; web frameworks parse, route, and handle CORS; standard libraries do more than you assume
- Check the installed dependencies (`package.json`, lockfiles, `requirements.txt`, `go.mod`) — a project with `zod` installed wants schemas, not if-chains; a project with `date-fns` wants `addDays`, not millisecond arithmetic
- Check how the codebase already solves it: if existing endpoints use the framework's paginator, your endpoint does too
- Treat hand-rolling as the option of last resort, taken only when the stack genuinely lacks the facility — and say so when you do, so the choice is visible
- Security-adjacent handrolls (escaping, sanitization, crypto, query construction) are forbidden outright when any library alternative exists

**Red flags that you're about to violate this:**
- "This is simple enough to implement directly..."
- "I'll write a small utility rather than pull in machinery..."
- "A custom version gives us more control..."
- "I don't see them using the framework's feature, so I'll roll my own..." (did you look?)
- "It's just date math / just escaping / just a regex..."
- Writing infrastructure code without having checked the dependency manifest this session

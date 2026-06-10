### Construct Dependencies at the Composition Root

NEVER construct stateful or configurable dependencies — database connections, HTTP clients, repositories, service objects, queue producers — inside business logic. Construction happens at the composition root (main, app startup, the DI container, the request factory); everything below receives its dependencies as constructor or function parameters.

Code that builds its own dependencies has decided, unilaterally and invisibly, which implementation, which config, and which lifecycle the whole application gets.

- A class that needs a repository takes it in its constructor; the place that builds the class supplies it. If that means a parameter ripples up a level or two, that ripple is the wiring becoming visible — it's the feature, not the cost
- Find the codebase's existing composition root before inventing one: a `main()`, an app factory, a DI container, framework startup hooks. Add new wiring there, in the established style
- Don't read config (env vars, settings) deep in the call stack to build things; config is read at the root, dependencies are built from it once, and objects receive them
- Value objects and pure data (a dataclass, a datetime, a Decimal) are constructed wherever needed — this rule is about dependencies with identity, state, configuration, or I/O
- Don't overcorrect into a framework: passing parameters IS dependency injection; introducing a DI container the codebase doesn't have is a rival-pattern violation, not compliance
- If you're three layers deep and the dependency isn't available, the fix is adding it to the constructor chain — not `new`, not a global, not a `get_client()` that hides the `new`

**Red flags that you're about to violate this:**
- "I'll just create the client here, it's only used in this function..."
- "Threading it through two constructors is too much plumbing..."
- "Reading the env var here is simpler than passing config down..."
- "A fresh connection per call is fine, it's not hot code..."
- "I'll add a helper that constructs it on demand..."

### Don't Couple Feature Modules Sideways

NEVER import from a sibling feature module while working inside another feature. Features depend downward — on `core/`, `shared/`, the domain layer — never on each other. A useful function in a sibling is not importable just because it's reachable.

Every feature-to-feature import converts two independently testable, deletable modules into one entangled pair, and the entanglement compounds with each edge.

- Before importing, classify the source: shared/core (fine, that's what it's for), your own feature (fine), a sibling feature (stop)
- If a sibling has logic you need, it's evidence the logic is actually shared: move it DOWN into `shared/` or `core/` (updating the sibling's call sites), then import it from there
- If what you need is the sibling's *behavior* (its data, its decisions — "what's this user's loyalty tier?"), that's an integration, not an import: use the codebase's sanctioned mechanism for cross-feature interaction — a public API the feature deliberately exposes, the domain layer, or events — and if none exists, flag it rather than improvising one
- Don't launder the dependency: copying the sibling's non-trivial logic wholesale, or re-exporting it through shared without moving it, preserves the coupling and hides it
- Trivial code (a three-line formatter) can simply be duplicated; independence is worth more than deduplicating three lines

**Red flags that you're about to violate this:**
- "The exact function I need already exists in the loyalty module..."
- "It's not a cycle and it's not upward, so the import is clean..."
- "Moving it to shared means touching another team's files..."
- "These two features are related anyway..."
- "It's only one import between siblings, the modules are still separate..."

### Don't Duplicate Domain Logic Across Layers

NEVER reimplement a business rule that already exists in another layer. One rule, one implementation, one owner — every other layer calls it, asks it, or receives its verdict as data.

Copies of a rule are correct only on the day they're written; every subsequent change to the rule is a chance for the copies to disagree, and the user sees whichever copy their request hits.

- Before writing any conditional that encodes business knowledge (thresholds, eligibility, state transitions, pricing), search for that rule by its constants and its vocabulary; if it exists anywhere, call it instead of rewriting it
- Frontend needing a rule's verdict gets it FROM the backend: a `requires_approval` field on the API response, computed by the one real implementation — not a reimplementation in the component
- Database queries that need a rule (reports, filters) should consume values the domain layer computed and stored (a flag, a status column), not re-derive the rule in SQL
- Client-side pre-validation for UX is legitimate, but it's a *courtesy copy* of the server's rule: keep it trivial, derive it from server-provided data where possible (limits in the API response), and never let it be the only enforcement
- If you genuinely must duplicate (offline clients, performance), leave a comment at both sites naming the other location — drift you can find beats drift you can't

**Red flags that you're about to violate this:**
- "It's a one-line check, importing the service is heavier than writing it..."
- "The frontend can't call the domain layer, so I'll just re-code the rule..."
- "The report query needs the logic in SQL anyway..."
- "I know what the rule is, I don't need to find the existing one..."
- "The two implementations are identical, so it's fine..."

### Don't Introduce a Rival Pattern

NEVER introduce a new pattern for a problem the codebase already solves an established way. Before writing the structural parts of a change — data fetching, error handling, dependency wiring, validation, state management — find two or three existing examples and match them.

A second pattern doesn't replace the first one; it coexists with it forever, and every reader pays for both.

- Before structuring new code, open the most recently touched files that do the same kind of thing; their shape is the spec
- Match the codebase even where your preferred pattern is genuinely better — consistency beats local optimality, because the next maintainer extrapolates from what exists
- This covers mechanisms, not just style: don't add a DI container to a constructor-injection codebase, an event emitter to a direct-call codebase, exceptions to a result-type codebase, or a new folder convention to an established layout
- If the existing pattern truly cannot express what the task needs, say so explicitly and propose the new pattern as a decision for a human — don't smuggle it in inside a feature diff
- If the codebase has two competing patterns already, match the one in the area you're touching, or the more recent one; don't add a third

**Red flags that you're about to violate this:**
- "The way I know is cleaner than what they're doing..."
- "This is the standard/modern approach, they'll want it eventually..."
- "It's a new file, so existing conventions don't constrain it..."
- "I'll do it the better way here and it can be the new direction..."
- "The pattern difference is small, nobody will notice..."

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

### Don't Make Everything Pluggable

NEVER build pluggability machinery — registries, plugin loaders, hook systems, strategy selection from config, string-keyed dispatch tables — unless the current task contains at least two real variants or an explicit requirement for runtime selection. One behavior is a function call, written directly.

Every behavior moved from code into configuration trades type-checked, navigable, greppable control flow for runtime lookup — that's a real price, paid for flexibility that usually never gets used.

- One exporter is `export_csv(...)` called directly — no registry, no `format` config key, no `get_exporter("csv")`
- Two real variants in this task is a plain `if`/`match` or a dict of functions at the call site — visible, typed, all cases in one screen. Registries start earning their keep around variant four or five, or when variants live outside the core (actual plugins)
- Don't add config options for decisions nobody asked to configure: every knob is a code path that needs testing in all positions and an invitation for production to differ from every test
- Don't dispatch on strings when the variants are known at build time; the type checker can't tell `"csv"` from `"cvs"` and neither will the AI editing this code next year
- If the codebase already has a real registry with multiple registered implementations, register into it — this rule bans founding new empires, not following existing ones
- Asked explicitly for a plugin architecture? Build it. This rule is about inventing the requirement, not refusing it

**Red flags that you're about to violate this:**
- "A registry makes it trivial to add new formats later..."
- "I'll make it configurable so we don't have to touch code to change it..."
- "Hardcoding the choice feels inflexible..."
- "This is how the big frameworks structure it..."
- "It's just one config key and one lookup table..."
- "Future exporters can self-register, it's elegant..."

### Don't Reach Into Module Internals

NEVER import another module's internals: underscore-prefixed names, files under `internal/` or `_private/` paths, symbols absent from the module's `__init__.py`/`index.ts` exports, or anything the module's public surface doesn't offer. Use the public interface or change it — never tunnel under it.

Every external import of an internal converts an implementation detail into an unbreakable contract the owner doesn't know they've signed.

- The public surface is what the module exports at its top level (its `__init__.py`, `index.ts`, package API, or documented entry points); if you'd need a deep path like `other_module/internal/helpers` to reach a symbol, that symbol is off-limits
- If the capability you need exists only as an internal, do one of: (a) add it to the module's public exports if it genuinely belongs to that module's job, (b) move it down into a shared module if it's generic, or (c) write your own — for small helpers, duplication beats a boundary violation
- Don't dodge enforcement: no copying a private function verbatim "to avoid the import," no re-exporting someone's internal through your own module, no reflection/dynamic import tricks
- Test code gets no exemption for other modules' internals; test through the public API or the tests will fossilize the implementation
- When you promote an internal to public (option a), you're changing that module's contract — name it in your summary so the owner sees it

**Red flags that you're about to violate this:**
- "The function I need already exists, it's just in their private file..."
- "The underscore is only a convention, the import works fine..."
- "Adding it to their public API means modifying their module..."
- "I'll copy the private helper so I'm not technically importing it..."
- "It's just a test, reaching into internals doesn't count there..."

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

### Keep Business Rules Out of the Data Layer

NEVER put business decisions in the data layer: no business logic in ORM lifecycle hooks (`save()`, `before_update`, signals), no business definitions baked into repository query methods, no database triggers or stored procedures that make domain decisions. The data layer stores and retrieves; the domain layer decides.

Logic below the domain layer executes invisibly on every persistence path — including the migrations, imports, and scripts that never asked for it.

- Side effects (fees, notifications, status changes) happen in an explicitly named domain operation — `apply_late_fee(invoice)`, called by whoever decides it's time — never in a save hook that fires whenever anything touches the row
- Repositories answer mechanical questions (`users_with_login_since(date)`), with parameters; the *business meaning* of "active" lives in one named domain function or spec that supplies those parameters
- ORM models can hold field-level derivations (`full_name`), but the moment a method consults plans, dates, or money to make a decision, it's domain logic in the wrong building
- Database constraints for integrity (foreign keys, uniqueness, NOT NULL) are good and encouraged — they enforce data shape, not business policy. Triggers that compute fees or flip statuses are policy in the basement
- If you find yourself adding a `skip_hooks` or `raw_save` flag, that's the architecture telling you the hook logic never belonged there

**Red flags that you're about to violate this:**
- "The save hook guarantees the rule always runs..."
- "The model already has all the fields the rule needs..."
- "I'll put the filter in the repository so callers can't get it wrong..."
- "A trigger means even manual SQL respects the rule..."
- "It's just one condition in the query..."

### Match the Codebase Slicing Axis

ALWAYS determine how the codebase is sliced — by feature (`checkout/`, `billing/`, each self-contained) or by technical layer (`models/`, `services/`, `controllers/`) — before creating any file, and place new code on the same axis. NEVER introduce the other axis.

A codebase's structure is a lookup function; one off-axis addition breaks it for every future search and licenses the next contributor to break it further.

- Before creating a file, list the top one or two directory levels and identify the axis. Then ask: where does the most recently added comparable feature live? Put yours in the same kind of place
- Feature-sliced codebase: a new feature gets a new feature folder with its own models/services/routes inside, mirroring an existing folder's internal layout. Do not create or grow top-level `services/` or `models/` directories
- Layer-sliced codebase: the feature's parts go into the existing layer directories, named consistently with their siblings. Do not create a self-contained feature folder on the side, however much tidier it feels
- Mirror the internal conventions too: if every feature folder has `routes.py`, `service.py`, `models.py`, yours has those names, not `api.py`, `logic.py`, `entities.py`
- If the codebase is mid-migration (both axes present), match the newer pattern — usually findable from recent commits — and say which one you matched

**Red flags that you're about to violate this:**
- "Standard practice is a services layer, so I'll add a services folder..."
- "This feature is cleaner as its own self-contained module..."
- "The tutorial structure for this framework puts models in models/..."
- "I'll organize my new code properly even if the rest isn't..."
- "It's just one file in a new folder, the structure can absorb it..."

### Never Import the Data Layer From UI

NEVER import repositories, ORM models, query builders, or database clients into UI code (components, views, pages, templates, frontend route files). UI talks to the service/API layer; only the service layer talks to data.

A direct UI-to-data import bypasses every rule the service layer enforces (authz, caching, tenant scoping, soft deletes) and welds screens to the database schema.

- If the UI needs data the service layer doesn't expose, extend the service layer: add the field to an existing method or add a new method, then call that from the UI
- Do not import ORM entities into components "just for the type"; use or create the DTO/view-model type the service layer returns
- Do not copy an existing direct import you find in the UI; one violation is a bug, not a precedent
- Server-rendered frameworks count: page loaders, `getServerSideProps`-style functions, and template helpers go through services too, not straight to the ORM
- If no service layer exists at all in this codebase, follow whatever its actual boundary is; this rule is about skipping a layer that exists, not inventing one

**Red flags that you're about to violate this:**
- "It's just one field, going through the service is ceremony..."
- "I'll query the repository directly here and clean it up later..."
- "Another component already imports the model, so it's the pattern..."
- "This is a read-only call, the service layer rules don't matter for reads..."
- "Adding a service method means touching three files for a one-line change..."

### No Circular Imports Between Modules

NEVER add an import that creates a dependency cycle between modules or packages. Before importing from module B while editing module A, check whether B (directly or transitively) already imports A.

Cycles fuse two modules into one untestable blob, and in Python/JavaScript they cause load-order bugs that pass locally and fail in production.

- Before adding a cross-module import, grep the target module for imports of the module you are editing; if any exist, stop and restructure instead
- If both modules need the same type or helper, move it DOWN into a module both can depend on (`shared`, `core`, `types`), never sideways
- If A needs to trigger behavior in B and B already depends on A, invert it: B passes a callback, B subscribes to an event A emits, or A exposes an interface that B implements
- Do not "fix" a cycle with a lazy import, an import inside a function body, a deferred `require()`, or a type-only import that hides a real runtime dependency; these conceal the cycle, they don't remove it
- In Go or other languages where the compiler rejects cycles, do not merge the two packages to make the error go away; restructure the dependency instead

**Red flags that you're about to violate this:**
- "The type I need is right there in billing, one import won't hurt..."
- "I'll just import it inside the function so it resolves at call time..."
- "It's only a type import, that doesn't really count as a dependency..."
- "The compiler complains about the cycle, so I'll combine the packages..."
- "Tests pass, so the import order must be fine..."

### No Event Bus for Direct Calls

NEVER use events, signals, pub/sub, or a message bus for an interaction with one known consumer whose outcome the caller depends on. That interaction is a function call; write it as one.

Events replace a visible, typed, error-propagating call with invisible control flow — that price is only worth paying when you actually need what events provide.

- Events are justified when at least one is true: multiple independent consumers exist TODAY; consumers can't be known at build time (plugin systems); or the work is truly fire-and-forget AND failure must not affect the caller. Otherwise: direct call
- "Might have more subscribers later" doesn't count — the second consumer justifies the event when it arrives, and converting a call to an event then is a small, mechanical change
- If the caller needs the result, needs errors to surface, or needs the work inside its transaction, an event is wrong regardless of consumer count
- Don't create the in-process event for "decoupling" while both modules sit in the same deployable importing the same types; that's coupling with extra steps and worse stack traces
- When you legitimately emit an event, the producer must remain correct if zero listeners are attached — if it wouldn't be, the dependency is real and should be a call
- This cuts both ways: where the codebase has a real event architecture with multiple consumers, add your consumer as a listener — don't bolt a direct call across it

**Red flags that you're about to violate this:**
- "Emitting an event keeps these modules decoupled..."
- "Someone else might want to listen to this someday..."
- "The task said 'when an order is placed,' so it sounds like an event..."
- "Events make it more extensible..."
- "I'll fire the event and the listener will handle failures itself..."

### No Interfaces With One Implementation

NEVER create an interface, abstract base class, or trait that has exactly one implementation and no concrete second implementation planned in the current task. Write the concrete class; extract the interface when the second implementation actually arrives.

An abstraction designed against one example is guesswork, and it taxes every reader and every signature change until someone deletes it.

- One email sender means one class: `SmtpEmailSender` or just `EmailSender`, concrete. No `IEmailSender`, no `AbstractEmailSender`, no factory returning the only option
- "We might swap the database later" is not a second implementation; a second implementation is code that exists or is in this task's requirements
- Test doubles do not justify an interface in languages with duck typing, monkeypatching, or mocking libraries that fake concrete classes; only extract one if the language genuinely requires it for substitution, and say so
- If the codebase has an established convention of interfaces at a particular boundary (e.g., all repositories), follow the convention; this rule is about inventing new speculative ones
- When a real second implementation shows up, extract the interface FROM the two concrete examples; that interface will be shaped by evidence instead of imagination

**Red flags that you're about to violate this:**
- "I'll add an interface so it's easy to swap implementations later..."
- "This makes it more testable..." (the mocking library fakes concrete classes fine)
- "It's a best practice to program against interfaces..."
- "The factory keeps construction flexible..."
- "It only costs one extra file..."
- "Enterprise codebases always do it this way..."

### No New Top-Level Directories Without Precedent

NEVER create a new top-level directory, package, or module without first mapping the existing structure and confirming the new code has no home in it. The default is always: new code goes inside the structure that exists.

The top level of a repo is its table of contents; every unprincipled addition makes the whole codebase less predictable, and root directories are nearly permanent once CI, deploys, and imports reference them.

- Before creating any directory at or near the root, list what's there and state (to yourself, concretely) what the level is organized by — features? layers? deployables? If your code fits one of the existing entries, it goes there
- "Doesn't fit perfectly" usually means "fits imperfectly in an existing place," which beats a new root entry: webhook handlers fit an existing `api/`; a new vendor client fits an existing `integrations/` or the module that uses it
- Check for near-misses before minting: a `webhooks/` next to an existing `api/inbound/`, a `helpers/` next to an existing `lib/`, a `scripts/` next to an existing `tools/` — synonym directories are the most common form of this failure
- If the code genuinely has no home — a truly new kind of thing for this repo — propose the new directory in your summary with its organizing rationale, rather than silently creating it; root-level structure is a team decision, not a diff detail
- Apply the same discipline one level down in large repos: a new top-level package inside `src/` or a new app in a monorepo carries the same costs

**Red flags that you're about to violate this:**
- "This is a new kind of thing, it deserves its own top-level folder..."
- "I'll make a new directory so my changes don't disturb existing code..."
- "The existing folder names don't quite match what I'm adding..."
- "A fresh module keeps my work self-contained..."
- "It's just a folder, we can always move it later..."

### No Shared Mutable Config Objects

NEVER mutate a shared config, settings, or context object after startup, and NEVER use one as a channel to pass data between components. Configuration is read-only after load; data flows through parameters and return values.

A mutable config bag is an untyped global with delivery service: every write creates an invisible dependency between the writer and whoever reads the key, sequenced only by luck.

- Treat config as frozen at startup: load it, validate it, then make it immutable (frozen dataclass, `Object.freeze`, read-only properties). All keys exist in the schema/class definition — no runtime key invention
- If step 2 computes something step 5 needs, return it from step 2 and pass it to step 5 — yes, that changes signatures; the signature change IS the documentation of the data flow
- If a component needs a variant of the config (shorter timeout, different endpoint), derive a new immutable copy for that scope; never edit the shared instance in place
- Don't widen a god-context as the workaround: adding `ctx.results`, `ctx.scratch`, or a `extras` dict to the config type is the same bag with a type annotation
- Per-request or per-job state lives in a per-request object created and discarded with the request — never in anything shared across requests

**Red flags that you're about to violate this:**
- "The config already flows through every step, it's the easiest channel..."
- "I'll stash the intermediate result on the context and read it later..."
- "Changing the return types of three functions is too invasive..."
- "I'll set the flag temporarily and put it back after the call..."
- "It's config-adjacent, so the config object is the natural home..."
- "Everything else already reads and writes this object..."

### No Singletons for Shared State

NEVER create a singleton, module-level instance, or `getInstance()` accessor to share a stateful object (database pools, caches, clients, sessions, registries). Shared dependencies are passed explicitly — as parameters, constructor arguments, or app context — so every function's signature tells the truth about what it uses.

A singleton is a global with a design-pattern alibi: it hides a dependency from every signature, couples tests through shared state, and hardwires "exactly one of these per process" into the architecture.

- If two components need the same object, construct it once where the app starts and pass it to both; "where the app starts" is the one place allowed to know how everything is built
- Don't initialize stateful objects at module import time; importing should never connect, open, or allocate
- A `get_db()` accessor reading a module global is the same singleton with extra steps; so is a class with all-static methods holding state
- Stateless constants and pure functions at module level are fine — this rule is about state and connections, not about banning module-level code
- If the codebase already has an established singleton (e.g., a framework-managed app object), use it rather than adding a parallel one — but do not mint new ones

**Red flags that you're about to violate this:**
- "Passing this through four layers means touching four files..."
- "Everything needs the config, so it should just be globally available..."
- "It's not a global, it's the singleton pattern..."
- "There will only ever be one of these anyway..."
- "I'll add a getInstance() so callers don't need it injected..."
- "The tests can just reset it in teardown..."

### No Upward Imports From Lower Layers

NEVER import from a higher layer while editing a lower one. Dependencies point in one direction only: UI imports application, application imports domain, domain imports shared/core. The reverse direction is forbidden at every step.

A lower layer that imports upward drags the entire upper layer into everything that depends on the lower one, and it is the standard first step toward an import cycle.

- Before importing a symbol, note which layer it lives in; if it is above the file you are editing, do not import it
- If a lower layer needs a constant, type, or helper that currently lives above it, MOVE that symbol down to the lower layer (updating the original call sites), or duplicate a trivial constant; never reach up for it
- If a lower layer needs to trigger upper-layer behavior (send a notification, invalidate a UI cache), expose a hook: emit an event, accept a callback, or define an interface the upper layer implements and injects
- Shared/util/core modules are the bottom; they import only the standard library, third-party packages, and each other, never feature or app code
- If you cannot tell which layer a module belongs to, check what the project's existing files in that directory import and match the direction

**Red flags that you're about to violate this:**
- "The error class I need is defined in the API layer, I'll import it from there..."
- "It's just a constant, the direction of the import doesn't matter..."
- "Moving the symbol down means editing files outside my task..."
- "The util can call the notification service directly, it's only one call..."
- "Search found it in features/, but an import is an import..."

### No Wrappers Around Wrappers

NEVER add a layer that only forwards to another layer. A wrapper is justified when it makes a decision, enforces a policy, or changes the abstraction level — not when it renames methods and passes arguments through.

Pass-through layers add a file to every navigation, a hop to every stack trace, and a mandatory edit to every signature change, in exchange for nothing.

- Before wrapping something, check whether it is itself already a wrapper (a thin module over a library or client); if so, the strong default is to extend or use the existing wrapper, not stack a new one on it
- A layer earns its existence by doing at least one of: enforcing policy (retries, auth, limits), translating between abstraction levels (HTTP to domain objects), or isolating a third-party API behind a project-owned seam. "Nicer name for our codebase" is not on the list
- If you need one convenience default, add a function or parameter to the existing layer instead of a class around it
- Never wrap to shorten a call: `get_user(id)` forwarding to `client.get(f"/users/{id}")` is a one-line saving that costs a permanent file
- When you find yourself writing a method whose body is a single call with the same arguments in a different order, stop — delete the method and call the target directly

**Red flags that you're about to violate this:**
- "I'll make a service class so the calls look cleaner..."
- "Wrapping it gives us a place to add logic later..."
- "Every other client has a wrapper, this one should too..."
- "The existing client's method names don't match our naming style..."
- "It's only a thin layer, it doesn't really count as indirection..."

### One Owner Per Piece of State

NEVER write to state that another module owns. Every table, field, cache, file, or store has exactly one owning module; everyone else reads through its interface and requests changes through its functions.

A second writer bypasses every invariant the owner enforces — validations, transitions, side effects, cache coherence — and creates bugs that only reproduce depending on who wrote last.

- Before writing to any shared state, find who else writes it: grep for updates to that table/field/key. If another module is the established writer, call its function instead of writing directly
- If the owner doesn't expose the operation you need (e.g., no `mark_shipped()`), ADD that function to the owner — that's a smaller change than a second writer, even though it touches another module
- Direct `UPDATE`/`SET` from outside the owning module is a bypass even when the SQL is correct, because the owner's side effects (events, audit rows, cache busts) don't fire
- This applies to in-memory state too: don't mutate another module's exported dict, store, or cached object; call its mutator
- If ownership is genuinely ambiguous (two modules already write it), don't silently become the third — flag the conflict in your summary

**Red flags that you're about to violate this:**
- "It's just one UPDATE, going through the orders module is overkill..."
- "The owning module doesn't have a function for this, so I'll write directly..."
- "Adding a method to their module is out of my task's scope..."
- "I'm setting the same value their code would set anyway..."
- "The field is public/the table is shared, so writing it is allowed..."

### Put Cross-Cutting Concerns at Seams

NEVER implement a cross-cutting concern — logging, auth checks, retries, timing, rate limiting, tracing, input sanitization, transaction wrapping — inline in individual functions. These belong at the codebase's seams: middleware, decorators, interceptors, base classes, or wrapper utilities that apply uniformly.

Inline copies are almost-uniform by construction: the gaps and drift between copies are exactly where the security holes and unsearchable logs live.

- First, find the seam the codebase already has: a middleware stack, a `@requires_auth`-style decorator, an interceptor chain, a `with_retries()` helper. Use it. Most codebases have one; the failure is not looking
- If the seam exists but lacks your case (a new permission level, a new retry policy), extend the seam — one change, every route — instead of going inline in your handler
- If no seam exists and you need the concern in 3+ places, build the smallest one (a decorator or wrapper function is enough) and apply it; don't lay copy number one of a future fifty
- Never hand-roll an inline retry loop, manual timing pair, or ad-hoc permission check next to an established mechanism that does the same thing
- Concern logic that genuinely varies per function (a domain-specific audit message) can be inline — but the transport of it (how it's logged, where it goes) still flows through the seam

**Red flags that you're about to violate this:**
- "I'll just add the check at the top of this one function..."
- "Touching the middleware affects every route, that feels too risky..."
- "The other handlers all have this block inline, so I'll match them..."
- "A retry loop is six lines, a shared helper is overkill..."
- "This endpoint is special, it can do its own logging..."

### Put Vendor SDKs Behind a Seam

NEVER import a vendor service SDK (payments, email, SMS, storage, analytics, LLM APIs) outside the one module that owns that integration. The rest of the codebase calls the seam — a project-owned module with project-shaped functions — and never sees the vendor's types.

A vendor imported in fifty files isn't a dependency, it's an organ; the seam keeps it an appliance.

- One module per integration (`payments/stripe_gateway.py`, `notifications/email.py`): SDK imports, client construction, auth, retries, and vendor config all live there and only there
- The seam's functions speak the project's language — take and return your domain types or plain values, never the vendor's response objects; translate vendor exceptions into your error types at the seam
- Before adding a vendor import, grep for existing ones: if the seam exists, use it; if scattered imports exist, use or create the seam for your call and don't add scatter point fifty-four
- Don't pre-build a multi-provider abstraction with interfaces and factories — the seam is just the single place the vendor is touched, not a speculative provider framework
- Infrastructure SDKs used AS infrastructure (your web framework, your database driver inside the data layer) don't need this; the rule covers swappable external services, not your foundation
- Vendor-managed config (API keys, endpoints) is read inside the seam, not threaded through callers

**Red flags that you're about to violate this:**
- "The quickstart shows calling the SDK right from the handler..."
- "It's one API call, routing it through another module is bureaucracy..."
- "Other files already import the SDK directly, so it's the pattern..."
- "We'll never switch vendors anyway..."
- "I'll catch their SDK's exception type here, it's more specific..."

### Respect the Read-Write Split

If the codebase separates reads from writes — query services vs. command handlers, read models vs. write models, replicas vs. primary — NEVER put a mutation in the read path or build a new read flow against the write model. Work within the side your task belongs to, even when crossing would be a smaller diff.

The split's value is its guarantees: reads are cacheable, retryable, replica-safe, and side-effect-free precisely because nothing ever writes there. One exception deletes the guarantee for every caller.

- Before touching a method, determine which side it's on: naming (`*QueryService`, `*ReadModel`, `commands/`, `queries/`), the database handle it uses, and what its siblings do. Then stay on that side
- A task that needs both ("show the profile AND record the view") is two operations: the query stays pure, and the write goes through a command — dispatched by the caller or handler, not smuggled into the getter
- Don't read your own writes through the read model immediately after a command if the read side is eventually consistent (replicas, projections); return what the command knows, or read from the write side within that flow if the codebase has a pattern for it
- New display/listing/reporting features go against the read side, even if the write model technically has the data — bypassing the read model forks the codebase's answer to "where do reads come from"
- If the task genuinely requires changing what the read model contains, that's a projection/view change on the read side, not a write-side query bolted on
- No split in this codebase? Then this rule is dormant — don't introduce CQRS to follow it

**Red flags that you're about to violate this:**
- "It's just a timestamp update, the query method already has the row..."
- "Adding a whole command for this tiny write is ceremony..."
- "The write model has all the fields, I'll query it directly..."
- "One side effect in a getter won't hurt anything..."
- "I'll read it back right after writing, it's the same database... probably..."

### Stop Dumping Code Into Utils

NEVER add a function to a `utils`, `helpers`, `common`, `misc`, or `shared.py`-style grab-bag module, and never create a new one. Every function gets a home named after what it's about.

A module named "utils" has no admission criteria, so it accumulates everything, gets imported by everything, and becomes the file nobody can find anything in or ever safely split.

- Name the concept, then name the module after it: date math goes in `dates.py`, money formatting in `money.py`, slug logic in `slugs.py` — small, single-topic modules, even if today they hold one function
- If the helper is only used by one module, it isn't shared yet; keep it private in that module until a second caller exists
- If the function touches your domain (knows about orders, users, plans), it isn't a utility at all — it's domain logic that belongs in the module that owns that concept
- Grab-bag modules must stay dependency-clean: nothing in a leaf helper module imports the ORM, the web framework, or feature code. If your helper needs those, it has a domain and therefore a real home
- An existing fat `utils.py` is precedent for the disease, not the cure; put your function in a properly named module and leave the pile its current size

**Red flags that you're about to violate this:**
- "It doesn't fit anywhere specific, so utils is the natural place..."
- "There's already a utils.py with stuff like this in it..."
- "A whole new file for one small function seems excessive..."
- "I'll put it in helpers for now and find it a real home later..."
- "It's sort of generic if you squint..."

### Stop Feeding the God Module

NEVER add new responsibilities to a class or module that is already the largest in its area and already spans multiple unrelated concerns. The fact that everything else lives there is the symptom, not the precedent.

God modules grow one reasonable-looking method at a time, and every addition raises the cost of testing, reviewing, and eventually splitting them.

- Before adding a method to a class, check its size and scan its existing public surface; if it already covers several unrelated domains (auth + export + notifications, say), your method goes somewhere else
- Put the new logic in a small, focused module named for what it does (`InvoiceExporter`, `session_renewal.py`), even if that means creating a file; have the god module delegate to it if callers expect the old entry point
- Do not justify placement with "the dependencies are already injected here"; wire the two dependencies your new code actually needs into its new home
- You are not required to refactor the god module — that's a separate task needing explicit approval — but you are required to stop enlarging it
- If genuinely everything in the codebase routes through this class and there is no other viable seam, say so in your summary instead of silently adding method 148

**Red flags that you're about to violate this:**
- "All the related logic is already in this class..."
- "It already has the database client injected, so it's the easiest place..."
- "One more method on a big class doesn't change anything..."
- "Creating a new file for one function feels like overkill..."
- "I'll add it here now and someone can move it during the big refactor..."

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

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

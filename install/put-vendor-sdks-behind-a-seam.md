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

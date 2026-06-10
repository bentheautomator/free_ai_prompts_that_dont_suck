### Never Put Secrets in Frontend Code or Bundles

NEVER place a secret in code delivered to the client. `NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, and `EXPO_PUBLIC_` prefixes inline the value into the public bundle; they are publication mechanisms, not configuration.

If the browser can use the key, every visitor has the key. Minification, compilation, and obfuscation do not change this.

- Before exposing any env var to the client, classify it: publishable values (analytics IDs, map keys with referrer restrictions, Stripe *publishable* keys, public API URLs) may use the prefix; secret keys, service-role keys, signing secrets, and database URLs may not, ever.
- When a frontend needs a privileged API, build the thin backend route: the browser calls `/api/your-endpoint`, the server (API route, edge function, serverless function) holds the key in a non-prefixed env var and makes the real call. This is the fix for "the key is undefined in the browser," not the rename.
- The same rule covers mobile and desktop apps: keys in compiled binaries are extracted with `strings` and a proxy. "Compiled" is not "secret."
- Distinguish key types by name: Stripe `pk_` is publishable, `sk_` is secret; Supabase `anon` key is public-by-design (RLS enforces security), `service_role` bypasses RLS and must never reach a client. If unsure which kind a key is, treat it as secret and ask.
- Server-only secrets should fail loudly if imported into client code; where the framework supports it, use its taint/server-only mechanisms (`import "server-only"`) on modules that read secrets.
- If a secret has already shipped in a bundle, rotation is mandatory; deleting it from the next deploy doesn't recall the cached JS.

**Red flags that you're about to violate this:**
- "Renaming it NEXT_PUBLIC_ fixes the undefined error..."
- "The key is needed client-side, so it has to be in the bundle..."
- "It's minified and the variable name is mangled, nobody will find it..."
- "This is a mobile app, the binary isn't readable like a webpage..."
- "Adding a backend route for one API call is over-engineering..."
- "It's a low-value key, even if someone finds it, who cares..."

### Verify the Package Exists Before Installing

NEVER install a package whose existence and identity you have not verified against the registry. A plausible name is not a real name — hallucinated package names get registered by attackers specifically to catch this mistake, and installation alone executes their code.

- Before any `npm install`, `pip install`, `cargo add`, `gem install`, or equivalent: verify the package on the registry first. Use `npm view <name>`, `pip index versions <name>` or the PyPI page, `cargo search <name>`, or fetch the registry URL directly.
- Verify identity, not just existence: does the description match what you expect? Does it have a real repository link, a plausible download count, and a version history older than a few weeks? A name that exists but was first published last month with no repo is a red flag, not a green light.
- Be especially suspicious of names you produced by analogy: "the Python version is probably called X," "the official SDK is probably `@vendor/thing`." Analogy is exactly how hallucinated names are formed.
- If you cannot verify (no network, registry unreachable), say so and present the install command for the user to vet — do not run it.
- Scoped/official packages: confirm the scope is the vendor's actual scope, not a lookalike.

**Red flags that you're about to violate this:**
- "The package is probably just called that."
- "It follows the usual naming convention, so this should be it."
- "The install will fail anyway if it doesn't exist."
- "I remember this package from somewhere."
- "It's the official SDK, the name is obvious."

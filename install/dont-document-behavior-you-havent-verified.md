### Don't Document Behavior You Haven't Verified

NEVER write documentation stating how the system behaves unless you verified that behavior against the actual code, config, or output. Plausible is not verified.

The problem: documentation hallucination produces confident, specific, wrong claims that readers treat as ground truth precisely because they are written down.

Rules:
- Before documenting a default, limit, timeout, ordering, or format, find the line of code or config that defines it, and document what that line says
- Before documenting what a command or endpoint returns, run it or read the code path that produces the response; do not document from the function name
- Distinguish your sources in your own head: read-the-code facts, ran-it facts, and assumed facts. Only the first two go in docs as statements
- If something can't be verified right now (external service, missing credentials), either omit it or mark it visibly: "Unverified: appears to retry 3 times based on `MAX_ATTEMPTS`"
- Never let general knowledge fill gaps. What caching layers, queues, or ORMs "usually do" is not what this one does
- Specific numbers are the highest-risk claims. Every concrete value in your doc needs a concrete source in the repo

**Red flags that you're about to violate this:**
- "This is how these systems typically work..."
- "The function name implies it returns JSON..."
- "I'll fill in a reasonable default value..."
- "Checking the actual code would take too long for a doc..."
- "It almost certainly retries; everything retries..."
- "The doc reads better with a specific number..."

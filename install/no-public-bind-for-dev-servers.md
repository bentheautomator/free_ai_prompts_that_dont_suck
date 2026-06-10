### Never Bind Dev Servers and Debug Tools to 0.0.0.0

NEVER fix a connectivity problem by binding development services to all interfaces. Default to `127.0.0.1`; widen only as far as the specific need requires, and never with debug modes or unauthenticated services.

`0.0.0.0` means "everyone who can reach this machine," and on cloud VMs and shared networks that's not a metaphor. Internet-wide scanners find newly exposed ports in minutes.

- Dev servers, REPLs, admin UIs, and anything with `debug=True` bind to `127.0.0.1` by default. Flask debug mode on a reachable interface is remote code execution via the Werkzeug console; Node's `--inspect` is a REPL in your process — keep both strictly local.
- Docker compose: `ports: "6379:6379"` publishes on all host interfaces. Write `ports: "127.0.0.1:6379:6379"` for host-only access — and container-to-container traffic usually needs no `ports` at all; containers on the same network reach each other by service name.
- Inside a container, where `0.0.0.0` is required for port mapping, the security boundary moves to the host's publish address and the cloud security group; verify those are restrictive before calling it done, and say so.
- Databases and caches reachable beyond localhost get a password first (`requirepass`, auth enabled), exposure second. Unauthenticated Redis/Mongo/Elasticsearch on a network interface is a published copy of your data.
- Need access from a phone or teammate: prefer a tunnel (SSH `-L`, mesh VPN, the framework's tunnel option) or knowingly bind to the specific LAN interface, on a trusted network, without debug mode.
- Never combine the broad bind with `debug=True`, default credentials, or a disabled firewall to make the test work; that stack of "temporary" choices is the standard breach recipe.

**Red flags that you're about to violate this:**
- "0.0.0.0 is the standard fix for container networking..."
- "It's just my dev machine, nobody is scanning it..."
- "The database has no data worth stealing yet..."
- "I'll bind wide to test from my phone, then change it back..."
- "We're behind the office firewall, the LAN is trusted..."
- "The compose file needs the port published or the app can't reach Redis..."

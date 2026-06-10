---
title: Never Bind Dev Servers and Debug Tools to 0.0.0.0
slug: no-public-bind-for-dev-servers
category: security
tags: [universal, security]
works_with: all
severity: high
one_liner: "AI exposing debug servers and databases on all interfaces to fix connectivity"
---

# Never Bind Dev Servers and Debug Tools to 0.0.0.0

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from exposing development servers, databases, and debug ports to the whole network.

**[Copy-paste ready version](../../install/no-public-bind-for-dev-servers.md)** — just the instruction block, no explanation.

## The Problem

"I can't reach the dev server from my phone/another container/the VM host." The connectivity fix every AI knows: bind to `0.0.0.0`. `app.run(host="0.0.0.0", debug=True)`, `--host 0.0.0.0` on Vite or webpack-dev-server, `command: redis-server --bind 0.0.0.0` with `ports: "6379:6379"` in compose, a Node `--inspect=0.0.0.0:9229` to attach a debugger from outside a container. Connection achieved — for you and for everyone else who can route to the machine: the coffee-shop WiFi, the corporate LAN, or the entire internet if the box is a cloud VM with a permissive security group.

What's listening matters more than the bind itself. Flask with `debug=True` on all interfaces serves the Werkzeug console — arbitrary code execution over HTTP. A Node inspector port is a JavaScript REPL inside your process. Dev databases bound publicly run with no password (dev Redis and Mongo famously so), and compose's `ports: "6379:6379"` publishes to all host interfaces by default — countless "test instance" databases have been found, dumped, and ransomed by scanners that sweep the IPv4 space continuously. The AI suggests these binds because they end the connectivity complaint in one flag, and nothing in the local experience reveals who else just got access.

The legitimate need (reach the server from another device or container) has narrower answers: bind to the specific interface, publish ports as `127.0.0.1:port:port`, or tunnel.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It separates the bind from the boundary.** Inside containers `0.0.0.0` is genuinely required, which is why blanket bans fail; teaching that the control moves to the publish address and security group keeps the rule applicable instead of ignorable.

2. **It names the two RCE-grade listeners.** Werkzeug's console and Node's inspector turn "exposed dev server" from untidy into game-over; models treat binds as connectivity trivia until those two are in context.

3. **It corrects the compose misconception doing the most damage.** "The app can't reach Redis without ports:" is false (service-name networking) and is the reason half of all dev databases are published; fixing the mental model removes the motive.

4. **It legitimizes the narrow alternatives.** Tunnels and loopback-scoped publishes solve the actual phone-testing and host-access needs, so the secure option competes on convenience instead of asking for sacrifice.

## Origin

To demo a prototype to a client from a cloud VM, an assistant started the Flask app with `host="0.0.0.0", debug=True` — the exact incantation from a thousand tutorials. The security group allowed the port broadly so the client could see it. A scanner found the Werkzeug debugger within the week and executed code through it; the VM's instance role then provided a path into the team's storage buckets. The demo could have run behind an SSH tunnel with debug off, a difference of one flag and one command.

---
title: Lower the TTL Before Changing DNS
slug: dns-lower-ttl-before-changes
category: devops
tags: [universal, devops, dns]
works_with: all
severity: critical
one_liner: "Changing a DNS record under a long TTL with no rollback for cached answers"
---

# Lower the TTL Before Changing DNS

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from flipping a DNS record that resolvers worldwide will keep serving the old way for the next 24 hours.

**[Copy-paste ready version](../../install/dns-lower-ttl-before-changes.md)** — just the instruction block, no explanation.

## The Problem

DNS changes are the rare infrastructure mutation where the undo button is physically disabled for a while. Change an A record that carries a 86400-second TTL and every resolver that looked it up in the past day keeps the old answer for up to a day — and if the new value is wrong, changing it back doesn't help the resolvers that already cached the mistake. There is no command that flushes the world's caches. The TTL you had *before* the change governs how long the change takes to land; the rollback window is whatever TTL you set *on* the bad record.

AI assistants treat DNS records like any other config value: edit, apply, verify with one `dig`, report success. The `dig` against authoritative servers looks perfect immediately, which is exactly why the AI believes the change is done while a global cache slowly splits traffic between old and new answers for hours. Cutover plans that needed the old endpoint kept alive ("we'll just point DNS at the new load balancer and tear down the old one") fail in the gap.

The professional sequence is well-known and never improvised by an AI unprompted: lower the TTL ahead of time, wait out the *old* TTL, make the change, verify from multiple resolvers, restore the TTL after stability.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Lower the TTL Before Changing DNS

NEVER change a DNS record without first checking its current TTL and reasoning about propagation. DNS changes propagate on the old TTL's schedule and cannot be recalled from caches; a record change is a staged migration, not an edit.

- Before any change, query the live record: `dig +noall +answer example.com A` — note the value and the TTL. The current TTL is your propagation delay and, for mistakes, your minimum exposure time.
- For planned cutovers on records with TTL above ~300s: lower the TTL first (e.g. to 60), wait at least the duration of the *previous* TTL so caches expire, then change the value. Restore the longer TTL only after the new target is verified stable.
- Keep the old destination serving until the old TTL has fully elapsed after the change, plus margin. Resolvers that cached the old answer will keep sending traffic there; tearing it down at flip time strands them.
- Verify from public resolvers, not just authoritative: `dig @1.1.1.1`, `dig @8.8.8.8`. Authoritative answering correctly proves nothing about caches.
- Treat MX, NS, and apex records as the highest tier: mistakes bounce mail or take the whole zone dark, for TTL-length minimum. Present these changes for explicit human review with the dig output attached.
- State the rollback honestly: "revert the record, but cached resolvers serve the bad answer for up to <TTL>." If that exposure is unacceptable, the TTL must come down before the change, not after.

**Red flags that you're about to violate this:**

- "DNS propagates fast these days, the TTL is mostly theoretical..."
- "dig already shows the new value, the change is live..."
- "If it's wrong I'll just change it back..."
- "The old load balancer can be deleted now that DNS points elsewhere..."
- "I'll set a long TTL on the new record for performance..."

---

## Why It Works

1. **It reframes a record edit as a staged migration.** The AI's config-edit model has apply and revert as symmetric instant operations; stating that caches make both asymmetric and slow replaces the model that causes every downstream mistake.

2. **It forces the TTL read before the write.** One `dig` turns "propagation" from folklore into a number, and the number drives the plan — a 60s TTL and an 86400s TTL legitimately call for different procedures.

3. **It separates authoritative truth from cached reality.** "dig shows the new value" is the precise observation that misleads; requiring checks via public resolvers aligns verification with what users actually experience.

4. **It ties teardown to TTL expiry.** The costliest variant of this failure is decommissioning the old endpoint at flip time; making "old destination stays up through old-TTL-plus-margin" an explicit step closes it.

## Origin

A migration moved an API to a new load balancer: the assistant updated the A record (TTL 86400), confirmed with dig, and helpfully deleted the old load balancer as cleanup, all in one session. For the next day, every client whose resolver held the cached answer connected to a load balancer that no longer existed. Traffic recovered resolver by resolver over 24 hours, support wrote the same apology several hundred times, and the runbook gained a new first line: read the TTL before you touch the record.

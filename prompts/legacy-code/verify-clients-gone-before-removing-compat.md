---
title: Verify Clients Are Gone Before Removing Compat Branches
slug: verify-clients-gone-before-removing-compat
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: critical
one_liner: "Keeps compatibility paths alive while real clients still send legacy traffic"
---

# Verify Clients Are Gone Before Removing Compat Branches

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting backward-compatibility code for old clients that are, in fact, still out there sending requests.

**[Copy-paste ready version](../../install/verify-clients-gone-before-removing-compat.md)** — just the instruction block, no explanation.

## The Problem

Compatibility branches age badly in appearance and beautifully in function. A block that says `// handle legacy request format from v2 clients` looks like a fossil: the comment is old, the format is ugly, and surely everyone upgraded years ago. An AI assistant doing cleanup sees a code path for "clients that no longer exist" and removes it. The problem is that the nonexistence was inferred from the age of the comment, not from any evidence about traffic.

Old clients are immortal in ways that are easy to forget: mobile apps that users never update, embedded devices flashed once and deployed for a decade, enterprise customers contractually pinned to an integration version, partner systems maintained by nobody. The compatibility branch wasn't kept by accident — it was kept because removing it breaks paying customers, and that calculation doesn't expire just because the code got older.

The failure is brutal because it's asymmetric: the cleanup saves thirty lines, and the breakage hits exactly the customers least able to update — that's why they were on the old path.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Clients Are Gone Before Removing Compat Branches

NEVER remove backward-compatibility code based on its age or on an assumption that old clients upgraded. The only valid evidence that a compat path is dead is data showing zero traffic on it over a meaningful window.

Before touching any compatibility branch:

- Look for telemetry, metrics, or access logs that would show hits on the legacy path. If you cannot see that data, say so explicitly — you cannot verify, and unverifiable means it stays.
- Run `git log` on the branch. Find out when it was added and why; the commit or PR usually names the client population it serves.
- Assume the worst-case clients exist: unupdated mobile apps, embedded/IoT devices, pinned enterprise integrations, partner systems in maintenance mode. The clients least likely to upgrade are the ones the branch exists for.
- If the user asks for the removal, ask whether traffic data confirms zero legacy usage and over what window. Seasonal clients (tax software, school systems, annual billing) need a window of a year, not a month.
- Propose deprecation instrumentation as the safe alternative: add logging/metrics to the legacy path now, remove it later with evidence.

A compat branch with no traffic data is not dead code. It is unmeasured code.

**Red flags that you're about to violate this:**
- "That client version is ancient, nobody runs it anymore."
- "The comment says this was temporary, and that was six years ago."
- "If anyone were still using this, we'd have heard about it."
- "The new format has been available forever, everyone migrated."
- "This branch makes the function twice as long for no modern benefit."
- "I'll remove it and we can revert if someone complains."

---

## Why It Works

1. **It replaces inference with measurement.** "Old comment, therefore extinct clients" is the exact reasoning chain that causes the failure; demanding traffic data severs it.
2. **It enumerates the immortal-client zoo.** Unupdated apps, flashed devices, pinned enterprise contracts — naming them makes "nobody uses this" feel as unlikely as it actually is.
3. **The instrumentation off-ramp converts the urge to delete into the prerequisite for deleting.** The AI gets to act on the compat branch today in a way that makes safe removal possible later.
4. **The seasonal-window rule closes the most common measurement trap:** thirty days of silence from a client that connects quarterly proves nothing.

## Origin

A request handler carried a branch translating an obsolete XML payload shape, commented "remove after v3 migration" with the migration four years done. An assistant removed it during a cleanup pass; review agreed it was obviously dead. Eleven days later a regional logistics partner's warehouse scanners — running firmware nobody had touched since installation — started failing every check-in. The partner's contract had penalty clauses for integration downtime. The branch was restored within hours; the goodwill took considerably longer.

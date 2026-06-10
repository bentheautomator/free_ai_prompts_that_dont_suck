---
title: Alias Renamed API Query Params
slug: alias-renamed-api-query-params
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops query param renames where old params get silently ignored, not rejected"
---

# Alias Renamed API Query Params

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming query parameters so that requests using the old name silently lose their filters instead of erroring.

**[Copy-paste ready version](../../install/alias-renamed-api-query-params.md)** — just the instruction block, no explanation.

## The Problem

Query parameters fail differently from almost everything else in an API: unknown ones are *ignored*. When the AI renames `?user_id=` to `?userId=`, or `?from=`/`?to=` to `?start_date=`/`?end_date=` while standardizing an endpoint, a caller sending the old name doesn't get a 400. The server simply doesn't see the filter, and the endpoint falls back to its default — which for a filter param usually means *everything*.

That inversion is the danger. A request meant to fetch one user's records now fetches all users' records, with a 200 status and plausible-looking JSON. An export filtered to last week now exports the full table. A consumer polling `?since=<last_run>` re-processes the entire history every run. Depending on what's downstream, that's a performance incident, a data-correctness incident, or — when the filter was doing tenant scoping the authorization layer assumed — something the security team gets paged about. The caller has no signal anything changed.

AI assistants rename params casually because the framework binding makes it look like a variable rename: change the annotation, change the handler signature, update the repo's own calls, done. The silent-ignore semantics of query strings never enter the picture.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Alias Renamed API Query Params

NEVER rename a query parameter on an existing endpoint without keeping the old name working as an alias. Unknown query params are silently ignored, so callers using the old name don't get errors — they get *unfiltered results*, which is usually the most dangerous possible response.

- A renamed filter param fails open: `?user_id=7` on an endpoint that now reads `userId` returns every user's data with a 200. For scoping, date-range, and `since`-style params, silent ignoring means data over-exposure or full-history reprocessing, not a visible bug.
- If a rename is justified, accept both names: read the new param, fall back to the old one, and document the old as deprecated. The alias stays until a human retires it with usage data.
- The same applies to changing a param's *value format* (IDs to UUIDs, dates to a new format, comma-separated to repeated params): old-format values that no longer match return empty or unfiltered results, not errors. Keep parsing the old format alongside the new.
- Framework migrations are the high-risk moment: binding annotations and handler-signature names often *are* the param names. After migrating, diff the full set of accepted param names per endpoint against the old code.
- Where a previously-honored param can no longer be honored at all, prefer rejecting requests that send it (explicit 400 with a pointer to the replacement) over silently ignoring it — a loud failure beats quietly unfiltered data.

**Red flags that you're about to violate this:**
- "I'm aligning all query params with the camelCase convention."
- "The handler signature changed, so the param name follows automatically."
- "Old callers will notice immediately if their param stops working."
- "It still returns 200 for old-style requests, so it degrades gracefully."
- "Nobody passes that param anyway — it's not used in any of our calls."

---

## Why It Works

1. **It names the fails-open semantics of query strings.** The AI's implicit model is that wrong input produces errors; stating that unknown params are ignored — and that ignored filters return *more* data — reverses the assumed failure direction.
2. **It ranks silent-unfiltered as worse than a 400**, giving the AI a correct preference ordering it otherwise lacks (it usually treats any non-error response as the gentler option).
3. **It extends the rule to value formats**, catching the rename's stealth twin where the param name survives but old values stop matching anything.
4. **It targets framework migrations explicitly**, where param renames happen as a side effect of signature changes and never appear as a decision.

## Origin

While standardizing an endpoint's parameters, an assistant renamed `?account_id=` to `?accountId=`, updating the web app in the same repo. A reporting service owned by another team kept sending `account_id`, and its nightly export — previously scoped to one client account — began exporting all accounts' rows. The job ran successfully for eleven nights, each report quietly containing other clients' data, before a customer noticed unfamiliar records in their export. What started as a casing cleanup ended as a disclosure review.

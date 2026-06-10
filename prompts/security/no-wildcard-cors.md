---
title: Never Fix CORS Errors With Wildcard Origins
slug: no-wildcard-cors
category: security
tags: [universal, security, headers]
works_with: all
severity: critical
one_liner: "AI adding Access-Control-Allow-Origin star to silence a CORS error"
---

# Never Fix CORS Errors With Wildcard Origins

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from opening your API to every origin on the internet because the browser console showed a red error.

**[Copy-paste ready version](../../install/no-wildcard-cors.md)** — just the instruction block, no explanation.

## The Problem

A CORS error appears in the browser console. It looks like a bug, so the AI fixes it the way half the internet suggests: `Access-Control-Allow-Origin: *`, or `app.use(cors())` with no options, or the genuinely catastrophic version that reflects whatever `Origin` header arrives back into the response with `Access-Control-Allow-Credentials: true`. The error disappears. What also disappears is the browser's same-origin protection for your API: any website a logged-in user visits can now make credentialed requests to your endpoints and read the responses.

AIs treat CORS as a connectivity problem rather than what it is, an access-control declaration. The blocked request is the browser asking "should arbitrary-website.com be able to read this user's data from your API?" and the wildcard answers "yes, everyone should." Reflecting the origin while allowing credentials is worse than `*`, because browsers at least refuse to combine `*` with credentials; the reflection trick exists specifically to defeat that safety check, and AI assistants suggest it constantly because it "makes credentials work."

The correct fix is almost always a one-line allowlist of the origins you actually own.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Fix CORS Errors With Wildcard Origins

NEVER respond to a CORS error by allowing all origins. CORS is an access-control policy, not a connectivity bug; the fix is naming the origins that should have access.

- Do not set `Access-Control-Allow-Origin: *` on any endpoint that serves user-specific data or sits behind authentication.
- Do not reflect the request's `Origin` header back unconditionally, and never combine reflection with `Access-Control-Allow-Credentials: true`. That grants every website on the internet credentialed access to the API.
- Configure an explicit allowlist instead: `cors({ origin: ["https://app.example.com", "https://staging.example.com"] })` or the framework equivalent. Add the dev origin (`http://localhost:3000`) explicitly for local work.
- Validate allowlist entries by exact match. Do not match with `startsWith` or a substring regex; `https://app.example.com.evil.io` passes both.
- `*` is acceptable only for truly public, unauthenticated, non-user-specific resources (public CDN assets, an open dataset), and say so in a comment when you use it.
- If the CORS error is happening because frontend and backend ports differ in dev, prefer a dev-server proxy over loosening the API's policy.

**Red flags that you're about to violate this:**
- "The wildcard unblocks development and we can tighten it before launch..."
- "Reflecting the origin is the standard workaround when you need credentials..."
- "It's an internal API, CORS doesn't really matter here..."
- "The mobile app doesn't send an Origin header anyway, so this is harmless..."
- "Every Stack Overflow answer for this error says to allow all origins..."
- "I'll match any subdomain of example.com with a regex to keep it flexible..."

---

## Why It Works

1. **It reframes CORS from bug to policy.** The AI's failure starts with misclassifying the error as breakage. Once CORS is framed as an access-control question, "allow everyone" is obviously the wrong answer rather than the obvious fix.

2. **It singles out origin reflection.** This is the variant AIs produce when the wildcard fails with credentials, and it is strictly worse. Most CORS guidance never mentions it; naming it removes the workaround-of-the-workaround.

3. **It closes the substring-match hole.** AIs that do build allowlists frequently validate with regex or `includes()`, which attackers bypass with crafted domains. Exact match is stated as the rule.

4. **It provides the dev-proxy alternative.** The legitimate trigger is local development friction; offering the proxy means the AI has a correct move available instead of just a prohibition.

## Origin

A frontend hitting a new API got CORS errors in staging, and the assistant resolved them with middleware that echoed the incoming origin and enabled credentials, since the wildcard "didn't work with cookies." It shipped. Months later a security researcher demonstrated reading any logged-in user's profile and messages from a page they controlled. The fix that should have happened originally was a three-entry origin allowlist.

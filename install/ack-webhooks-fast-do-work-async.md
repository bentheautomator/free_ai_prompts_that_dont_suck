### Ack Webhooks Fast, Do Work Async

A webhook handler's job is to durably accept the event and return 2xx within a couple of seconds. NEVER run slow or multi-step business logic inline before responding to a webhook: providers time out slow responses, count them as failures, redeliver into your now-busy service, and eventually disable the endpoint.

- In the handler do only: verify the request, persist the event (insert into a table or publish to a queue), return 200. Everything else happens in a worker that consumes what you persisted.
- The persistence step must be durable before you respond. Acking and then doing the work from memory means a crash after the 200 silently loses the event, and the provider will never resend it — you told it delivery succeeded.
- No outbound API calls, email sends, file generation, or fan-out inside the handler. One slow third party in that path becomes your timeout.
- Status codes signal delivery, not business outcome. If the event is stored, return 200 even though processing hasn't happened yet; report processing failures through your own job retries and alerts, not the webhook response.
- Keep the synchronous path's only failure modes to "could not verify" and "could not persist" — those are the cases where you genuinely want the provider to retry.
- If the work is truly trivial (set one flag, one indexed update), inline is fine. The moment there's a second side effect or any network call, move it behind the queue.

**Red flags that you're about to violate this:**
- "The processing only takes a second or two, well within the timeout."
- "Adding a queue for this one webhook is over-engineering."
- "I'll do the work first so I can return an accurate status code."
- "The provider's timeout is 30 seconds, we have plenty of room."
- "If processing fails, returning 500 gets us a free retry from the provider."
- "I'll respond 200 immediately and then keep processing in this request."

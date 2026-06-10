### Don't Share One Connection Across Tasks

NEVER let multiple concurrent tasks use a single connection, session, or cursor unless its documentation explicitly guarantees concurrent use. Default assumption: stateful clients are single-task objects.

A connection is a protocol state machine; two concurrent users interleave commands and read each other's results.

- Share the *pool*, not a connection: acquire per task/request, release when done. Wrong: `conn = pool.acquire()` at module scope. Right: acquire inside the handler, in a `with`/`try-finally` that guarantees release.
- Never fan out on one connection: `gather(q1(conn), q2(conn), q3(conn))` interleaves three queries on one wire. Either run them sequentially on that connection or acquire one connection per concurrent query.
- ORM sessions (SQLAlchemy `Session`, EF `DbContext`, Hibernate `Session`) are single-task objects, full stop. One per request/task; never a module-level or singleton session.
- Check the contract before sharing anything stateful: HTTP clients are usually designed for concurrent use; DB connections, cursors, SMTP/IMAP/FTP clients, and serial ports usually are not. "It has async methods" is not the same claim as "it supports concurrent calls."
- Transactions bind to connections: everything in one transaction must run on the one connection that opened it, and *only* that work runs there until commit/rollback.
- If a connection must be shared (a single websocket, a serial line), serialize access through one owner task and a queue — others submit messages, never touch the socket.

**Red flags that you're about to violate this:**
- "One connection for the whole app is more efficient than a pool."
- "The client has async methods, so concurrent calls must be fine."
- "I'll cache the acquired connection so I don't pay acquisition cost per request."
- "These three queries are read-only, they can't conflict." (They share one result stream.)
- "It's worked fine so far." (Requests haven't overlapped yet.)

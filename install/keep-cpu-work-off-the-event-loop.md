### Keep CPU Work Off the Event Loop

NEVER run heavy synchronous work — CPU-bound computation or blocking I/O — directly inside an async handler on a single-threaded event loop. While it runs, every other request in the process is frozen.

`async` marks where a function *can* yield, not a guarantee that it does; everything between awaits blocks the world.

- Offload CPU-bound work: Node `worker_threads` or a job queue; Python `loop.run_in_executor` / `ProcessPoolExecutor` (threads don't help CPU-bound Python; processes do); never inline in the handler.
- Ban sync I/O in async contexts: `fs.*Sync`, `execSync`, `child_process.spawnSync`, Python `requests`/`time.sleep`/blocking DB drivers inside `async def`. Use the async equivalents (`asyncio.sleep`, async clients) or push to an executor.
- Watch for hidden CPU: parsing/serializing large JSON or XML, compression, encryption and password hashing, image processing, regex over big inputs (catastrophic backtracking blocks too), sorting or transforming very large arrays.
- Big-input loops that must stay inline need explicit yield points (chunk the work, `await setImmediate()` / `await asyncio.sleep(0)` per chunk) — and that's the fallback, not the plan.
- Treat input size as attacker-controlled: a parse that's fine at 100KB is an outage at 100MB. Bound it or offload it.

**Red flags that you're about to violate this:**
- "The function is async, so it won't block anything."
- "It's only ~50ms of CPU." (Times every request, on the only thread you have.)
- "The sync version is simpler and the async one needs a worker."
- "It ran instantly when I tested it." (Alone, with a small input.)
- "Hashing/zipping/parsing isn't really 'heavy computation.'"

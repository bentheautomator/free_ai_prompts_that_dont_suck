### Use the Project Logger

NEVER log with raw `print`, `console.log`, `fmt.Println`, `System.out`, or `echo` in a codebase that has logging infrastructure. Find how this project logs and log that way.

Raw output bypasses everything the logging setup provides: levels, structured formatting, bound request context, and routing. A print statement is invisible to the aggregator, unfilterable in production, and uncorrelatable during incidents — which is to say, useless exactly when logs matter.

**When adding any log output:**
- Find the project's pattern first: search for `logger`, `log.`, `getLogger`, `createLogger` and copy how an existing module obtains its logger — module-level instance, injected dependency, factory call, whatever the convention is
- Never construct a fresh logger with default config (`logging.basicConfig`, `new winston.Logger()`) when a project factory or shared instance exists — that forks the configuration
- Use the project's conventions for the message itself: structured fields vs interpolated strings (`logger.info("order processed", order_id=oid)` vs f-strings, if that's the house style), message casing, and which context fields get attached
- Choose levels the way the codebase does: `debug` for diagnostic detail, `info` for normal operations, `warning`/`error` per the patterns in similar code — don't log routine success at `error` or failures at `info`
- If the project genuinely has no logging setup (scripts, tiny tools), plain output is fine — this rule is about bypassing infrastructure that exists

**Red flags that you're about to violate this:**
- "I'll just print a quick status message..."
- "console.log is fine for this..."
- "I'll set up a basic logger for this module..." (the project already has one)
- "The message text is what matters, not how it's emitted..."
- "I'll log the whole object so everything's visible..." (structured fields exist for this)
- Writing a log line without having looked at how the neighboring module logs

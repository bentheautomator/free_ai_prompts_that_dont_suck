### Log Caught Errors at Error Level

Log levels are routing, not tone. A real failure logged below ERROR is invisible to the alerting and dashboards that watch for failures — record it at the severity that gets it seen.

- A caught exception representing a failed operation is logged at ERROR, with the exception and stack attached: `logger.error("payment sync failed for order %s", oid, exc_info=True)` / `logger.error("sync failed", err)` — not debug, not info, not a message without the exception
- Never use `print(e)` or `console.log(err)` for failures in code that has a logger; use the logger at error level (`console.error` at minimum in plain JS)
- Reserve the lower levels for what they route to: WARN for degraded-but-handled (retry succeeded, fallback engaged deliberately), INFO for normal operations, DEBUG for diagnostics — a failure that broke the operation is none of these
- Don't inflate either: logging expected, handled conditions at ERROR (every cache miss, every validation rejection of user input) trains humans and alert thresholds to ignore the channel — severity inflation and severity deflation both end in missed incidents
- The test for level: who needs to act? Someone should be alerted → ERROR. Worth noticing in review → WARN. Nobody → INFO/DEBUG
- When you downgrade an existing `logger.error` to reduce noise, you are editing alerting behavior; say so explicitly rather than slipping it into an unrelated diff

**Red flags that you're about to violate this:**
- "I'll print the exception so it shows up during testing..."
- "Debug level keeps production logs clean..."
- "It's caught, so warning seems more accurate than error..."
- "console.log is fine; it all goes to the same place..."
- "I don't want this to trigger alerts, so I'll log it lower..."

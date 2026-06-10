### Open the Logs Before Claiming No Errors

NEVER claim "no errors," "runs cleanly," or "nothing in the logs" unless you identified where this system records errors and actually looked there, after your change ran.

The core problem: systems are built to keep errors out of the foreground — caught exceptions go to log files, browser consoles, stderr, and error trackers. Watching one quiet channel and declaring the system error-free is testimony about places you never visited.

- Before the claim, enumerate the error channels this system has: application log files, stderr (separately from stdout), the browser devtools console for anything with a frontend, the framework's error log, worker/queue failure records, error-tracking services if present.
- Check the relevant ones after exercising your change — filtered to the time window of your run, so you're not crediting yourself with pre-existing noise or blaming yourself for it.
- Greppable evidence beats impressions: search the window for ERROR, WARN, exception, traceback, and the failure vocabulary of this stack. Say what you searched and what came back.
- A rendered page is not a clean console. Error boundaries and caught promises let UIs look perfect over a console full of red. For frontend claims, the console check is mandatory.
- Scope honestly when access is partial: "stdout and the app log are clean; I cannot see the error tracker from here" is a verifiable claim. "No errors" while blind to half the channels is not.
- Warnings you find don't get rounded down to nothing. "Clean except two deprecation warnings, quoted below" is the accurate sentence.

**Red flags that you're about to violate this:**
- "Nothing printed, so nothing went wrong..."
- "The page rendered fine; the console is surely fine too..."
- "If there were errors, I'd have seen them..."
- "Tailing the log file is extra ceremony for a small change..."
- "The framework would have crashed if something failed..."
- "stderr is probably empty — stdout was..."

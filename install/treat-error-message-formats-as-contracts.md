### Treat Error Message Formats as Contracts

NEVER reword, restructure, or change the severity/level of an existing error message or log line as a side effect of other work. Once shipped, error text is an interface: alerts, dashboards, runbooks, and scripts on other teams match it by exact string.

The break is silent — a monitor matching old text doesn't fail, it just stops firing.

- When editing a function, leave its existing error messages, log lines, error codes, and log levels byte-for-byte alone unless changing them is the task.
- New messages are yours to write; existing messages belong to whoever is parsing them.
- This includes "harmless" edits: punctuation, capitalization, switching to structured logging, changing `ERROR` to `WARN`, reordering interpolated values, translating, or adding a prefix.
- Error codes, exception class names, and machine-readable error fields are even harder contracts than the human text. Never rename them in passing.
- If the task does require changing a shipped message, flag it explicitly: old text, new text, and a note that downstream alerting and runbooks may match the old string and need updating.
- When adding context to an error, prefer appending new fields or a new line over rewriting the line that exists.

**Red flags that you're about to violate this:**
- "This error message is unclear; I'll improve it while I'm here."
- "Switching this to structured logging is a strict upgrade."
- "It's just a log line, nothing depends on log lines."
- "This is clearly WARN-level, not ERROR — easy fix."
- "I'll standardize all these messages to the same format."

### No Unrequested Logging

Do not add logging, print statements, or debug output unless the request asks for it. Code you edit for other reasons keeps exactly the log statements it had.

The core problem: ad-hoc log statements bury real signals in noise, leak payload data into log storage, and impose an observability "style" the project never chose.

- No entry/exit announcements ("Starting X...", "X complete") around functions you write or modify
- No logging of payloads, records, or variables for visibility; logged data is stored, retained, and accessed under different rules than the source data, and secrets or PII in logs are incidents
- No `print`/`console.log` left behind from your own debugging during the task
- Do not change levels, formats, or messages of existing log lines in passing
- If the task involves diagnosing a problem, temporary instrumentation is fine while you investigate, but remove it before delivering unless asked to keep it
- If you believe a specific failure point genuinely warrants a permanent log line, propose it in one sentence with the level and message, and let the user decide

**Red flags that you're about to violate this:**
- "I'll add some logging so this is easier to debug later..."
- "A quick info line here improves observability..."
- "Logging the payload will help when something goes wrong..."
- "Good production code logs its progress..."
- "I'll leave my debug prints in, they might be useful..."

### Read the Logs Before Theorizing

ALWAYS exhaust the output that already exists — logs, consoles, CI output, stderr, journals — before constructing any theory about a failure. Systems narrate their failures; read the narration first.

Logs record what happened. Code only records what was supposed to happen. When you skip the logs, you choose reconstruction-from-theory over an eyewitness account.

- Step one for any failure: locate and read its output channels — application log, the failing command's full stdout/stderr, the browser console and network tab, the CI job's complete log (not just the failed-step summary), service journals
- Read generously around the failure, not just the final error line: the cause frequently appears as a warning seconds or minutes earlier, and the first anomaly matters more than the last message
- Look for what's *absent* too — an expected "server started" or "job completed" line missing tells you where execution actually stopped
- Repeated lines are data: the same warning 800 times is a different story than once, so check counts and timestamps, not just unique messages
- If the log is huge, search it for the failure timestamp, error keywords, and the request/job ID, rather than declaring it too big and reverting to theory
- Only when the existing output is read and insufficient do you move to adding instrumentation or hypothesizing from code — and your theory must not contradict anything the logs already said

**Red flags that you're about to violate this:**
- "Let me look at the code to figure out what could cause this..." (the log is right there)
- "The error summary says it failed; that's all the output I need..."
- "The log file is huge, I'll reason from the code instead..."
- "The console probably doesn't have anything useful..."
- Forming a theory the existing logs already contradict
- Asking the user what happened when the system wrote down what happened

### Wait for the Job to Finish Before Reporting Success

NEVER report the outcome of an asynchronous or long-running job — background process, CI pipeline, batch script, deploy, scheduled task — unless you observed its terminal state. Starting a job successfully is evidence the job started.

The core problem: launch and outcome are separate events separated by time, and the session keeps moving through that time. By the summary, "kicked off" has quietly inflated into "completed."

- Every job you start creates a debt: before claiming its outcome (or saying "done" about anything depending on it), check that it reached a terminal state — completed, failed, cancelled — and which one. "Running" and "queued" are not outcomes.
- Poll or wait deliberately: check the process exit, the pipeline conclusion, the job status API. If your tooling reports background-task completion, read that report before summarizing, not after.
- Verify the job's product, not just its status, when something depends on it: the artifact exists, the rows moved, the new version responds. A "succeeded" status with no output is a fresh problem, not a success.
- If you genuinely must hand off before completion, report launch as launch: "started <job>; it was still running as of <check>; confirm completion with <command>." Never decorate an in-flight job with past-tense success.
- Track your open jobs across the session. The failure mode is forgetting the debt exists — re-scan for unfinished launches before writing any summary.
- Long jobs that outlive the session still need the honest label: outcome unknown is an outcome report.

**Red flags that you're about to violate this:**
- "The kickoff command succeeded, so the job will too..."
- "It's been running fine for a while; it'll finish fine..."
- "I'll write the summary now and the job will complete during it..."
- "Checking back means waiting, and the rest of the work is done..."
- "These jobs basically never fail..."
- "I started it earlier — surely it's finished by now..."

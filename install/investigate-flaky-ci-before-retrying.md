### Investigate Flaky CI Before Retrying

NEVER respond to an intermittent CI failure by retrying it — manually, with a `retry:` key, or with a retry-wrapper action — until you have investigated what actually failed. "It passed on re-run" is an observation, not a diagnosis.

Retries convert a visible problem into an invisible tax: slower pipelines, higher CI bills, and real regressions that slip through because failures are presumed flaky.

- When a job fails intermittently, pull the logs from the failing run first. Identify the exact test or step, the error, and the difference from passing runs (timing, ordering, environment).
- Look for the classic causes before declaring flakiness: shared state between tests, time/timezone dependence, network calls to real services, port collisions, unpinned dependency or image versions, and resource exhaustion on the runner.
- If you find the root cause, fix it in the code or test, not in the pipeline.
- If you cannot find the root cause in the time available, say so explicitly and report what you ruled out. Recommend quarantine-with-a-ticket as a human decision; do not silently add retry config.
- Never add a blanket retry to a whole job or workflow. If a retry is ever justified (a documented-unreliable external dependency you cannot remove), scope it to that single operation and comment why.
- One green re-run proves nothing. If you claim something is fixed, the evidence is the cause you found, not the color of the latest run.

**Red flags that you're about to violate this:**

- "It passed when I re-ran it, so the failure was spurious."
- "This test is known to be flaky; everyone just retries it."
- "Adding a retry wrapper is a pragmatic fix while the team is busy."
- "The failure is probably infrastructure, so there's nothing to investigate in the code."
- "Three attempts should be enough to get past this reliably."

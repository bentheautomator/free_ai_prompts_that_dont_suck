### Never Report a Number You Didn't Measure

NEVER state a quantity — latency, throughput, memory, bundle size, row counts, percentage improvements — unless a measurement you ran in this session produced that number, or you are quoting a cited source.

The core problem: numbers signal rigor, so fabricated ones borrow credibility that only measurement earns. "Roughly 60% faster" without a benchmark is fiction with a decimal point.

- Every number you report must trace to an artifact: the benchmark output, the profiler summary, the `du`/`ls -l`/bundle-analyzer line, the `SELECT count(*)` result. Be ready to point at it.
- Improvement claims require two measurements — before and after, same conditions, same inputs. One measurement plus an assumption is not a delta.
- State the conditions with the number: input size, iterations, machine, dataset. "180ms median over 100 runs on the seed dataset" is a measurement; "about 180ms" alone is decor.
- If you didn't measure, describe the change qualitatively and say measurement is pending: "removes an N+1 query; expected to help, not yet measured." Offer the command that would measure it.
- Hedge-words don't license fabrication. "Roughly," "around," "should be about" followed by a specific figure is still reporting a number you didn't measure.
- Mind units and magnitudes when you do report: ms vs s, MiB vs MB, median vs mean. A real measurement misreported is fabrication's quieter cousin.

**Red flags that you're about to violate this:**
- "A number will make this summary more convincing..."
- "Removing a loop like that is typically a 50% improvement..."
- "I'll say 'roughly' so it doesn't need to be exact..."
- "The math suggests it should be about 40KB smaller..."
- "Benchmarking properly would take a while; the estimate is close enough..."
- "Changelogs always include a figure here..."

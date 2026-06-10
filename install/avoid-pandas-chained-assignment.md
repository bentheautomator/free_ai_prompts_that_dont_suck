### Avoid Pandas Chained Assignment

NEVER assign through chained indexing in pandas. `df[mask]['col'] = value` writes into a temporary object and may silently change nothing; under copy-on-write (pandas 3.x default) it is guaranteed to change nothing.

- Wrong: `df[df.a > 0]['b'] = 1`. Right: `df.loc[df.a > 0, 'b'] = 1` — one `.loc` with both row and column selection in a single indexing operation.
- Wrong: `sub = df[mask]` then later `sub['col'] = x` while intending to modify `df`. If you need a working subset, take an explicit copy (`sub = df[mask].copy()`) and decide deliberately whether results get merged back; if you mean to edit `df`, use `df.loc[mask, 'col'] = x` directly.
- Never silence `SettingWithCopyWarning` with `pd.set_option('mode.chained_assignment', None)` or warning filters. The warning marks code whose behavior is version- and layout-dependent; fix the indexing instead.
- The same applies through method chains: `df.query('a > 0')['b'] = 1` and `df.dropna()['b'] = 1` assign into temporaries.
- For conditional column updates prefer explicit whole-column constructions: `df['b'] = df['b'].mask(df.a > 0, 1)` or `np.where(...)` — these produce a new column and cannot half-apply.
- After any in-place cleaning step, verify it took: a quick `assert (df.loc[mask, 'col'] == expected).all()` catches a write that landed on a copy.

**Red flags that you're about to violate this:**

- "df[mask]['col'] = value reads cleanly, pandas will figure it out..."
- "It's just a warning, not an error — I'll suppress it..."
- "This exact pattern worked in the last cell..."
- "I'll filter into a variable first, it's the same DataFrame anyway..."
- "No time to restructure the indexing, the assignment probably propagates..."

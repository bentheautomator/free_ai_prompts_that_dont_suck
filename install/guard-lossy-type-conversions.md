### Guard Lossy Type Conversions

NEVER apply a type conversion without accounting for what it destroys. Casts are not plumbing; float→int truncates, datetime→string discards timezone and precision, and numeric parsing of identifiers mutilates them. If a cast can lose information, either prove it doesn't on this data or don't do it.

- Float→int: decide rounding explicitly (`np.round(s).astype(int)` vs truncation) and handle NaN first — `astype(int)` on NaN either raises or, via numpy paths, produces garbage sentinels. If values can be missing, use nullable `Int64`, don't `fillna(0)` your way past it.
- Identifiers are strings, always: ZIP codes, phone numbers, account IDs, EANs. Pin them at read time (`pd.read_csv(..., dtype={'zip': str, 'account_id': str})`) before pandas infers int (losing leading zeros) or float64 (losing precision above 2^53, colliding distinct IDs).
- Datetimes stay datetimes end to end. Persist as Parquet timestamps or ISO-8601 with offset (`s.dt.strftime` is for display only); keep timezone explicit (`tz_localize`/`tz_convert`), and never round-trip through a bare `str()` and re-parse.
- CSV is itself a lossy cast — everything becomes text and dtype inference happens twice. For intermediates, prefer Parquet/Feather, which preserve dtypes; if CSV is required, specify `dtype=` and `parse_dates=` on every read.
- After any unavoidable conversion, assert round-trip fidelity on the data you have: `assert (converted_back == original).all()` or check `s.max() < 2**53` before a float cast of IDs. One assert, run once, beats a quarter of corrupted joins.
- Watch implicit casts too: merging int64 with float64 keys, `concat` upcasting int columns with NaN to float, JSON serialization turning big ints into doubles.

**Red flags that you're about to violate this:**

- "astype(int) will fix this type error..."
- "I'll stringify the timestamps so the CSV writes..."
- "The ID column reads in fine as a number..."
- "fillna(0) then cast, easy..."
- "It's just an intermediate CSV, dtypes will sort themselves out..."
- "The preview looks right, conversion succeeded..."

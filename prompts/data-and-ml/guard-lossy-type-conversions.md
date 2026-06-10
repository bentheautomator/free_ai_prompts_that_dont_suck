---
title: Guard Lossy Type Conversions
slug: guard-lossy-type-conversions
category: data-and-ml
tags: [universal, data, pandas]
works_with: all
severity: high
one_liner: "Casual casts truncate floats, mangle datetimes, and strip leading zeros silently"
---

# Guard Lossy Type Conversions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents silent data destruction from casual type casts: float-to-int truncation, datetime-to-string round-trips, and IDs degraded by numeric parsing.

**[Copy-paste ready version](../../install/guard-lossy-type-conversions.md)** — just the instruction block, no explanation.

## The Problem

Type conversions look like plumbing, so assistants apply them casually to make the next operation work: `df['qty'].astype(int)` to satisfy a function (silently truncating 2.7 to 2, or blowing up on a NaN by turning it into a garbage sentinel via numpy casting); `df['ts'].astype(str)` to write a file (discarding timezone, freezing a format nothing was promised to parse back); `pd.read_csv` without dtypes (reading ZIP codes as integers, amputating leading zeros; turning 19-digit IDs into float64, where they lose precision past 2^53 and several distinct IDs become the same number). Each cast succeeds. Nothing warns. The information is just gone.

The damage surfaces far from the cause: joins that mysteriously drop rows because `"00501"` became `501` on one side only; duplicate "users" because two long IDs collided in float space; a day-shift in every timestamp after a naive string round-trip crossed a timezone. By then the lossy cast is several files away and nobody connects an off-by-one-day report to an `astype(str)` from last month.

Assistants do it because the cast is the shortest path past a TypeError, the result prints fine in the preview (`501` looks like a ZIP code if you don't know better), and round-trip fidelity is a property no test checks by default.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reclassifies casts from plumbing to data operations.** A conversion framed as "what does this destroy?" gets the same scrutiny as a filter or a join, which is what it deserves — silent truncation is a `drop` with worse PR.

2. **Pinning dtypes at the read boundary beats fixing them downstream.** Leading zeros and big-int precision are destroyed during inference; by the time any code sees the column, repair is impossible. Only `dtype=` at ingestion is early enough.

3. **The 2^53 and round-trip asserts make invisible loss loud on real data.** These failures produce values that look plausible individually; only a fidelity check against the originals reveals the collisions and shifts.

4. **Preferring typed formats for intermediates removes the repeated coin-flip** of CSV dtype inference, so a column's type is decided once instead of re-guessed at every pipeline stage.

## Origin

Two datasets were joined on a 19-digit event ID that one pipeline had passed through float64. Above 2^53, distinct IDs mapped to identical floats; the join fanned out on the collisions and dropped the rows whose IDs had shifted by one unit, simultaneously inflating some segments and starving others. The numbers were wrong in both directions at once, which made the bug look like everything except what it was: a dtype, set by inference, in a file nobody had opened.

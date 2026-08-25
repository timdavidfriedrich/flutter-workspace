# Date, Time & Formatting

*Requires `SKILL.md`.*

- **UTC-first:** `DateTime` in memory is always UTC (`isUtc == true`). `DateTime.now().toUtc()` for "now", `.toUtc()` immediately after every `DateTime.parse` / `tryParse`.
- **`.toLocal()` only in the leaf widget** — never in mappers, repositories, use cases or Blocs.
- **Persisted wall-clock values** (date/time strings without a zone) need a symmetric codec pair as extensions (`toDateString()` / `String.toDateTimeUtc()`). Never send an already converted string through the encoder again.
- **Formatting as an extension, not a helper function.** A function that takes its subject as the first parameter becomes an extension on that type: `dateTime.toDayMonthString()`, `duration.toHoursMinutesString()`, `error.toMessage(context)`.
  - No speculative parameters for cases that do not exist.
  - Placement: the innermost module that actually uses it — one feature → the feature; several → `shared`; `core` only if `core` code calls it itself.
- **Number, date and currency formats** via `intl` and the active locale, never hand-built string interpolation.

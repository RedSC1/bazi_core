# bazi_core

[中文](./README.md)

A pure Dart BaZi and Four Pillars library ported from this project's
`bazi-lite`. It includes Ten Gods, hidden stems, life stages, Na Yin, Shen Sha,
stem/branch relations, Qi Yun, Da Yun, solar clocks, and bounded reverse lookup.
Astronomy and Chinese-calendar calculations use `ephemeris_lite`.

> **Breaking release:** version 1.x is not API-compatible with the old 0.6.x
> implementation. See the [migration guide](./doc/migration.md).

Current stable version: `1.1.0`.

## Installation

```yaml
dependencies:
  bazi_core: ^1.1.0
```

## Create a chart

```dart
import 'package:bazi_core/bazi_core.dart';

final options = BaziOptions(
  gender: Gender.male,
  calendarOptions: CalendarOptions(
    eventAccuracy: Accuracy.mid,
    utcOffsetMinutes: 480,
  ),
);
final chart = BaziChart.fromZonedTime(
  ZonedTime(
    year: 2003, month: 3, day: 13,
    hour: 14, minute: 15, offsetMinutes: 480,
  ),
  options: options,
);

final lunarChart = BaziChart.fromLunarDay(
  const LunarDate(year: 2003, month: 2, day: 11),
  hour: 14,
  minute: 15,
  options: options,
);
```

Calendar-day constructors require a separate `hour`; minutes and seconds default
to zero. `fromLunarDay()` uses the same `CalendarOptions` for conversion and chart
construction.

`birthClockTime` is the original wall clock, `birthJdUT1` is the physical
instant, and `birthChartTime` is the civil, mean-solar, or apparent-solar clock
used by the pillars. `birthCivilTime` remains a deprecated alias.

Chart-bound Qi Yun and Da Yun methods reuse the immutable options saved on the
chart. Low-level functions accept other options for explicit comparisons, but
mixed conventions can disagree near solar-term, day, and historical-calendar
boundaries.

Run `dart analyze`, `dart test`, and
`dart run example/bazi_core_example.dart`. See the [API map](./doc/api-map.md)
and [migration guide](./doc/migration.md).

MPL-2.0. The prior 0.6.x implementation retains its original license in Git
history.

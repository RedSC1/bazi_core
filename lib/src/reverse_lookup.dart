part of '../bazi_core.dart';

enum BaziDatePhase { normal, beforeJie, afterJie }

class BaziDateSearchQuery {
  final int? year, month, day;
  final CalendarDate startDate, endDate;
  final BaziOptions options;
  BaziDateSearchQuery({
    this.year,
    this.month,
    this.day,
    required this.startDate,
    required this.endDate,
    BaziOptions? options,
  }) : options = options ?? BaziOptions();
}

class BaziDateCandidate {
  final CalendarDate date;
  final BaziDatePhase phase;
  final ZonedTime sampleTime;
  final BaziChart chart;
  final String? jieName;
  final ZonedTime? jieTime;
  final BaziOptions options;
  const BaziDateCandidate._(
    this.date,
    this.phase,
    this.sampleTime,
    this.chart,
    this.jieName,
    this.jieTime,
    this.options,
  );
  bool get isJieBoundaryDay => phase != BaziDatePhase.normal;
}

class BaziTimeCandidate {
  /// Inclusive boundaries, resolved to one-second search precision.
  final ZonedTime startTime, endTime, sampleTime;
  final BaziChart chart;
  final int hourIndex;
  final bool isLateZi;
  const BaziTimeCandidate._(
    this.startTime,
    this.endTime,
    this.sampleTime,
    this.chart,
    this.hourIndex,
    this.isLateZi,
  );
  int get hourPillar => chart.pillars.hour;
  String get label => isLateZi ? '晚子时' : '${earthlyBranches[hourIndex]}时';
}

class BaziFullCandidate {
  final BaziDateCandidate dateCandidate;
  final BaziTimeCandidate? timeCandidate;
  const BaziFullCandidate(this.dateCandidate, this.timeCandidate);
  BaziChart get chart => timeCandidate?.chart ?? dateCandidate.chart;
}

class _Window {
  final double start, end;
  const _Window(this.start, this.end);
  _Window? intersect(_Window other) {
    final a = start > other.start ? start : other.start,
        b = end < other.end ? end : other.end;
    return a < b ? _Window(a, b) : null;
  }
}

const _monthJie = [21, 23, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
const _termNames = [
  '冬至',
  '小寒',
  '大寒',
  '立春',
  '雨水',
  '惊蛰',
  '春分',
  '清明',
  '谷雨',
  '立夏',
  '小满',
  '芒种',
  '夏至',
  '小暑',
  '大暑',
  '立秋',
  '处暑',
  '白露',
  '秋分',
  '寒露',
  '霜降',
  '立冬',
  '小雪',
  '大雪',
];
ZonedTime _zoned(double jd, BaziOptions o) =>
    JulianTime.fromUT1(jd).toZonedTime(o.utcOffsetMinutes);
CalendarDate _date(CalendarDate c) =>
    CalendarDate(year: c.year, month: c.month, day: c.day);
double _noon(CalendarDate c) =>
    julianDay(year: c.year, month: c.month, day: c.day, hour: 12);
CalendarDate _addDate(CalendarDate c, int days) =>
    _date(calendarDateFromJulianDay(_noon(c) + days));
double _dateStart(CalendarDate c, BaziOptions o) =>
    _noon(c) - 0.5 - o.utcOffsetMinutes / 1440;
bool _sameDate(CalendarDate a, CalendarDate b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
bool _matches(int value, int? target) => target == null || value == target;
bool _matchesDate(BaziChart c, BaziDateSearchQuery q) =>
    _matches(c.pillars.year, q.year) &&
    _matches(c.pillars.month, q.month) &&
    _matches(c.pillars.day, q.day);
double _termBoundary(CalendarSolarTerm t, BaziOptions o) =>
    getPillarTermBoundary(
      t,
      options: o.calendarOptions,
      pillarHistoricalMode: o.pillarHistoricalMode,
    );
double _specificBoundary(int year, int index, BaziOptions o) => _termBoundary(
  getSpecificSolarTerm(year, index, options: o.calendarOptions),
  o,
);
double _monthBoundary(int year, int index, BaziOptions o) => _specificBoundary(
  index >= 11 ? year + 1 : year,
  _monthJie[index == 12 ? 0 : index],
  o,
);
List<_Window> _searchWindows(BaziDateSearchQuery q) {
  final o = q.options,
      search = _Window(
        _dateStart(q.startDate, o),
        _dateStart(_addDate(q.endDate, 1), o),
      );
  if (q.year == null && q.month == null) return [search];
  final windows = <_Window>[];
  for (var y = q.startDate.year - 1; y <= q.endDate.year + 1; y++) {
    final year = calculateFlowYear(y);
    if (!_matches(year, q.year)) continue;
    final yw = _Window(
      _specificBoundary(y, 21, o),
      _specificBoundary(y + 1, 21, o),
    ).intersect(search);
    if (yw == null) continue;
    if (q.month == null) {
      windows.add(yw);
      continue;
    }
    final mi = (ganzhiBranch(q.month!) - 2) % 12;
    if (getMonthGanzhi(ganzhiStem(year), mi) != q.month) continue;
    final mw = _Window(
      _monthBoundary(y, mi, o),
      _monthBoundary(y, mi + 1, o),
    ).intersect(yw);
    if (mw != null) windows.add(mw);
  }
  return windows;
}

(CalendarSolarTerm, double)? _jieOnDate(CalendarDate date, BaziOptions o) {
  final start = _dateStart(date, o), end = _dateStart(_addDate(date, 1), o);
  var t = getNextJie(start - 3, options: o.calendarOptions);
  for (var i = 0; i < 2; i++) {
    final jd = _termBoundary(t, o);
    if (_sameDate(_zoned(jd, o), date)) return (t, jd);
    if (jd >= end) break;
    t = getNextJie(t.time.jdUT1 + 2 / 86400, options: o.calendarOptions);
  }
  return null;
}

List<BaziDateCandidate> searchBaziDates(BaziDateSearchQuery q) {
  _validCivil(_date(q.startDate));
  _validCivil(_date(q.endDate));
  if (_noon(q.startDate) > _noon(q.endDate)) {
    throw RangeError('startDate must precede endDate');
  }
  for (final p in [q.year, q.month, q.day]) {
    if (p != null) ganzhiIndex(p);
  }
  if (q.year != null &&
      q.month != null &&
      getMonthGanzhi(ganzhiStem(q.year!), (ganzhiBranch(q.month!) - 2) % 12) !=
          q.month) {
    throw ArgumentError('month pillar does not match year pillar by Wu-Hu-Dun');
  }
  final o = q.options, results = <BaziDateCandidate>[], seen = <String>{};
  for (final w in _searchWindows(q)) {
    final first = _date(_zoned(w.start, o)),
        last = _date(_zoned(w.end - 1 / 86400, o));
    final offset = q.day == null
        ? 0
        : (ganzhiIndex(q.day!) - ganzhiIndex(calculateDayPillar(first))) % 60;
    for (
      var d = _addDate(first, offset);
      _noon(d) <= _noon(last);
      d = _addDate(d, q.day == null ? 1 : 60)
    ) {
      final jie = _jieOnDate(d, o);
      final noon = _dateStart(d, o) + 0.5,
          normal = noon < w.start
              ? w.start
              : noon > w.end - 1 / 86400
              ? w.end - 1 / 86400
              : noon;
      final samples = jie == null
          ? [(normal, BaziDatePhase.normal)]
          : [
              (jie.$2 - 1 / 86400, BaziDatePhase.beforeJie),
              (jie.$2 + 1 / 86400, BaziDatePhase.afterJie),
            ];
      for (final (jd, phase) in samples) {
        if (jd < w.start || jd >= w.end) continue;
        final time = _zoned(jd, o),
            c = BaziChart.fromZonedTime(time, options: o);
        if (!_matchesDate(c, q)) continue;
        final key = '${phase.index}@$jd';
        if (!seen.add(key)) continue;
        results.add(
          BaziDateCandidate._(
            d,
            phase,
            time,
            c,
            jie == null ? null : _termNames[jie.$1.indexFromWinterSolstice],
            jie == null ? null : _zoned(jie.$2, o),
            o,
          ),
        );
      }
    }
  }
  results.sort(
    (a, b) => a.sampleTime.toJulianTime().jdUT1.compareTo(
      b.sampleTime.toJulianTime().jdUT1,
    ),
  );
  return List.unmodifiable(results);
}

class _TimeState {
  final BaziChart chart;
  final int hour;
  final bool late;
  const _TimeState(this.chart, this.hour, this.late);
}

_TimeState? _timeState(BaziDateCandidate c, double jd) {
  final chart = BaziChart.fromZonedTime(
        _zoned(jd, c.options),
        options: c.options,
      ),
      p = chart.pillars,
      target = c.chart.pillars;
  if (p.year != target.year || p.month != target.month || p.day != target.day) {
    return null;
  }
  final hour = ganzhiBranch(p.hour),
      late =
          c.options.ratHourMode != RatHourMode.nextDay &&
          hour == 0 &&
          chart.birthChartTime.hour >= 23;
  return _TimeState(chart, hour, late);
}

bool _sameState(_TimeState? a, _TimeState? b) => a == null || b == null
    ? a == b
    : a.hour == b.hour &&
          a.late == b.late &&
          a.chart.pillars.hour == b.chart.pillars.hour;
List<BaziTimeCandidate> searchBaziTimesForDate(
  BaziDateCandidate candidate, {
  int? hour,
}) {
  if (hour != null) ganzhiIndex(hour);
  final o = candidate.options;
  var start = _dateStart(candidate.date, o),
      end = _dateStart(_addDate(candidate.date, 1), o);
  if (candidate.phase == BaziDatePhase.beforeJie && candidate.jieTime != null) {
    end = candidate.jieTime!.toJulianTime().jdUT1;
  }
  if (candidate.phase == BaziDatePhase.afterJie && candidate.jieTime != null) {
    start = candidate.jieTime!.toJulianTime().jdUT1;
  }
  if (start >= end) return const [];
  final last = end - 1 / 86400;
  if (last < start) return const [];
  final points = [start];
  for (var t = start + 600 / 86400; t < end; t += 600 / 86400) {
    points.add(t);
  }
  if (points.last != last) points.add(last);
  final results = <BaziTimeCandidate>[];
  void add(_TimeState state, double from, double to) {
    if (to < from) return;
    final sample = from + (((to - from) * 86400).round() ~/ 2) / 86400;
    final c = BaziChart.fromZonedTime(_zoned(sample, o), options: o);
    if (_matches(c.pillars.hour, hour)) {
      results.add(
        BaziTimeCandidate._(
          _zoned(from, o),
          _zoned(to, o),
          _zoned(sample, o),
          c,
          state.hour,
          state.late,
        ),
      );
    }
  }

  var previousPoint = points.first,
      previous = _timeState(candidate, points.first);
  double? segment = previous == null ? null : points.first;
  for (final point in points.skip(1)) {
    final state = _timeState(candidate, point);
    if (!_sameState(previous, state)) {
      var left = 0, right = ((point - previousPoint) * 86400).round();
      while (left < right) {
        final mid = (left + right) ~/ 2;
        if (_sameState(
          _timeState(candidate, previousPoint + mid / 86400),
          previous,
        )) {
          left = mid + 1;
        } else {
          right = mid;
        }
      }
      final change = previousPoint + left / 86400;
      if (previous != null && segment != null) {
        add(previous, segment, change - 1 / 86400);
      }
      segment = state == null ? null : change;
    }
    previousPoint = point;
    previous = state;
  }
  if (previous != null && segment != null) add(previous, segment, last);
  results.sort(
    (a, b) => a.startTime.toJulianTime().jdUT1.compareTo(
      b.startTime.toJulianTime().jdUT1,
    ),
  );
  return List.unmodifiable(results);
}

List<BaziFullCandidate> reverseLookupBazi({
  required int year,
  required int month,
  required int day,
  int? hour,
  required CalendarDate startDate,
  required CalendarDate endDate,
  BaziOptions? options,
}) {
  if (hour != null) ganzhiIndex(hour);
  final dates = searchBaziDates(
    BaziDateSearchQuery(
      year: year,
      month: month,
      day: day,
      startDate: startDate,
      endDate: endDate,
      options: options,
    ),
  );
  final results = <BaziFullCandidate>[];
  for (final d in dates) {
    if (hour == null) {
      results.add(BaziFullCandidate(d, null));
    } else {
      for (final t in searchBaziTimesForDate(d, hour: hour)) {
        results.add(BaziFullCandidate(d, t));
      }
    }
  }
  results.sort(
    (a, b) => (a.timeCandidate?.startTime ?? a.dateCandidate.sampleTime)
        .toJulianTime()
        .jdUT1
        .compareTo(
          (b.timeCandidate?.startTime ?? b.dateCandidate.sampleTime)
              .toJulianTime()
              .jdUT1,
        ),
  );
  return List.unmodifiable(results);
}

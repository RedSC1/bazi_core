part of '../bazi_core.dart';

int calculateFlowYear(int year) {
  final i = (year - 4) % 60;
  return makeGanzhi(i % 10, i % 12);
}

int calculateFlowMonth(int yearPillar, int monthBranch) {
  _branch(monthBranch);
  return getMonthGanzhi(ganzhiStem(yearPillar), (monthBranch + 10) % 12);
}

int calculateFlowDay(CalendarDate date) => calculateDayPillar(date);
int calculateFlowHour(int dayPillar, int hourIndex) =>
    getHourGanzhi(ganzhiStem(dayPillar), hourIndex);
int calculateLuckDirection(int yearPillar, Gender gender) =>
    ((ganzhiStem(yearPillar) & 1) == 0) == (gender == Gender.male) ? 1 : -1;
void _direction(int d) {
  if (d != 1 && d != -1) throw RangeError('direction must be -1 or 1');
}

void _count(int count) {
  if (count < 0) throw RangeError('count must be non-negative');
}

int calculateXiaoYun(BaziPillarAnalysis chart, int direction, int age) {
  _direction(direction);
  if (age < 1) throw RangeError('age must be positive');
  return advanceGanzhi(chart.pillars.hour, direction * age);
}

class XiaoYunEntry {
  final int age, pillar;
  const XiaoYunEntry(this.age, this.pillar);
  Map<String, int> toJson() => {'age': age, 'pillar': pillar};
}

List<XiaoYunEntry> generateXiaoYun(
  BaziPillarAnalysis chart,
  int direction,
  int count, {
  int startAge = 1,
}) {
  _direction(direction);
  _count(count);
  if (startAge < 1) throw RangeError('startAge must be positive');
  return List.unmodifiable([
    for (var i = 0; i < count; i++)
      XiaoYunEntry(
        startAge + i,
        calculateXiaoYun(chart, direction, startAge + i),
      ),
  ]);
}

class DaYunPillar {
  final int index, pillar, startVirtualAge, endVirtualAge;
  const DaYunPillar(
    this.index,
    this.pillar,
    this.startVirtualAge,
    this.endVirtualAge,
  );
  Map<String, Object> toJson() => {
    'index': index,
    'pillar': pillar,
    'startVirtualAge': startVirtualAge,
    'endVirtualAge': endVirtualAge,
  };
}

List<DaYunPillar> generateDaYunPillars(
  BaziPillarAnalysis chart,
  int direction, {
  int count = 8,
  int firstStartVirtualAge = 1,
}) {
  _direction(direction);
  _count(count);
  return List.unmodifiable([
    for (var i = 0; i < count; i++)
      DaYunPillar(
        i + 1,
        advanceGanzhi(chart.pillars.month, direction * (i + 1)),
        firstStartVirtualAge + i * 10,
        firstStartVirtualAge + i * 10 + 9,
      ),
  ]);
}

double _civilJd(CalendarDate c) => julianDay(
  year: c.year,
  month: c.month,
  day: c.day,
  hour: c.hour,
  minute: c.minute,
  second: c.second,
);
void _validCivil(CalendarDate c) {
  ZonedTime(
    year: c.year,
    month: c.month,
    day: c.day,
    hour: c.hour,
    minute: c.minute,
    second: c.second,
    offsetMinutes: 0,
  );
}

(CalendarDate, double) _addComponents(
  CalendarDate origin,
  int years,
  int months,
  double remainingDays,
) {
  final mi = origin.month - 1 + months,
      y = origin.year + years + (mi / 12).floor(),
      m = mi % 12 + 1;
  final base = julianDay(
    year: y,
    month: m,
    day: 1,
    hour: origin.hour,
    minute: origin.minute,
    second: origin.second,
  );
  final result = base + origin.day - 1 + remainingDays;
  return (calendarDateFromJulianDay(result), result - _civilJd(origin));
}

class TraditionalLuckOffset {
  final int years, months, days, hours, minutes;
  final double seconds;
  const TraditionalLuckOffset(
    this.years,
    this.months,
    this.days,
    this.hours,
    this.minutes,
    this.seconds,
  );
  Map<String, num> toJson() => {
    'years': years,
    'months': months,
    'days': days,
    'hours': hours,
    'minutes': minutes,
    'seconds': seconds,
  };
}

class QiYunResult {
  final int direction;
  final QiYunTimeModel timeModel;
  final CalendarSolarTerm referenceJie;
  final double jieIntervalDays, startAgeYears, startJdUT1;
  final TraditionalLuckOffset traditionalOffset;
  final CalendarDate startCivilTime;
  const QiYunResult({
    required this.direction,
    required this.timeModel,
    required this.referenceJie,
    required this.jieIntervalDays,
    required this.startAgeYears,
    required this.startJdUT1,
    required this.traditionalOffset,
    required this.startCivilTime,
  });
  Map<String, Object> toJson() => {
    'direction': direction,
    'timeModel': timeModel.index,
    'referenceJie': {
      'indexFromWinterSolstice': referenceJie.indexFromWinterSolstice,
      'targetLongitude': referenceJie.targetLongitude,
      'civilDayNumber': referenceJie.civilDayNumber,
      'time': {
        'jdUT1': referenceJie.time.jdUT1,
        'jdTT': referenceJie.time.jdTT,
      },
    },
    'jieIntervalDays': jieIntervalDays,
    'startAgeYears': startAgeYears,
    'startJdUT1': startJdUT1,
    'traditionalOffset': traditionalOffset.toJson(),
    'startCivilTime': startCivilTime.toJson(),
  };
}

/// Astronomical Jie interval; civil/solar clock is supplied independently.
QiYunResult calculateQiYun(
  Object instant,
  CalendarDate birthChartTime,
  BaziPillarAnalysis chart,
  Gender gender, {
  CalendarOptions? calendarOptions,
  QiYunTimeModel timeModel = QiYunTimeModel.traditionalCalendar,
}) {
  final jd = asUt1JulianDay(instant);
  _validCivil(birthChartTime);
  final direction = calculateLuckDirection(chart.pillars.year, gender);
  var term = getPreviousJie(jd, options: calendarOptions);
  var interval = jd - term.time.jdUT1;
  if (interval.abs() <= 1e-10) {
    interval = 0;
  } else if (direction > 0) {
    term = getNextJie(jd, options: calendarOptions);
    interval = term.time.jdUT1 - jd;
  }
  if (!interval.isFinite || interval < -1e-10) {
    throw StateError('Invalid Qi-Yun interval');
  }
  interval = interval < 0 ? 0 : interval;
  final scaled = interval * 120,
      y = (scaled / 360).floor(),
      afterYears = scaled - y * 360,
      m = (afterYears / 30).floor(),
      afterMonths = afterYears - m * 30,
      d = afterMonths.floor();
  var seconds = (afterMonths - d) * 86400;
  final hours = (seconds / 3600).floor();
  seconds -= hours * 3600;
  final minutes = (seconds / 60).floor();
  seconds -= minutes * 60;
  final offset = TraditionalLuckOffset(y, m, d, hours, minutes, seconds);
  final (civil, elapsed) = timeModel == QiYunTimeModel.traditionalCalendar
      ? _addComponents(birthChartTime, y, m, afterMonths)
      : _addElapsed(
          birthChartTime,
          interval *
              (timeModel == QiYunTimeModel.julianYear ? 365.25 : 365.2422) /
              3,
        );
  return QiYunResult(
    direction: direction,
    timeModel: timeModel,
    referenceJie: term,
    jieIntervalDays: interval,
    startAgeYears: interval / 3,
    startJdUT1: jd + elapsed,
    traditionalOffset: offset,
    startCivilTime: civil,
  );
}

(CalendarDate, double) _addElapsed(CalendarDate origin, double days) =>
    (calendarDateFromJulianDay(_civilJd(origin) + days), days);

class DaYunEntry extends DaYunPillar {
  final double startJdUT1, endJdUT1;
  final CalendarDate startCivilTime, endCivilTime;
  const DaYunEntry(
    super.index,
    super.pillar,
    super.startVirtualAge,
    super.endVirtualAge,
    this.startJdUT1,
    this.endJdUT1,
    this.startCivilTime,
    this.endCivilTime,
  );
  @override
  Map<String, Object> toJson() => {
    ...super.toJson(),
    'startJdUT1': startJdUT1,
    'endJdUT1': endJdUT1,
    'startCivilTime': startCivilTime.toJson(),
    'endCivilTime': endCivilTime.toJson(),
  };
}

List<DaYunEntry> generateDaYun(
  CalendarDate birth,
  BaziPillarAnalysis chart,
  QiYunResult qi, {
  int count = 8,
  DaYunBoundaryModel boundaryModel = DaYunBoundaryModel.civilYears,
}) {
  _validCivil(birth);
  _count(count);
  _direction(qi.direction);
  (CalendarDate, double) at(int years) =>
      boundaryModel == DaYunBoundaryModel.civilYears
      ? _addComponents(qi.startCivilTime, years, 0, 0)
      : _addElapsed(
          qi.startCivilTime,
          years *
              (boundaryModel == DaYunBoundaryModel.julianYears
                  ? 365.25
                  : 365.2422),
        );
  return List.unmodifiable([
    for (var i = 0; i < count; i++)
      (() {
        final (s, sd) = at(i * 10);
        final (e, ed) = at((i + 1) * 10);
        final age = s.year - birth.year + 1;
        return DaYunEntry(
          i + 1,
          advanceGanzhi(chart.pillars.month, qi.direction * (i + 1)),
          age,
          age + 9,
          qi.startJdUT1 + sd,
          qi.startJdUT1 + ed,
          s,
          e,
        );
      })(),
  ]);
}

class RenyuanSilingSegment {
  final int index, stem, startDay, endDay;
  final RenyuanSilingOrigin origin;
  const RenyuanSilingSegment(
    this.index,
    this.stem,
    this.origin,
    this.startDay,
    this.endDay,
  );
  Map<String, int> toJson() => {
    'index': index,
    'stem': stem,
    'origin': origin.index,
    'startDay': startDay,
    'endDay': endDay,
  };
}

List<RenyuanSilingSegment> getRenyuanSilingSegments(
  int monthBranch, [
  RenyuanSilingTable table = RenyuanSilingTable.sanMingTongHui,
]) {
  _branch(monthBranch);
  var start = 0;
  final results = <RenyuanSilingSegment>[];
  final stems = _silingStem[table.index][monthBranch],
      durations = _silingDuration[table.index][monthBranch];
  for (var i = 0; i < stems.length; i++) {
    final end = start + durations[i];
    final origin = table == RenyuanSilingTable.sanMingTongHui && i == 0
        ? (monthBranch == 2
              ? RenyuanSilingOrigin.genEarth
              : monthBranch == 8
              ? RenyuanSilingOrigin.kunEarth
              : RenyuanSilingOrigin.stem)
        : RenyuanSilingOrigin.stem;
    results.add(RenyuanSilingSegment(i, stems[i], origin, start, end));
    start = end;
  }
  return List.unmodifiable(results);
}

RenyuanSilingSegment selectRenyuanSiling(
  int monthBranch,
  double daysSinceJie, [
  RenyuanSilingTable table = RenyuanSilingTable.sanMingTongHui,
]) {
  if (!daysSinceJie.isFinite || daysSinceJie < 0) {
    throw RangeError('daysSinceJie must be finite and non-negative');
  }
  final segments = getRenyuanSilingSegments(monthBranch, table);
  return segments.firstWhere(
    (s) => daysSinceJie < s.endDay,
    orElse: () => segments.last,
  );
}

const _silingStem = [
  [
    [8, 9],
    [9, 6, 5],
    [4, 2, 0],
    [0, 1],
    [1, 8, 4],
    [4, 6, 2],
    [2, 3],
    [3, 0, 5],
    [4, 8, 6],
    [6, 7],
    [7, 2, 4],
    [4, 0, 8],
  ],
  [
    [8, 9],
    [9, 7, 5],
    [4, 2, 0],
    [0, 1],
    [1, 9, 4],
    [4, 6, 2],
    [2, 5, 3],
    [3, 1, 5],
    [4, 8, 6],
    [6, 7],
    [7, 3, 4],
    [4, 0, 8],
  ],
];

const _silingDuration = [
  [
    [7, 23],
    [7, 5, 18],
    [5, 5, 20],
    [7, 23],
    [7, 5, 18],
    [7, 5, 18],
    [7, 23],
    [7, 5, 18],
    [5, 5, 20],
    [7, 23],
    [7, 5, 18],
    [5, 5, 20],
  ],
  [
    [10, 20],
    [9, 3, 18],
    [7, 7, 16],
    [10, 20],
    [9, 3, 18],
    [5, 9, 16],
    [10, 9, 11],
    [9, 3, 18],
    [10, 3, 17],
    [10, 20],
    [9, 3, 18],
    [7, 5, 18],
  ],
];

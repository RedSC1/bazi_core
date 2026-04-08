import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

import '../models/bazi_chart.dart';
import '../models/enums.dart';
import '../models/si_ling.dart';

enum BaziDatePhase {
  normal,
  beforeJie,
  afterJie,
}

class BaziDateSearchQuery {
  final GanZhi? year;
  final GanZhi? month;
  final GanZhi? day;
  final AstroDateTime startDate;
  final AstroDateTime endDate;
  final Location location;
  final double timeZone;
  final RatHourMode ratHourMode;
  final bool useTrueSolarTime;
  final Gender gender;
  final SiLingVersion siLingVersion;

  const BaziDateSearchQuery({
    this.year,
    this.month,
    this.day,
    required this.startDate,
    required this.endDate,
    this.location = defaultLoc,
    this.timeZone = 8,
    this.ratHourMode = RatHourMode.noSplit,
    this.useTrueSolarTime = true,
    this.gender = Gender.male,
    this.siLingVersion = SiLingVersion.sanMingTongHui,
  });
}

class BaziDateCandidate {
  final AstroDateTime date;
  final BaziDatePhase phase;
  final AstroDateTime sampleTime;
  final BaziChart chart;
  final String? jieName;
  final AstroDateTime? jieTime;
  final Location location;
  final double timeZone;
  final RatHourMode ratHourMode;
  final bool useTrueSolarTime;
  final Gender gender;
  final SiLingVersion siLingVersion;

  const BaziDateCandidate({
    required this.date,
    required this.phase,
    required this.sampleTime,
    required this.chart,
    this.jieName,
    this.jieTime,
    required this.location,
    required this.timeZone,
    required this.ratHourMode,
    required this.useTrueSolarTime,
    required this.gender,
    required this.siLingVersion,
  });

  bool get isJieBoundaryDay => phase != BaziDatePhase.normal;
}

class BaziTimeSearchQuery {
  final BaziDateCandidate dateCandidate;
  final GanZhi? time;

  const BaziTimeSearchQuery({
    required this.dateCandidate,
    this.time,
  });
}

class BaziTimeCandidate {
  final AstroDateTime startTime;
  final AstroDateTime endTime;
  final AstroDateTime sampleTime;
  final BaziChart chart;
  final int hourIndex;
  final bool isLateZi;

  const BaziTimeCandidate({
    required this.startTime,
    required this.endTime,
    required this.sampleTime,
    required this.chart,
    required this.hourIndex,
    required this.isLateZi,
  });

  GanZhi get timePillar => chart.bazi.time;

  String get label => isLateZi ? '晚子时' : '${DiZhi.values[hourIndex].label}时';
}

class BaziFullSearchQuery {
  final GanZhi year;
  final GanZhi month;
  final GanZhi day;
  final GanZhi? time;
  final AstroDateTime startDate;
  final AstroDateTime endDate;
  final Location location;
  final double timeZone;
  final RatHourMode ratHourMode;
  final bool useTrueSolarTime;
  final Gender gender;
  final SiLingVersion siLingVersion;

  const BaziFullSearchQuery({
    required this.year,
    required this.month,
    required this.day,
    this.time,
    required this.startDate,
    required this.endDate,
    this.location = defaultLoc,
    this.timeZone = 8,
    this.ratHourMode = RatHourMode.noSplit,
    this.useTrueSolarTime = true,
    this.gender = Gender.male,
    this.siLingVersion = SiLingVersion.sanMingTongHui,
  });
}

class BaziFullCandidate {
  final BaziDateCandidate dateCandidate;
  final BaziTimeCandidate? timeCandidate;

  const BaziFullCandidate({
    required this.dateCandidate,
    this.timeCandidate,
  });

  BaziChart get chart => timeCandidate?.chart ?? dateCandidate.chart;
}

class BaziReverseLookup {
  static const List<int> _monthStartJieIndices = <int>[
    21,
    23,
    1,
    3,
    5,
    7,
    9,
    11,
    13,
    15,
    17,
    19,
  ];

  static List<BaziDateCandidate> searchDates(BaziDateSearchQuery query) {
    _validateQuery(query);

    final searchStart = _dateOnly(query.startDate);
    final searchEndExclusive = _dateOnly(query.endDate).add(const Duration(days: 1));
    final windows = _buildSearchWindows(
      query: query,
      searchStart: searchStart,
      searchEndExclusive: searchEndExclusive,
    );

    final results = <BaziDateCandidate>[];
    final seen = <String>{};

    for (final window in windows) {
      final candidates = query.day == null
          ? _buildWindowCandidates(window: window, query: query)
          : _buildWindowCandidatesByDayPillar(
              window: window,
              query: query,
              targetDay: query.day!,
            );

      for (final candidate in candidates) {
        if (!_matches(candidate.chart, query)) {
          continue;
        }

        final key = _candidateKey(candidate);
        if (seen.add(key)) {
          results.add(candidate);
        }
      }
    }

    results.sort((a, b) => a.sampleTime.toJ2000().compareTo(b.sampleTime.toJ2000()));
    return results;
  }

  static List<BaziFullCandidate> searchFullBazi(BaziFullSearchQuery query) {
    final dateCandidates = searchDates(
      BaziDateSearchQuery(
        year: query.year,
        month: query.month,
        day: query.day,
        startDate: query.startDate,
        endDate: query.endDate,
        location: query.location,
        timeZone: query.timeZone,
        ratHourMode: query.ratHourMode,
        useTrueSolarTime: query.useTrueSolarTime,
        gender: query.gender,
        siLingVersion: query.siLingVersion,
      ),
    );

    final results = <BaziFullCandidate>[];
    for (final dateCandidate in dateCandidates) {
      if (query.time == null) {
        results.add(BaziFullCandidate(dateCandidate: dateCandidate));
        continue;
      }

      final timeCandidates = searchTimesForDate(
        BaziTimeSearchQuery(
          dateCandidate: dateCandidate,
          time: query.time,
        ),
      );

      for (final timeCandidate in timeCandidates) {
        results.add(
          BaziFullCandidate(
            dateCandidate: dateCandidate,
            timeCandidate: timeCandidate,
          ),
        );
      }
    }

    results.sort((a, b) {
      final aTime = a.timeCandidate?.startTime ?? a.dateCandidate.sampleTime;
      final bTime = b.timeCandidate?.startTime ?? b.dateCandidate.sampleTime;
      return aTime.toJ2000().compareTo(bTime.toJ2000());
    });
    return results;
  }

  static List<BaziTimeCandidate> searchTimesForDate(BaziTimeSearchQuery query) {
    final dateCandidate = query.dateCandidate;
    final window = _buildTimeWindow(dateCandidate);
    if (window == null) {
      return const <BaziTimeCandidate>[];
    }

    final segmentResults = <BaziTimeCandidate>[];
    final probeStep = const Duration(minutes: 10);
    final points = <AstroDateTime>[window.start];
    var cursor = window.start.add(probeStep);

    while (cursor.toJ2000() < window.endExclusive.toJ2000()) {
      points.add(cursor);
      cursor = cursor.add(probeStep);
    }

    final lastSample = window.endExclusive.add(const Duration(seconds: -1));
    if (points.last.toJ2000() != lastSample.toJ2000()) {
      points.add(lastSample);
    }

    var previousPoint = points.first;
    var previousState = _evaluateTimeState(dateCandidate, previousPoint);
    AstroDateTime? currentSegmentStart = previousState != null ? previousPoint : null;

    for (int i = 1; i < points.length; i++) {
      final point = points[i];
      final currentState = _evaluateTimeState(dateCandidate, point);

      if (!_sameTimeState(previousState, currentState)) {
        final changeAt = _findStateChange(
          dateCandidate: dateCandidate,
          from: previousPoint,
          to: point,
          previousState: previousState,
        );

        if (previousState != null && currentSegmentStart != null) {
          segmentResults.add(
            _buildTimeCandidate(
              dateCandidate: dateCandidate,
              state: previousState,
              start: currentSegmentStart,
              endInclusive: changeAt.add(const Duration(seconds: -1)),
            ),
          );
          currentSegmentStart = null;
        }

        if (currentState != null) {
          currentSegmentStart = changeAt;
        }
      }

      previousState = currentState;
      previousPoint = point;
    }

    if (previousState != null && currentSegmentStart != null) {
      segmentResults.add(
        _buildTimeCandidate(
          dateCandidate: dateCandidate,
          state: previousState,
          start: currentSegmentStart,
          endInclusive: window.endExclusive.add(const Duration(seconds: -1)),
        ),
      );
    }

    final filtered = query.time == null
        ? segmentResults
        : segmentResults
            .where((item) => _sameGanZhi(item.timePillar, query.time!))
            .toList();

    filtered.sort((a, b) => a.startTime.toJ2000().compareTo(b.startTime.toJ2000()));
    return filtered;
  }

  static void _validateQuery(BaziDateSearchQuery query) {
    if (query.startDate.toJ2000() > query.endDate.toJ2000()) {
      throw ArgumentError('startDate must be earlier than or equal to endDate');
    }

    if (query.year != null && query.month != null) {
      final monthIndex = _monthIndexFromZhi(query.month!.zhi);
      final expected = monthGanZhi(query.year!.gan, monthIndex);
      if (!_sameGanZhi(expected, query.month!)) {
        throw ArgumentError('month pillar does not match year pillar by WuHuDun');
      }
    }
  }

  static List<_SearchWindow> _buildSearchWindows({
    required BaziDateSearchQuery query,
    required AstroDateTime searchStart,
    required AstroDateTime searchEndExclusive,
  }) {
    final windows = <_SearchWindow>[];
    final startYear = searchStart.year - 1;
    final endYear = searchEndExclusive.year + 1;

    if (query.year == null && query.month == null) {
      windows.add(_SearchWindow(start: searchStart, end: searchEndExclusive));
      return windows;
    }

    for (int yearStart = startYear; yearStart <= endYear; yearStart++) {
      if (query.year != null && !_sameGanZhi(yearGanZhi(yearStart), query.year!)) {
        continue;
      }

      final yearWindow = _intersectWindows(
        _buildYearWindow(yearStart),
        _SearchWindow(start: searchStart, end: searchEndExclusive),
      );
      if (yearWindow == null) {
        continue;
      }

      if (query.month == null) {
        windows.add(yearWindow);
        continue;
      }

      final monthIndex = _monthIndexFromZhi(query.month!.zhi);
      final expectedMonth = monthGanZhi(yearGanZhi(yearStart).gan, monthIndex);
      if (!_sameGanZhi(expectedMonth, query.month!)) {
        continue;
      }

      final monthWindow = _intersectWindows(
        _buildMonthWindow(yearStart, monthIndex),
        yearWindow,
      );
      if (monthWindow != null) {
        windows.add(monthWindow);
      }
    }

    return windows;
  }

  static _SearchWindow _buildYearWindow(int yearStart) {
    return _SearchWindow(
      start: _getJieDateTime(yearStart, 21),
      end: _getJieDateTime(yearStart + 1, 21),
    );
  }

  static _SearchWindow _buildMonthWindow(int yearStart, int monthIndex) {
    final startBoundary = _getMonthBoundary(yearStart, monthIndex);
    final endBoundary = _getMonthBoundary(yearStart, monthIndex + 1);
    return _SearchWindow(start: startBoundary, end: endBoundary);
  }

  static AstroDateTime _getMonthBoundary(int yearStart, int boundaryIndex) {
    final jieIndex = boundaryIndex == 12
        ? _monthStartJieIndices[0]
        : _monthStartJieIndices[boundaryIndex];
    final gregorianYear = boundaryIndex >= 11 ? yearStart + 1 : yearStart;
    return _getJieDateTime(gregorianYear, jieIndex);
  }

  static AstroDateTime _getJieDateTime(int year, int jieIndex) {
    return AstroDateTime.fromJ2000(getSpecificJieQi(year, jieIndex));
  }

  static _SearchWindow? _intersectWindows(
    _SearchWindow a,
    _SearchWindow b,
  ) {
    final start = a.start.toJ2000() >= b.start.toJ2000() ? a.start : b.start;
    final end = a.end.toJ2000() <= b.end.toJ2000() ? a.end : b.end;
    if (start.toJ2000() >= end.toJ2000()) {
      return null;
    }
    return _SearchWindow(start: start, end: end);
  }

  static BaziDateCandidate _buildCandidate({
    required AstroDateTime date,
    required AstroDateTime sampleTime,
    required BaziDatePhase phase,
    required BaziDateSearchQuery query,
    String? jieName,
    AstroDateTime? jieTime,
  }) {
    final chart = BaziChart.createBySolarDate(
      clockTime: sampleTime,
      location: query.location,
      timeZone: query.timeZone,
      ratHourMode: query.ratHourMode,
      useTrueSolarTime: query.useTrueSolarTime,
      gender: query.gender,
      siLingVersion: query.siLingVersion,
    );

    return BaziDateCandidate(
      date: date,
      phase: phase,
      sampleTime: sampleTime,
      chart: chart,
      jieName: jieName,
      jieTime: jieTime,
      location: query.location,
      timeZone: query.timeZone,
      ratHourMode: query.ratHourMode,
      useTrueSolarTime: query.useTrueSolarTime,
      gender: query.gender,
      siLingVersion: query.siLingVersion,
    );
  }

  static bool _matches(BaziChart chart, BaziDateSearchQuery query) {
    final bazi = chart.bazi;
    return _matchesPillar(bazi.year, query.year) &&
        _matchesPillar(bazi.month, query.month) &&
        _matchesPillar(bazi.day, query.day);
  }

  static bool _matchesPillar(GanZhi actual, GanZhi? expected) {
    if (expected == null) {
      return true;
    }
    return _sameGanZhi(actual, expected);
  }

  static bool _sameGanZhi(GanZhi a, GanZhi b) {
    return a.gan == b.gan && a.zhi == b.zhi;
  }

  static int _monthIndexFromZhi(DiZhi zhi) {
    return (zhi.index - 2 + 12) % 12;
  }

  static AstroDateTime _dateOnly(AstroDateTime date) {
    return AstroDateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  static AstroDateTime _sampleNormalDay({
    required AstroDateTime date,
    required AstroDateTime lowerBound,
    required AstroDateTime upperBound,
  }) {
    final noon = AstroDateTime(date.year, date.month, date.day, 12, 0, 0);
    if (noon.toJ2000() < lowerBound.toJ2000()) {
      return lowerBound;
    }
    if (noon.toJ2000() > upperBound.toJ2000()) {
      return upperBound;
    }
    return noon;
  }

  static AstroDateTime _sampleBeforeJie(
    AstroDateTime date,
    AstroDateTime jieTime,
  ) {
    final dayStart = AstroDateTime(date.year, date.month, date.day, 0, 0, 0);
    final sample = jieTime.add(const Duration(seconds: -1));
    if (_isSameDate(sample, date)) {
      return sample;
    }
    return dayStart;
  }

  static AstroDateTime _sampleAfterJie(
    AstroDateTime date,
    AstroDateTime jieTime,
  ) {
    final dayEnd = AstroDateTime(date.year, date.month, date.day, 23, 59, 59);
    final sample = jieTime.add(const Duration(seconds: 1));
    if (_isSameDate(sample, date)) {
      return sample;
    }
    return dayEnd;
  }

  static bool _isSameDate(AstroDateTime a, AstroDateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isInsideWindow(AstroDateTime time, _SearchWindow window) {
    final jd = time.toJ2000();
    return jd >= window.start.toJ2000() && jd < window.end.toJ2000();
  }

  static List<BaziDateCandidate> _buildWindowCandidates({
    required _SearchWindow window,
    required BaziDateSearchQuery query,
  }) {
    final results = <BaziDateCandidate>[];
    final startDay = _dateOnly(window.start);
    final endDay = _dateOnly(window.end.add(const Duration(seconds: -1)));
    var current = startDay;

    while (current.toJ2000() <= endDay.toJ2000()) {
      results.addAll(
        _buildCandidatesForDate(
          date: current,
          window: window,
          query: query,
        ),
      );
      current = current.add(const Duration(days: 1));
    }

    return results;
  }

  static List<BaziDateCandidate> _buildWindowCandidatesByDayPillar({
    required _SearchWindow window,
    required BaziDateSearchQuery query,
    required GanZhi targetDay,
  }) {
    final startDay = _dateOnly(window.start);
    final endDay = _dateOnly(window.end.add(const Duration(seconds: -1)));
    final startIndex = dayGanZhi(startDay).index;
    final offset = (targetDay.index - startIndex + 60) % 60;
    final windowDaySpan = endDay.toJ2000().floor() - startDay.toJ2000().floor();

    if (offset > windowDaySpan) {
      return const <BaziDateCandidate>[];
    }

    final matchDate = startDay.add(Duration(days: offset));
    return _buildCandidatesForDate(
      date: matchDate,
      window: window,
      query: query,
    );
  }

  static List<BaziDateCandidate> _buildCandidatesForDate({
    required AstroDateTime date,
    required _SearchWindow window,
    required BaziDateSearchQuery query,
  }) {
    final jie = _findJieOnDate(date);
    final candidates = jie == null
        ? <BaziDateCandidate>[
            _buildCandidate(
              date: date,
              sampleTime: _sampleNormalDay(
                date: date,
                lowerBound: window.start,
                upperBound: window.end.add(const Duration(seconds: -1)),
              ),
              phase: BaziDatePhase.normal,
              query: query,
            ),
          ]
        : <BaziDateCandidate>[
            _buildCandidate(
              date: date,
              sampleTime: _sampleBeforeJie(date, jie.dateTime),
              phase: BaziDatePhase.beforeJie,
              query: query,
              jieName: jie.name,
              jieTime: jie.dateTime,
            ),
            _buildCandidate(
              date: date,
              sampleTime: _sampleAfterJie(date, jie.dateTime),
              phase: BaziDatePhase.afterJie,
              query: query,
              jieName: jie.name,
              jieTime: jie.dateTime,
            ),
          ];

    return candidates.where((item) => _isInsideWindow(item.sampleTime, window)).toList();
  }

  static String _candidateKey(BaziDateCandidate candidate) {
    return '${candidate.phase.name}@${candidate.sampleTime.toJ2000()}';
  }

  static _TimeWindow? _buildTimeWindow(BaziDateCandidate candidate) {
    var start = AstroDateTime(
      candidate.date.year,
      candidate.date.month,
      candidate.date.day,
      0,
      0,
      0,
    );
    var endExclusive = AstroDateTime(
      candidate.date.year,
      candidate.date.month,
      candidate.date.day,
      23,
      59,
      59,
    ).add(const Duration(seconds: 1));

    if (candidate.phase == BaziDatePhase.beforeJie && candidate.jieTime != null) {
      endExclusive = candidate.jieTime!;
    } else if (candidate.phase == BaziDatePhase.afterJie && candidate.jieTime != null) {
      start = candidate.jieTime!;
    }

    if (start.toJ2000() >= endExclusive.toJ2000()) {
      return null;
    }

    return _TimeWindow(start: start, endExclusive: endExclusive);
  }

  static _TimeState? _evaluateTimeState(
    BaziDateCandidate dateCandidate,
    AstroDateTime clockTime,
  ) {
    final chart = BaziChart.createBySolarDate(
      clockTime: clockTime,
      location: dateCandidate.location,
      timeZone: dateCandidate.timeZone,
      ratHourMode: dateCandidate.ratHourMode,
      useTrueSolarTime: dateCandidate.useTrueSolarTime,
      gender: dateCandidate.gender,
      siLingVersion: dateCandidate.siLingVersion,
    );

    if (!_sameGanZhi(chart.bazi.year, dateCandidate.chart.bazi.year) ||
        !_sameGanZhi(chart.bazi.month, dateCandidate.chart.bazi.month) ||
        !_sameGanZhi(chart.bazi.day, dateCandidate.chart.bazi.day)) {
      return null;
    }

    final hourIndex = chart.bazi.time.zhi.index;
    final isLateZi = dateCandidate.ratHourMode != RatHourMode.noSplit &&
        hourIndex == 0 &&
        clockTime.hour >= 23;

    return _TimeState(
      chart: chart,
      hourIndex: hourIndex,
      isLateZi: isLateZi,
    );
  }

  static bool _sameTimeState(_TimeState? a, _TimeState? b) {
    if (a == null || b == null) {
      return a == b;
    }
    return a.hourIndex == b.hourIndex &&
        a.isLateZi == b.isLateZi &&
        _sameGanZhi(a.chart.bazi.time, b.chart.bazi.time);
  }

  static AstroDateTime _findStateChange({
    required BaziDateCandidate dateCandidate,
    required AstroDateTime from,
    required AstroDateTime to,
    required _TimeState? previousState,
  }) {
    int left = 0;
    int right = _secondsBetween(from, to);

    if (right <= 0) {
      return to;
    }

    while (left < right) {
      final middle = (left + right) ~/ 2;
      final probe = from.add(Duration(seconds: middle));
      final state = _evaluateTimeState(dateCandidate, probe);
      if (_sameTimeState(state, previousState)) {
        left = middle + 1;
      } else {
        right = middle;
      }
    }

    return from.add(Duration(seconds: left));
  }

  static BaziTimeCandidate _buildTimeCandidate({
    required BaziDateCandidate dateCandidate,
    required _TimeState state,
    required AstroDateTime start,
    required AstroDateTime endInclusive,
  }) {
    final midpointOffset = _secondsBetween(start, endInclusive) ~/ 2;
    final sampleTime = start.add(Duration(seconds: midpointOffset));
    final sampleChart = BaziChart.createBySolarDate(
      clockTime: sampleTime,
      location: dateCandidate.location,
      timeZone: dateCandidate.timeZone,
      ratHourMode: dateCandidate.ratHourMode,
      useTrueSolarTime: dateCandidate.useTrueSolarTime,
      gender: dateCandidate.gender,
      siLingVersion: dateCandidate.siLingVersion,
    );

    return BaziTimeCandidate(
      startTime: start,
      endTime: endInclusive,
      sampleTime: sampleTime,
      chart: sampleChart,
      hourIndex: state.hourIndex,
      isLateZi: state.isLateZi,
    );
  }

  static int _secondsBetween(AstroDateTime from, AstroDateTime to) {
    final deltaDays = to.toJ2000() - from.toJ2000();
    return (deltaDays * 86400).round();
  }

  static JieQiResult? _findJieOnDate(AstroDateTime date) {
    final next = getNextJie(date);
    if (next == null) {
      return null;
    }
    if (_isSameDate(next.dateTime, date)) {
      return next;
    }
    return null;
  }
}

class _SearchWindow {
  final AstroDateTime start;
  final AstroDateTime end;

  const _SearchWindow({
    required this.start,
    required this.end,
  });
}

class _TimeWindow {
  final AstroDateTime start;
  final AstroDateTime endExclusive;

  const _TimeWindow({
    required this.start,
    required this.endExclusive,
  });
}

class _TimeState {
  final BaziChart chart;
  final int hourIndex;
  final bool isLateZi;

  const _TimeState({
    required this.chart,
    required this.hourIndex,
    required this.isLateZi,
  });
}

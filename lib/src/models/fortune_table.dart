import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 流时信息
class FlowHour {
  final int hourIndex;
  final GanZhi ganZhi;
  final AstroDateTime startTime;
  final AstroDateTime endTime;

  const FlowHour({
    required this.hourIndex,
    required this.ganZhi,
    required this.startTime,
    required this.endTime,
  });

  String get name => DiZhi.values[hourIndex].label;

  @override
  String toString() => '$ganZhi ($name时)';
}

/// 流日信息
class FlowDay {
  final AstroDateTime date;
  final GanZhi ganZhi;
  final RatHourMode ratHourMode;

  List<FlowHour>? _hours;

  FlowDay({
    required this.date,
    required this.ganZhi,
    this.ratHourMode = RatHourMode.noSplit,
  });

  List<FlowHour> get hours {
    _hours ??= _buildHours();
    return _hours!;
  }

  List<FlowHour> _buildHours() {
    final result = <FlowHour>[];
    final dayGan = ganZhi.gan;
    final hourGanZhiList = getDayHourGanZhi(dayGan);
    final bool isSplitting = ratHourMode != RatHourMode.noSplit;

    for (int i = 0; i < 12; i++) {
      int startHour, endHour;
      if (i == 0) {
        startHour = isSplitting ? 0 : 23;
        endHour = 1;
      } else {
        startHour = i * 2 - 1;
        endHour = startHour + 2;
      }

      result.add(FlowHour(
        hourIndex: i,
        ganZhi: hourGanZhiList[i],
        startTime: AstroDateTime(date.year, date.month, date.day, startHour, 0),
        endTime: AstroDateTime(date.year, date.month, date.day, endHour, 0),
      ));
    }

    if (isSplitting) {
      GanZhi lateZiGanZhi;
      if (ratHourMode == RatHourMode.tomorrowGan) {
        final nextDay = date.add(const Duration(days: 1));
        final nextDayGZ = dayGanZhi(nextDay);
        lateZiGanZhi = getDayHourGanZhi(nextDayGZ.gan)[0];
      } else {
        lateZiGanZhi = hourGanZhiList[0];
      }

      result.add(FlowHour(
        hourIndex: 0,
        ganZhi: lateZiGanZhi,
        startTime: AstroDateTime(date.year, date.month, date.day, 23, 0),
        endTime: AstroDateTime(date.year, date.month, date.day, 23, 59),
      ));
    }

    return result;
  }
}

/// 流月信息
class FlowMonth {
  final GanZhi ganZhi;
  final AstroDateTime startTime;
  final AstroDateTime endTime;
  final RatHourMode ratHourMode;

  List<FlowDay>? _days;

  FlowMonth({
    required this.ganZhi,
    required this.startTime,
    required this.endTime,
    this.ratHourMode = RatHourMode.noSplit,
  });

  List<FlowDay> get days {
    _days ??= _buildDays();
    return _days!;
  }

  List<FlowDay> _buildDays() {
    final result = <FlowDay>[];
    final daysDiff = endTime.difference(startTime).inDays;

    for (int i = 0; i < daysDiff; i++) {
      final currentDate = startTime.add(Duration(days: i));
      final gz = dayGanZhi(currentDate);

      result.add(FlowDay(
        date: AstroDateTime(currentDate.year, currentDate.month, currentDate.day),
        ganZhi: gz,
        ratHourMode: ratHourMode,
      ));
    }
    return result;
  }
}

/// 流年信息
class FlowYear {
  final int year;
  final GanZhi ganZhi;
  final List<FlowMonth> months;

  const FlowYear({
    required this.year,
    required this.ganZhi,
    required this.months,
  });
}

/// 大运信息
class FlowDecade {
  final int index;
  final GanZhi ganZhi;
  final int startAge;
  final int endAge;
  final AstroDateTime startTime;
  final AstroDateTime endTime;
  final List<FlowYear> years;

  const FlowDecade({
    required this.index,
    required this.ganZhi,
    required this.startAge,
    required this.endAge,
    required this.startTime,
    required this.endTime,
    required this.years,
  });
}

/// 岁运流转表
class FortuneTable {
  final List<FlowDecade> decades;

  const FortuneTable._(this.decades);

  factory FortuneTable.build(
    Fortune fortune, {
    int decadeCount = 8,
    RatHourMode ratHourMode = RatHourMode.noSplit,
  }) {
    final result = <FlowDecade>[];

    for (int i = 1; i <= decadeCount; i++) {
      final d = fortune.getDecadeByIndex(i);
      final years = d.flowYears.map((yi) {
        final months = _buildFlowMonths(yi.year, fortune, ratHourMode);
        return FlowYear(
          year: yi.year,
          ganZhi: yi.ganZhi,
          months: months,
        );
      }).toList();

      result.add(FlowDecade(
        index: d.index,
        ganZhi: d.ganZhi,
        startAge: d.startAge,
        endAge: d.endAge,
        startTime: d.startTime,
        endTime: d.endTime,
        years: years,
      ));
    }

    return FortuneTable._(result);
  }

  static List<FlowMonth> _buildFlowMonths(int year, Fortune fortune, RatHourMode mode) {
    final jieBoundaries = _getJieBoundaries(year);
    final monthGanZhi = fortune.getFlowMonths(year);
    final months = <FlowMonth>[];

    for (int i = 0; i < 12 && i < jieBoundaries.length - 1; i++) {
      months.add(FlowMonth(
        ganZhi: monthGanZhi[i],
        startTime: jieBoundaries[i].dateTime,
        endTime: jieBoundaries[i + 1].dateTime,
        ratHourMode: mode,
      ));
    }
    return months;
  }

  static List<JieQiResult> _getJieBoundaries(int year) {
    final liChunJd = getSpecificJieQi(year, 21);
    var current = JieQiResult(index: 2, name: '立春', jd: liChunJd, dateTime: AstroDateTime.fromJ2000(liChunJd));
    final result = <JieQiResult>[current];
    for (int i = 0; i < 12; i++) {
      final next = getNextJie(current.dateTime);
      if (next == null) break;
      result.add(next);
      current = next;
    }
    return result;
  }
}

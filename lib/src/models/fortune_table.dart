import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 流时信息
class FlowHour {
  /// 时辰索引 0-11 对应子、丑、寅...亥
  final int hourIndex;

  /// 时辰干支
  final GanZhi ganZhi;

  /// 时辰起始时间
  final AstroDateTime startTime;

  /// 时辰结束时间
  final AstroDateTime endTime;

  const FlowHour({
    required this.hourIndex,
    required this.ganZhi,
    required this.startTime,
    required this.endTime,
  });

  /// 时辰名称：子、丑、寅...
  String get name => DiZhi.values[hourIndex].label;

  @override
  String toString() => '$ganZhi ($name时)';
}

/// 流日信息
class FlowDay {
  final AstroDateTime date;
  final GanZhi ganZhi;

  /// 是否分早晚子时
  final bool splitByRatHour;

  /// 缓存的流时列表
  List<FlowHour>? _hours;

  FlowDay({
    required this.date,
    required this.ganZhi,
    this.splitByRatHour = false,
  });

  /// 获取当天12个流时（五鼠遁）
  List<FlowHour> get hours {
    _hours ??= _buildHours();
    return _hours!;
  }

  List<FlowHour> _buildHours() {
    final result = <FlowHour>[];
    final dayGan = ganZhi.gan;
    final hourGanZhiList = getDayHourGanZhi(dayGan);

    for (int i = 0; i < 12; i++) {
      int startHour, endHour;

      if (i == 0) {
        startHour = splitByRatHour ? 0 : 23;
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

    // 分早晚子时时，添加晚子（23:00-24:00），用次日日干
    if (splitByRatHour) {
      final nextDay = date.add(const Duration(days: 1));
      final nextDayGanZhi = dayGanZhi(nextDay);
      final nextDayHourList = getDayHourGanZhi(nextDayGanZhi.gan);

      result.add(FlowHour(
        hourIndex: 0,
        ganZhi: nextDayHourList[0],
        startTime: AstroDateTime(date.year, date.month, date.day, 23, 0),
        endTime: AstroDateTime(date.year, date.month, date.day, 23, 59),
      ));
    }

    return result;
  }

  @override
  String toString() => '$date $ganZhi';
}

/// 流月信息（节气月）
class FlowMonth {
  /// 流月干支
  final GanZhi ganZhi;

  /// 本月起始节气时刻（通常是"节"，如立春）
  final AstroDateTime startTime;

  /// 本月结束节气时刻（下一个"节"，不包含）
  final AstroDateTime endTime;

  /// 是否分早晚子时（传递给流日）
  final bool splitByRatHour;

  /// 缓存的流日列表
  List<FlowDay>? _days;

  FlowMonth({
    required this.ganZhi,
    required this.startTime,
    required this.endTime,
    this.splitByRatHour = false,
  });

  /// 获取本月包含的流日列表（懒加载）
  List<FlowDay> get days {
    _days ??= _buildDays();
    return _days!;
  }

  List<FlowDay> _buildDays() {
    final result = <FlowDay>[];
    final start = startTime;
    final end = endTime;

    // 计算天数差
    final daysDiff = end.difference(start).inDays;

    for (int i = 0; i < daysDiff; i++) {
      final currentDate = start.add(Duration(days: i));
      // 用轻量级 dayGanZhi 代替 getDayRange
      final gz = dayGanZhi(currentDate);

      result.add(FlowDay(
        date: AstroDateTime(currentDate.year, currentDate.month, currentDate.day),
        ganZhi: gz,
        splitByRatHour: splitByRatHour,
      ));
    }

    return result;
  }

  @override
  String toString() => '$ganZhi (${startTime.toString().split(' ')[0]} ~ ${endTime.toString().split(' ')[0]})';
}

/// 流年信息
class FlowYear {
  /// 阳历年
  final int year;

  /// 流年干支
  final GanZhi ganZhi;

  /// 本年12个流月（按节气划分，懒加载）
  final List<FlowMonth> months;

  const FlowYear({
    required this.year,
    required this.ganZhi,
    required this.months,
  });

  @override
  String toString() => '$year $ganZhi (${months.length}个月)';
}

/// 大运信息
class FlowDecade {
  /// 第几步大运（1, 2, 3...）
  final int index;

  /// 大运干支
  final GanZhi ganZhi;

  /// 起始虚岁
  final int startAge;

  /// 结束虚岁
  final int endAge;

  /// 大运开始时间（钟表时间）
  final AstroDateTime startTime;

  /// 大运结束时间（钟表时间）
  final AstroDateTime endTime;

  /// 本大运包含的10个流年
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

  @override
  String toString() => '第${index}步大运 $ganZhi (${startAge}~${endAge}岁)';
}

/// 完整的岁运流运表
///
/// 包含大运 → 流年 → 流月 → 流日 → 流时的完整层级结构
/// 其中流月按节气月划分（立春、惊蛰、清明...）
///
/// **性能说明**：流日和流时采用懒加载设计，构建 FortuneTable 时只生成
/// 年月框架，实际访问 days/hours 时才计算具体日期，避免一次性计算
/// 大量数据导致的性能问题。
class FortuneTable {
  /// 所有大运列表
  final List<FlowDecade> decades;

  const FortuneTable._(this.decades);

  /// 从 [Fortune] 对象构建完整的流运表
  ///
  /// [fortune] 由 `Fortune.createByBaziChart()` 创建的岁运对象
  /// [decadeCount] 要生成多少步大运（默认8步 = 80年）
  /// [splitByRatHour] 是否分早晚子时（影响流时的日干计算，默认false）
  factory FortuneTable.build(
    Fortune fortune, {
    int decadeCount = 8,
    bool splitByRatHour = false,
  }) {
    final result = <FlowDecade>[];

    for (int i = 1; i <= decadeCount; i++) {
      final d = fortune.getDecadeByIndex(i);
      final years = d.flowYears.map((yi) {
        final months = _buildFlowMonths(yi.year, fortune, splitByRatHour);
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

  /// 构建指定阳历年的12个流月
  static List<FlowMonth> _buildFlowMonths(
    int year,
    Fortune fortune,
    bool splitByRatHour,
  ) {
    final jieBoundaries = _getJieBoundaries(year);
    final monthGanZhi = fortune.getFlowMonths(year);
    final months = <FlowMonth>[];

    for (int i = 0; i < 12 && i < jieBoundaries.length - 1; i++) {
      final start = jieBoundaries[i].dateTime;
      final nextJie = jieBoundaries[i + 1].dateTime;

      months.add(FlowMonth(
        ganZhi: monthGanZhi[i],
        startTime: start,
        endTime: nextJie,
        splitByRatHour: splitByRatHour,
      ));
    }

    return months;
  }

  /// 获取指定阳历年的13个节气边界（12个月需要13个节）
  static List<JieQiResult> _getJieBoundaries(int year) {
    final liChunJd = getSpecificJieQi(year, 21);

    var current = JieQiResult(
      index: 2,
      name: '立春',
      jd: liChunJd,
      dateTime: AstroDateTime.fromJ2000(liChunJd),
    );

    final result = <JieQiResult>[current];

    for (int i = 0; i < 12; i++) {
      final next = getNextJie(current.dateTime);
      if (next == null) break;
      result.add(next);
      current = next;
    }

    return result;
  }

  /// 根据虚岁快速查找对应的流年
  FlowYear? findYearByAge(int age) {
    for (final d in decades) {
      if (age >= d.startAge && age <= d.endAge) {
        for (final y in d.years) {
          final targetYear = d.startTime.year + (age - d.startAge);
          if (y.year == targetYear) return y;
        }
      }
    }
    return null;
  }

  /// 根据阳历年快速查找对应的流年
  FlowYear? findYearBySolarYear(int year) {
    for (final d in decades) {
      for (final y in d.years) {
        if (y.year == year) return y;
      }
    }
    return null;
  }

  @override
  String toString() => 'FortuneTable(${decades.length}步大运)';
}

import 'package:bazi_core/src/astronomy/time_adapter.dart';
import 'package:bazi_core/src/models/bazi_table.dart';
import 'package:bazi_core/src/models/enums.dart';
import 'package:bazi_core/src/models/interaction_calculator.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

class BaziChart {
  TimePack time;
  BaZi bazi;
  LunarDate lunarDate;
  Gender gender;

  /// 命宫
  late final GanZhi mingGong;

  /// 身宫
  late final GanZhi shenGong;

  /// 胎元
  late final GanZhi taiYuan;

  /// 胎息
  late final GanZhi taiXi;

  BaziChart(this.time, this.bazi, this.lunarDate, this.gender) {
    mingGong = _calculateMingGong();
    shenGong = _calculateShenGong();
    taiYuan = _calculateTaiYuan();
    taiXi = _calculateTaiXi();
  }

  /// 修正后的宫位计算用月份 (过中气算下个月)
  int _getGongMonthIndex() {
    // 1. 获取当前八字月支 (0-based)
    final m = bazi.month.zhi.index;

    // 2. 计算目标中气索引 (Target Qi Index)
    // 映射关系：
    // 子(0) -> 冬至(23)
    // 丑(1) -> 大寒(1)
    // 寅(2) -> 雨水(3)
    // ...
    // 公式: ((m - 1 + 12) % 12) * 2 + 1
    final targetQiIndex = ((m - 1 + 12) % 12) * 2 + 1;

    try {
      // 3. 获取当年节气列表
      // getYearJieQi 返回从上一年冬至到本年冬至的列表 (北京时间)
      final jieQiList = getYearJieQi(time.clockTime.year);

      // 4. 找到对应的中气
      // 可能有多个(比如冬至)，找时间最近的一个
      // 这里的比较基准用 UTC 时间戳，避免时区混乱
      final birthUtcJd = time.utcTime.toJ2000();

      JieQiResult? targetQi;
      double minDiff = double.maxFinite;

      for (final jq in jieQiList) {
        if (jq.index == targetQiIndex) {
          // jq.jd 是北京时间(UTC+8)的 J2000 相对日
          // 转换为 UTC JD: jq.jd - 8/24
          // 但注意: sxwnl 的 getJulianDay() 返回的是 UTC JD
          // jq.dateTime 是 Beijing Time
          // 我们直接用 jq.jd (Beijing Time) 还原为 UTC JD 比较稳妥
          // 或者直接用 dateTime 转换

          // 修正: JieQiResult.jd 是 "J2000 相对儒略日 (北京时间)"
          // AstroDateTime.getJulianDay() 返回的是 "J2000 相对儒略日 (UTC)" (通常)
          // 让我们检查 AstroDateTime.getJulianDay 实现
          // 假设它是标准的 J2000

          // 简单起见，我们将 jq.jd (BJ) 转为 UTC JD
          final qiUtcJd = jq.jd - 8.0 / 24.0;

          final diff = (qiUtcJd - birthUtcJd).abs();
          if (diff < minDiff) {
            minDiff = diff;
            targetQi = jq;
          }
        }
      }

      if (targetQi != null) {
        final qiUtcJd = targetQi.jd - 8.0 / 24.0;

        // 5. 判断是否过中气
        if (birthUtcJd >= qiUtcJd) {
          return (m + 1) % 12; // 过中气，算下个月
        }
      }

      return m;
    } catch (e) {
      // 降级处理
      return m;
    }
  }

  /// 计算命宫
  GanZhi _calculateMingGong() {
    // 算法来源 (问真/神峰通考)：
    // 1. 月份以“过中气”为准 (即月将)
    // 2. 寅上起正月，逆数至生月 (GongMonth)
    // 3. 在该位起子时，顺数至生时 (Hour)
    // 公式：
    // Pos1 = 2(寅) - (GongMonth - 2) = 4 - GongMonth
    // Final = Pos1 + Hour = 4 - GongMonth + Hour

    final m = _getGongMonthIndex();
    final h = bazi.time.zhi.index;

    var branchIdxVal = 4 - m + h;

    // 调整为有效范围 0-11
    branchIdxVal %= 12;
    if (branchIdxVal < 0) branchIdxVal += 12;

    final branch = DiZhi.values[branchIdxVal];
    final stem = _calculateStemForGong(branchIdxVal);

    return GanZhi(stem, branch);
  }

  /// 计算身宫
  GanZhi _calculateShenGong() {
    // 算法来源 (问真)：
    // 1. 月份以“过中气”为准
    // 2. 寅上起正月，顺数至生月
    // 3. 顺数至生时
    // 公式：
    // Pos1 = 2(寅) + (GongMonth - 2) = GongMonth
    // Final = GongMonth + Hour
    // (注意：这里的GongMonth和Hour都是0-based index)

    final m = _getGongMonthIndex();
    final h = bazi.time.zhi.index;

    var branchIdxVal = m + h;

    // 调整为有效范围 0-11
    branchIdxVal %= 12;
    if (branchIdxVal < 0) branchIdxVal += 12;

    final branch = DiZhi.values[branchIdxVal];
    final stem = _calculateStemForGong(branchIdxVal);

    return GanZhi(stem, branch);
  }

  /// 计算胎元
  GanZhi _calculateTaiYuan() {
    // 胎元：月干后一位，月支后三位
    // 在六十甲子序列中，相当于月柱 - 9
    return bazi.month - 9;
  }

  /// 计算胎息
  GanZhi _calculateTaiXi() {
    // 胎息：日柱的天干五合与地支六合
    final stem = BaziTable.getStemCombinationPartner(bazi.day.gan);
    final branch = BaziTable.getBranchCombinationPartner(bazi.day.zhi);
    return GanZhi(stem, branch);
  }

  /// 根据五虎遁推算宫位天干
  TianGan _calculateStemForGong(int branchIndex) {
    // 五虎遁年上起月法（也适用于命宫/身宫）
    // 甲己之年丙作首 -> 甲(0)/己(5) -> 丙(2) (丙寅)
    // 年干 index % 5 * 2 + 2 = 寅月天干
    final yearStemIndex = bazi.year.gan.index;
    final startStemIndex = (yearStemIndex % 5) * 2 + 2;

    // 寅的 index 是 2
    // 偏移量 = 目标地支 - 寅
    final offset = branchIndex - 2;

    var stemIndex = (startStemIndex + offset) % 10;
    if (stemIndex < 0) stemIndex += 10;

    return TianGan.values[stemIndex];
  }

  factory BaziChart.createBySolarDate({
    required AstroDateTime clockTime,
    Location location = defaultLoc,
    double timeZone = 8,
    bool splitByRatHour = false, // 默认不分(即23点换日)，可配置
    bool useTrueSolarTime = true, // 默认使用真太阳时
    Gender gender = Gender.male,
  }) {
    TimePack timepack = TimePack.createBySolarTime(
      clockTime: clockTime,
      location: defaultLoc,
      timezone: timeZone,
      splitByRatHour: splitByRatHour,
      useTrueSolarTime: useTrueSolarTime,
    );
    BaZi bz = TimeAdaptor.fromSolar(timepack, splitRatHour: splitByRatHour);
    LunarDate ld = LunarDate.fromSolar(
      timepack.bjClt,
      splitRatHour: splitByRatHour,
    );
    return BaziChart(timepack, bz, ld, gender);
  }
  factory BaziChart.createByLunarDate({
    required int year,
    required String monthName,
    required int day,
    required int hour,
    required int minute,
    int second = 0,
    bool? isleap,
    Location location = defaultLoc,
    double timeZone = 8,
    bool splitByRatHour = false, // 默认不分(即23点换日)，可配置
    bool useTrueSolarTime = true, // 默认使用真太阳时
    Gender gender = Gender.male,
  }) {
    final lunarDate = LunarDate.fromString(
      year,
      monthName,
      day,
      isLeap: isleap,
    );
    AstroDateTime temp = lunarDate.toSolar;
    final clockTime = AstroDateTime(
      temp.year,
      temp.month,
      temp.day,
      hour,
      minute,
      second,
    );
    final tp = TimePack.createBySolarTime(
      clockTime: clockTime,
      timezone: timeZone,
      location: location,
      splitByRatHour: splitByRatHour,
      useTrueSolarTime: useTrueSolarTime,
    );
    final bz = TimeAdaptor.fromSolar(tp, splitRatHour: splitByRatHour);
    return BaziChart(tp, bz, lunarDate, gender);
  }

  /// 获取八字原局内部的所有干支感应 (刑冲合害等)
  List<InteractionResult> getAllInteractions() {
    return getInteractionsWith();
  }

  /// 获取八字原局与外部（如大运、流年）组合后的所有感应
  ///
  /// [otherStems] 和 [otherBranches] 允许传入额外的干支节点进行池化扫描
  List<InteractionResult> getInteractionsWith({
    List<InteractionNode<TianGan>> otherStems = const [],
    List<InteractionNode<DiZhi>> otherBranches = const [],
  }) {
    // 1. 构建天干池 (原局四柱 + 外部传入)
    final List<InteractionNode<TianGan>> stemPool = [
      InteractionNode(PillarType.year, bazi.year.gan),
      InteractionNode(PillarType.month, bazi.month.gan),
      InteractionNode(PillarType.day, bazi.day.gan),
      InteractionNode(PillarType.hour, bazi.time.gan),
      ...otherStems,
    ];

    // 2. 构建地支池 (原局四柱 + 外部传入)
    final List<InteractionNode<DiZhi>> branchPool = [
      InteractionNode(PillarType.year, bazi.year.zhi),
      InteractionNode(PillarType.month, bazi.month.zhi),
      InteractionNode(PillarType.day, bazi.day.zhi),
      InteractionNode(PillarType.hour, bazi.time.zhi),
      ...otherBranches,
    ];

    // 3. 执行计算
    final List<InteractionResult> results = [];
    results.addAll(
      BaziInteractionCalculator.calculateStemInteractions(stemPool),
    );
    results.addAll(
      BaziInteractionCalculator.calculateBranchInteractions(branchPool),
    );

    return results;
  }
}

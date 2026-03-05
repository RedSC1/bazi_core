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
  // ai写的代码真不行，我重构了一下下面的命宫身宫算法的代码
  int _getGongMonthIndex() {
    // 1. 获取当前八字月支 (0-based)
    final m = bazi.month.zhi.index;
    var prevJieQi = getPrevJieQi(time.bjClt);
    if (prevJieQi != null && isQi(prevJieQi.index)) {
      return (m + 1) % 12;
    } else {
      return m;
    }
  }

  /// 计算命宫
  GanZhi _calculateMingGong() {
    final fixedMonthIndex = (_getGongMonthIndex() - 2 + 12) % 12; // 寅月是正月！！
    final hourIndex = bazi.time.zhi.index; // 子 = 0
    final startIndex = 2; // 寅 = 2
    final branchIndex = (startIndex + fixedMonthIndex - hourIndex + 12) % 12;
    final stem = _calculateStemForGong(branchIndex);
    return GanZhi(stem, DiZhi.values[branchIndex]);
  }

  /// 计算身宫
  GanZhi _calculateShenGong() {
    final fixedMonthIndex = (_getGongMonthIndex() - 2 + 12) % 12; // 寅月是正月！！
    final hourIndex = bazi.time.zhi.index; // 子 = 0
    final startIndex = 2; // 寅 = 2
    final branchIndex = (startIndex + fixedMonthIndex + hourIndex + 12) % 12;
    final stem = _calculateStemForGong(branchIndex);
    return GanZhi(stem, DiZhi.values[branchIndex]);
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

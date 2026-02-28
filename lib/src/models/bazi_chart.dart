import 'package:bazi_core/src/astronomy/time_adapter.dart';
import 'package:bazi_core/src/models/enums.dart';
import 'package:bazi_core/src/models/interaction_calculator.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

class BaziChart {
  TimePack time;
  BaZi bazi;
  LunarDate lunarDate;
  Gender gender;
  BaziChart(this.time, this.bazi, this.lunarDate, this.gender);
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
    results.addAll(BaziInteractionCalculator.calculateStemInteractions(stemPool));
    results.addAll(BaziInteractionCalculator.calculateBranchInteractions(branchPool));

    return results;
  }
}

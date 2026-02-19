import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 时间封装包 (TimePack)
///
/// 核心职责：
/// 1. 承载用户输入的原始时间 (Clock Time)。
/// 2. 计算并携带天文时间 (UTC, True Solar Time)。
/// 3. 确定排盘基准时间 (Virtual Time)，但不做换日处理。
/// 4. 携带排盘配置 (如是否分早晚子时)。
class TimePack {
  /// 用户输入的墙上钟表时间 (Face Value)。
  /// 比如: 2026-02-18 12:00:00
  final AstroDateTime clockTime;

  /// 真太阳时计算结果 (包含均时差、日中天等数据)。
  final SolarTimeResult solarTime;

  /// 【排盘基准时间】
  ///
  ///这是用于定【日柱】和【时柱】的时间。
  /// - 如果 useTrueSolarTime = true，此处为真太阳时。
  /// - 如果 useTrueSolarTime = false，此处为钟表时间。
  /// 注意：此处【不处理】早晚子时的日期变更，保持原始值。
  final AstroDateTime virtualTime;

  /// 世界协调时 (UTC)。
  ///
  /// 核心用途：用于和天文算法返回的【节气】(Solar Term) 进行绝对时间对比。
  /// 计算公式：clockTime - timezone。
  final AstroDateTime utcTime;

  /// 用户所在时区 (小时偏移，如 +8.0)。
  final double timezone;

  /// 用户所在地理位置 (经纬度)。
  final Location location;

  /// 配置：是否区分早晚子时。
  /// - true: 23:00-00:00 算当天的晚子时。
  /// - false: 23:00-00:00 算明天的早子时。
  /// 该字段仅作存储，具体逻辑下放给 calcGanZhi 函数。
  final bool splitRatHour;

  TimePack({
    required this.clockTime,
    required this.solarTime,
    required this.virtualTime,
    required this.utcTime,
    required this.timezone,
    required this.location,
    required this.splitRatHour,
  });

  /// 用户创建入口
  factory TimePack.createBySolarTime({
    required AstroDateTime clockTime,
    double timezone = 8.0,
    Location location = const Location(
      120.0, // ✅ 默认使用UTC+8标准线，而非北京城
      30.0, // ✅ 使用中间纬度
    ),
    bool splitByRatHour = false, // 默认不分(即23点换日)，可配置
    bool useTrueSolarTime = true, // 默认使用真太阳时
  }) {
    // 1. 无论用不用，先算出真太阳时备着 (Data Calculation)
    final solarTimeResult = calcTrueSolarTime(
      clockTime,
      location,
      timezone: timezone,
    );

    // 2. 确定排盘基准时间 (Base Time Strategy)
    AstroDateTime baseTime;
    if (useTrueSolarTime) {
      // 真太阳派：使用经纬度+均时差矫正后的时间
      baseTime = solarTimeResult.trueSolarTime;
    } else {
      // 钟表派：直接使用墙上的钟表时间
      // 忽略经度差和均时差
      baseTime = clockTime;
    }

    // 换日逻辑完全交给 calcGanZhi内部去判断。
    final AstroDateTime virtualTime = baseTime;

    // 3. 计算 UTC (Universal Time Strategy)
    // 这是给"上帝"看的时间，用来比对节气
    final double deltaSeconds = timezone * 3600;
    final AstroDateTime utcTime = clockTime.subtract(
      Duration(seconds: deltaSeconds.round()),
    );

    return TimePack(
      clockTime: clockTime,
      solarTime: solarTimeResult,
      virtualTime: virtualTime,
      utcTime: utcTime,
      timezone: timezone,
      location: location,
      splitRatHour: splitByRatHour, // 将配置透传
    );
  }

  AstroDateTime get bjClt => utcTime.add(Duration(hours: 8)); //120E的时间
}

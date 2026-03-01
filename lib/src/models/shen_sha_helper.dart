import 'package:bazi_core/bazi_core.dart';
import 'package:bazi_core/src/models/shen_sha.dart';

/// 神煞分析结果
class ShenShaInfo {
  /// 年柱神煞列表
  final List<String> yearShenSha;

  /// 月柱神煞列表
  final List<String> monthShenSha;

  /// 日柱神煞列表
  final List<String> dayShenSha;

  /// 时柱神煞列表
  final List<String> hourShenSha;

  /// 大运神煞列表 (如果提供了大运)
  final List<String> daYunShenSha;

  /// 流年神煞列表 (如果提供了流年)
  final List<String> liuNianShenSha;

  /// 流月神煞列表 (如果提供了流月)
  final List<String> liuYueShenSha;

  /// 流日神煞列表 (如果提供了流日)
  final List<String> liuRiShenSha;

  /// 流时神煞列表 (如果提供了流时)
  final List<String> liuShiShenSha;

  const ShenShaInfo({
    this.yearShenSha = const [],
    this.monthShenSha = const [],
    this.dayShenSha = const [],
    this.hourShenSha = const [],
    this.daYunShenSha = const [],
    this.liuNianShenSha = const [],
    this.liuYueShenSha = const [],
    this.liuRiShenSha = const [],
    this.liuShiShenSha = const [],
  });

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('年柱: ${yearShenSha.isEmpty ? "无" : yearShenSha.join(", ")}');
    buf.writeln('月柱: ${monthShenSha.isEmpty ? "无" : monthShenSha.join(", ")}');
    buf.writeln('日柱: ${dayShenSha.isEmpty ? "无" : dayShenSha.join(", ")}');
    buf.writeln('时柱: ${hourShenSha.isEmpty ? "无" : hourShenSha.join(", ")}');
    if (daYunShenSha.isNotEmpty) {
      buf.writeln('大运: ${daYunShenSha.join(", ")}');
    }
    if (liuNianShenSha.isNotEmpty) {
      buf.writeln('流年: ${liuNianShenSha.join(", ")}');
    }
    if (liuYueShenSha.isNotEmpty) {
      buf.writeln('流月: ${liuYueShenSha.join(", ")}');
    }
    if (liuRiShenSha.isNotEmpty) {
      buf.writeln('流日: ${liuRiShenSha.join(", ")}');
    }
    if (liuShiShenSha.isNotEmpty) {
      buf.writeln('流时: ${liuShiShenSha.join(", ")}');
    }
    return buf.toString();
  }
}

/// 神煞计算助手
class ShenShaHelper {
  /// 获取特定柱的神煞列表
  ///
  /// [chart] 八字排盘对象
  /// [pillar] 要检查的柱干支
  /// [type] 柱类型
  static List<String> getShenSha(
    BaziChart chart,
    GanZhi pillar,
    PillarType type,
  ) {
    final result = <String>[];
    for (final shenSha in shenShaRegistry) {
      if (shenSha.check(chart, pillar, type)) {
        result.add(shenSha.name);
      }
    }
    return result;
  }

  /// 全盘神煞分析
  ///
  /// [chart] 八字排盘对象
  /// [daYun] 大运干支 (可选)
  /// [liuNian] 流年干支 (可选)
  /// [liuYue] 流月干支 (可选)
  /// [liuRi] 流日干支 (可选)
  /// [liuShi] 流时干支 (可选)
  static ShenShaInfo analyze(
    BaziChart chart, {
    GanZhi? daYun,
    GanZhi? liuNian,
    GanZhi? liuYue,
    GanZhi? liuRi,
    GanZhi? liuShi,
  }) {
    return ShenShaInfo(
      yearShenSha: getShenSha(chart, chart.bazi.year, PillarType.year),
      monthShenSha: getShenSha(chart, chart.bazi.month, PillarType.month),
      dayShenSha: getShenSha(chart, chart.bazi.day, PillarType.day),
      hourShenSha: getShenSha(chart, chart.bazi.time, PillarType.hour),
      daYunShenSha: daYun != null
          ? getShenSha(chart, daYun, PillarType.decade)
          : const [],
      liuNianShenSha: liuNian != null
          ? getShenSha(chart, liuNian, PillarType.flowYear)
          : const [],
      liuYueShenSha: liuYue != null
          ? getShenSha(chart, liuYue, PillarType.flowMonth)
          : const [],
      liuRiShenSha: liuRi != null
          ? getShenSha(chart, liuRi, PillarType.flowDay)
          : const [],
      liuShiShenSha: liuShi != null
          ? getShenSha(chart, liuShi, PillarType.flowHour)
          : const [],
    );
  }
}

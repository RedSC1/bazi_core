import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart'; // Needed for AstroDateTime

// Note: ShenShaHelper is exported by bazi_core.dart.

/// Helper to parse GanZhi string (e.g. "甲子")
GanZhi parseGanZhi(String s) {
  if (s.length != 2) {
    throw FormatException('GanZhi string must be 2 characters (e.g. "甲子")');
  }
  // These helpers are available via bazi_core -> sxwnl_spa_dart
  final gan = TianGan.fromName(s[0]);
  final zhi = DiZhi.fromName(s[1]);
  return GanZhi(gan, zhi);
}

/// Helper to create a BaziChart for ShenSha analysis
BaziChart createChart(String year, String month, String day, String time) {
  final bazi = BaZi(
    year: parseGanZhi(year),
    month: parseGanZhi(month),
    day: parseGanZhi(day),
    time: parseGanZhi(time),
  );

  // Create dummy time/lunar date as they are required for BaziChart construction
  // but mostly irrelevant for basic ShenSha checks (except those relying on gender/season which use month branch)
  // We use a fixed date for simplicity.
  final dummyTime = AstroDateTime(2024, 1, 1, 12, 0, 0);
  final timePack = TimePack.createBySolarTime(clockTime: dummyTime);
  final lunarDate = LunarDate.fromSolar(dummyTime);

  // Default to Male gender for this demo. Some ShenSha (like TianLuoDiWang) depend on gender.
  // Ideally this should also be an input.
  return BaziChart(timePack, bazi, lunarDate, Gender.male);
}

void main(List<String> args) {
  print('=== 八字神煞分析演示 ===\n');

  String yearStr, monthStr, dayStr, timeStr;
  String? daYunStr, liuNianStr;

  if (args.length >= 4) {
    yearStr = args[0];
    monthStr = args[1];
    dayStr = args[2];
    timeStr = args[3];
    if (args.length >= 5) daYunStr = args[4];
    if (args.length >= 6) liuNianStr = args[5];
  } else {
    print('未提供完整的八字参数。使用默认示例：');
    print('用法: dart example/shensha_demo.dart <年柱> <月柱> <日柱> <时柱> [大运] [流年]');
    print('示例: dart example/shensha_demo.dart 甲子 丙寅 辛卯 甲午 庚辰 辛巳');
    print('--------------------------------------------------\n');

    // Default Example:
    // Year: 甲子, Month: 丙寅, Day: 辛卯, Time: 甲午
    // DaYun: 庚辰, LiuNian: 辛巳
    yearStr = '甲子';
    monthStr = '丙寅';
    dayStr = '辛卯';
    timeStr = '甲午';
    daYunStr = '庚辰';
    liuNianStr = '辛巳';
  }

  try {
    print('正在分析八字: $yearStr(年) $monthStr(月) $dayStr(日) $timeStr(时)');
    if (daYunStr != null) print('大运: $daYunStr');
    if (liuNianStr != null) print('流年: $liuNianStr');

    final chart = createChart(yearStr, monthStr, dayStr, timeStr);

    // Use ShenShaHelper to analyze
    final daYunGZ = daYunStr != null ? parseGanZhi(daYunStr) : null;
    final liuNianGZ = liuNianStr != null ? parseGanZhi(liuNianStr) : null;

    // Example: Add LiuYue (Flow Month) for demonstration if not provided via args
    // Assuming Flow Month is RenWu (壬午)
    final liuYueGZ = parseGanZhi('壬午');
    print('流月: 壬午 (演示添加)');

    final info = ShenShaHelper.analyze(
      chart,
      daYun: daYunGZ,
      liuNian: liuNianGZ,
      liuYue: liuYueGZ, // Add flow month analysis
    );

    print('\n[分析结果]');
    print(info);
  } catch (e) {
    print('\n错误: $e');
    print('请确保输入的干支字符正确 (例如 "甲子")。');
  }
}

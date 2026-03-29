import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// FortuneTable 验证脚本
///
/// 使用方法：
/// 1. 修改下面的测试用例（出生时间）
/// 2. 运行：dart test test/fortune_table_verify.dart
/// 3. 对比其他软件的输出
void main() {
  // ==================== 测试用例配置 ====================
  // 在这里填入你想测试的出生时间
  final testCases = [
    // 用户指定的时间：2026年2月4日 19:48
    _TestCase(
      name: '2026年2月4日 19:48（立春当天）',
      year: 2026,
      month: 2,
      day: 4,
      hour: 19,
      minute: 48,
      gender: Gender.female,
    ),
  ];

  // ==================== 运行测试 ====================
  for (final tc in testCases) {
    print('\n${'=' * 60}');
    print('测试用例：${tc.name}');
    print('=' * 60);

    // 创建八字盘
    final chart = BaziChart.createBySolarDate(
      clockTime: AstroDateTime(tc.year, tc.month, tc.day, tc.hour, tc.minute),
      gender: tc.gender,
    );

    // 打印基本信息
    print('\n【基本信息】');
    print('八字：${chart.bazi}');
    print('性别：${tc.gender == Gender.male ? '男' : '女'}');
    print('农历：${chart.lunarDate}');

    // 创建岁运
    final fortune = Fortune.createByBaziChart(chart);
    print('\n【起运信息】');
    print('起运年龄：${fortune.startAge.toStringAsFixed(2)} 岁');
    print('起运时间：${fortune.qiYunTime}');
    print('大运顺逆：${fortune.direction == 1 ? '顺行' : '逆行'}');

    // 生成流运表
    final table = FortuneTable.build(fortune, decadeCount: 3); // 只生成3步方便看

    // 打印大运
    print('\n【大运列表】');
    for (final d in table.decades) {
      print(
        '  第${d.index}步 ${d.ganZhi}：${d.startAge}岁~${d.endAge}岁 '
        '(${d.startTime.year}.${d.startTime.month} ~ ${d.endTime.year}.${d.endTime.month})',
      );
    }

    // 打印第一步大运的详细流年
    print('\n【第一步大运 - 流年详情】');
    final firstDecade = table.decades.first;
    for (final y in firstDecade.years) {
      print('  ${y.year}年 ${y.ganZhi} (${y.months.length}个月)');
    }

    // 打印特定流年的流月（节气交接验证）
    print('\n【${firstDecade.years.first.year}年 - 流月详情（节气验证）】');
    final firstYear = firstDecade.years.first;
    for (int i = 0; i < firstYear.months.length && i < 3; i++) {
      final m = firstYear.months[i];
      print('  流月 ${m.ganZhi}：');
      print('    起止：${m.startTime} ~ ${m.endTime}');
      print('    天数：${m.days.length}天');
      print('    首日流日：${m.days.first.ganZhi} (${m.days.first.date})');
      print('    末日流日：${m.days.last.ganZhi} (${m.days.last.date})');
    }

    // 关键验证点：节气交接当天的归属
    print('\n【关键验证点：节气交接当天归属】');
    if (firstYear.months.length >= 2) {
      final m1 = firstYear.months[0];
      final m2 = firstYear.months[1];
      print('  ${m1.ganZhi} 最后一天：${m1.days.last.date} ${m1.days.last.ganZhi}');
      print('  ${m2.ganZhi} 第一天：${m2.days.first.date} ${m2.days.first.ganZhi}');
      print('  交接时刻：${m2.startTime}');
      print('  → 验证：交接当天(${m2.days.first.date})算哪个月？');
    }

    // 早晚子时完整对比
    print('\n【早晚子时完整时辰表对比】');
    final testDay = firstYear.months.first.days.first;
    print('  日期：${testDay.date}，日柱：${testDay.ganZhi}');
    print('');

    // 不分早晚子时
    print('  ┌─────────────────────────────────────────┐');
    print('  │  不分早晚子时（12个时辰）                 │');
    print('  ├──────────┬────────────────┬─────────────┤');
    print('  │   时辰   │     时间       │    干支     │');
    print('  ├──────────┼────────────────┼─────────────┤');
    for (final h in testDay.hours) {
      final timeStr = '${h.startTime.toTimeString().substring(0, 5)}-${h.endTime.toTimeString().substring(0, 5)}';
      print('  │  ${h.name}时   │  $timeStr      │    ${h.ganZhi}    │');
    }
    print('  └──────────┴────────────────┴─────────────┘');

    // 分早晚子时
    final tableSplit = FortuneTable.build(fortune, decadeCount: 1, splitByRatHour: true);
    final splitDay = tableSplit.decades.first.years.first.months.first.days.first;
    print('');
    print('  ┌─────────────────────────────────────────┐');
    print('  │  分早晚子时（13个时辰）                   │');
    print('  ├──────────┬────────────────┬─────────────┤');
    print('  │   时辰   │     时间       │    干支     │');
    print('  ├──────────┼────────────────┼─────────────┤');
    for (final h in splitDay.hours) {
      final timeStr = '${h.startTime.toTimeString().substring(0, 5)}-${h.endTime.toTimeString().substring(0, 5)}';
      final note = (h.startTime.hour == 23) ? '（晚子）' : '';
      print('  │  ${h.name}时   │  $timeStr      │    ${h.ganZhi}    $note│');
    }
    print('  └──────────┴────────────────┴─────────────┘');
    print('');
    print('  说明：');
    print('    • 日干 ${testDay.ganZhi.gan.label} 起五鼠遁');
    print('    • 次日干 ${dayGanZhi(testDay.date.add(Duration(days: 1))).gan.label} 起五鼠遁（晚子用）');

    // 起运前的小运（可选）
    print('\n【起运前小运（验证用）】');
    for (int age = 1; age <= fortune.startAge.ceil() + 1 && age <= 5; age++) {
      final xiaoYun = fortune.getXiaoYunByAge(age);
      print('  $age岁小运：$xiaoYun');
    }

    print('\n');
  }

  print('\n${'=' * 60}');
  print('验证建议：');
  print('1. 对比其他排盘工具的"大运流年"页面，检查起运年龄是否一致');
  print('2. 对比第一步大运的流年干支是否一致');
  print('3. 重点检查节气交接当天的归属（如立春当天算哪个月）');
  print('4. 对比流日干支');
  print('=' * 60);
}

class _TestCase {
  final String name;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final Gender gender;

  _TestCase({
    required this.name,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.gender,
  });
}

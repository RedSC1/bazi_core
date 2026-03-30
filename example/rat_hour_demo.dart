import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  print('=== 🌙 子时流派逻辑交叉验证 Demo ===');
  print('测试时间: 2000-01-01 23:30:00');
  print('日柱背景: 1月1日为戊午日, 1月2日为己未日');
  print('------------------------------------');

  final testTime = AstroDateTime(2000, 1, 1, 23, 30, 0);

  // 1. 不分早晚子 (传统派)
  final tp1 = TimePack.createBySolarTime(
    clockTime: testTime,
    ratHourMode: RatHourMode.noSplit,
  );
  final bz1 = TimeAdaptor.fromSolar(tp1);
  print('【1. 不分早晚子】结果: ${bz1.day}日 ${bz1.time}时');
  print('   -> 预期: 23:00 准时换日, 结果应为 [己未日 甲子时]');

  print('');

  // 2. 晚子算当天 + 今天天干 (古法派)
  final tp2 = TimePack.createBySolarTime(
    clockTime: testTime,
    ratHourMode: RatHourMode.todayGan,
  );
  final bz2 = TimeAdaptor.fromSolar(tp2);
  print('【2. 晚子算当天+今天干】结果: ${bz2.day}日 ${bz2.time}时');
  print('   -> 预期: 00:00 换日, 时干按今天算, 结果应为 [戊午日 壬子时]');

  print('');

  // 3. 晚子算当天 + 明天天干 (主流派/问真)
  final tp3 = TimePack.createBySolarTime(
    clockTime: testTime,
    ratHourMode: RatHourMode.tomorrowGan,
  );
  final bz3 = TimeAdaptor.fromSolar(tp3);
  print('【3. 晚子算当天+明天干】结果: ${bz3.day}日 ${bz3.time}时');
  print('   -> 预期: 00:00 换日, 时干借用明天, 结果应为 [戊午日 甲子时]');

  print('------------------------------------');
  print('✅ 验证完成！如果输出符合预期，说明底层逻辑已完美。');
}

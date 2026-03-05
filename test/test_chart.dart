import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 使用固定时间进行回归测试 (2026-03-05 10:04)
  const year = 2026;
  const month = 3;
  const day = 5;
  const hour = 10;
  const minute = 4;

  print('测试时间: $year-$month-$day $hour:$minute');
  print('');

  // 创建 AstroDateTime
  final astroTime = AstroDateTime(year, month, day, hour, minute, 0);

  // 创建 TimePack
  final timePack = TimePack.createBySolarTime(clockTime: astroTime);

  // 计算八字
  final bazi = TimeAdaptor.fromSolar(timePack);

  // 计算农历
  final lunarDate = LunarDate.fromSolar(astroTime);

  // 创建命盘
  final chart = BaziChart(timePack, bazi, lunarDate, Gender.male);

  print('=== 八字 ===');
  print('年柱: ${bazi.year}');
  print('月柱: ${bazi.month}');
  print('日柱: ${bazi.day}');
  print('时柱: ${bazi.time}');
  print('');

  print('=== 宫位 ===');
  print('命宫: ${chart.mingGong}');
  print('身宫: ${chart.shenGong}');
  print('胎元: ${chart.taiYuan}');
  print('胎息: ${chart.taiXi}');
}

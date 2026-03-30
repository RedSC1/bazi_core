import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

class TimeAdaptor {
  static BaZi strBz2Bz(GanZhiResult strBazi) {
    GanZhi parseGanZhi(String ganZhi) {
      if (ganZhi.length < 2) {
        throw ArgumentError('Invalid GanZhi: $ganZhi');
      }
      return GanZhi(TianGan.fromName(ganZhi[0]), DiZhi.fromName(ganZhi[1]));
    }

    final year = parseGanZhi(strBazi.yearGanZhi);
    final month = parseGanZhi(strBazi.monthGanZhi);
    final day = parseGanZhi(strBazi.dayGanZhi);
    final time = parseGanZhi(strBazi.timeGanZhi);

    return BaZi(year: year, month: month, day: day, time: time);
  }

  static BaZi fromSolar(TimePack time) {
    final mode = time.ratHourMode;
    // 1. 获取基础计算结果 (sxwnl 默认 23:00 换日)
    final rawBaziResult = calcGanZhi(
      time.utcTime.toJ2000(),
      time.virtualTime.toJ2000(),
    );
    
    final bazi = strBz2Bz(rawBaziResult);

    // 如果不是晚子时（23:00-00:00），或者选的是“不拆分”模式，直接返回原样
    if (time.virtualTime.hour < 23 || mode == RatHourMode.noSplit) {
      return bazi;
    }

    // --- 处理晚子时算当天 (00:00 换日) 的特殊逻辑 ---
    
    // 2. 还原日柱：利用你重载的 -1 运算符，强行回到今天
    final todayDay = bazi.day - 1; 

    // 3. 确定最终的时柱干支
    GanZhi finalTimePillar;
    if (mode == RatHourMode.todayGan) {
      // 【模式：晚子用今天天干】
      // 重新基于“今天日干”推算子时天干 (五鼠遁)
      finalTimePillar = getDayHourGanZhi(todayDay.gan)[0]; 
    } else {
      // 【模式：晚子用明天天干】(主流)
      // 保持 rawBazi 里的时干不变（因为它已经是明天的子时天干了），地支确保是子
      finalTimePillar = GanZhi(bazi.time.gan, DiZhi.zi);
    }

    return BaZi(
      year: bazi.year,
      month: bazi.month,
      day: todayDay, // 回归今天
      time: finalTimePillar,
    );
  }
}

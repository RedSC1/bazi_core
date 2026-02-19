import 'package:bazi_core/src/models/gan_zhi.dart';
import 'package:bazi_core/src/models/timepack.dart';
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

  static BaZi fromSolar(TimePack time, {bool splitRatHour = false}) {
    final rawBazi = calcGanZhi(
      time.utcTime.toJ2000(),
      time.virtualTime.toJ2000(),
    ); //默认不区分早晚子时的八字
    GanZhiResult strBazi;
    if (time.virtualTime.hour >= 23 && splitRatHour) {
      //区分早晚子时单独处理，这里采用拼接的方式
      final tbz = calcGanZhi(
        time.utcTime.toJ2000() - 23 / 24,
        time.virtualTime.toJ2000() - 23 / 24,
      );
      strBazi = GanZhiResult(
        yearGanZhi: rawBazi.yearGanZhi,
        monthGanZhi: rawBazi.monthGanZhi,
        dayGanZhi: tbz.dayGanZhi,
        timeGanZhi: tbz.timeGanZhi,
        timeZhiIndex: tbz.timeZhiIndex,
      );
    } else {
      strBazi = rawBazi;
    }
    return strBz2Bz(strBazi);
  }
}

import 'package:bazi_core/src/astronomy/time_adapter.dart';
import 'package:bazi_core/src/models/constants.dart';
import 'package:bazi_core/src/models/enums.dart';
import 'package:bazi_core/src/models/gan_zhi.dart';
import 'package:bazi_core/src/models/lunar_date.dart';
import 'package:bazi_core/src/models/timepack.dart';
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
}

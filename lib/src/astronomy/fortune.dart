import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

class QiYunDt {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  QiYunDt(this.year, this.month, this.day, this.hour, this.minute, this.second);

  @override
  String toString() {
    return "出生后 $year年 $month个月 $day天 $hour小时 $minute分钟 $second 秒 交运";
  }
}

class Decade {
  final int index; // 第几步大运 (1, 2, 3...)
  final AstroDateTime startTime; // 大运开始的钟表时间
  final AstroDateTime endTime; // 大运结束的钟表时间
  final int startAge; // 起步虚岁 (传统八字必用！比如 7)
  final int endAge; // 结束虚岁 (比如 17)
  final GanZhi ganZhi; // 大运干支

  Decade(
    this.index,
    this.startTime,
    this.endTime,
    this.startAge,
    this.endAge,
    this.ganZhi,
  );

  factory Decade.createByIndex(
    int index,
    AstroDateTime qiYunDate,
    AstroDateTime birthday,
    GanZhi originalMonth,
    int direction,
  ) {
    // 1. 时间推算 (你的防平年2.29陷阱)
    int stYear = qiYunDate.year + (index - 1) * 10;
    int stMonth = qiYunDate.month;
    int stDay = qiYunDate.day;
    if (stMonth == 2 && stDay == 29 && !_isLeapYear(stYear)) {
      stMonth = 3;
      stDay = 1;
    }

    int etYear = qiYunDate.year + index * 10;
    int etMonth = qiYunDate.month;
    int etDay = qiYunDate.day;
    if (etMonth == 2 && etDay == 29 && !_isLeapYear(etYear)) {
      etMonth = 3;
      etDay = 1;
    }

    final st = AstroDateTime(
      stYear,
      stMonth,
      stDay,
      qiYunDate.hour,
      qiYunDate.minute,
      qiYunDate.second,
    );
    final et = AstroDateTime(
      etYear,
      etMonth,
      etDay,
      qiYunDate.hour,
      qiYunDate.minute,
      qiYunDate.second,
    );

    // 虚岁算法 = 当前年份 - 出生年份 + 1
    final sAge = stYear - birthday.year + 1;
    final eAge = sAge + 9;

    // 3. 干支推算
    final gz = originalMonth + (direction * index);

    return Decade(index, st, et, sAge, eAge, gz);
  }

  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}

class Fortune {
  final AstroDateTime birthday; //生日的钟表时间
  final AstroDateTime qiYunTime; //钟表时间
  final double startAge; //起运年龄
  final int direction; //1 == 顺行, -1 == 逆行
  final GanZhi daYunBase; //大运的起始干支，这里是第0个大运，就是月份干支
  final GanZhi xiaoYunBase; //小运的其实干支，同上，就是时柱
  final QiYunDt qiYunDt;
  final DaYunAlgorithm daYunAlgorithm;
  Fortune(
    this.birthday,
    this.qiYunTime,
    this.startAge,
    this.direction,
    this.daYunBase,
    this.xiaoYunBase,
    this.qiYunDt, {
    this.daYunAlgorithm = DaYunAlgorithm.precise120,
  });

  ///使用真太阳时来构建起运时间
  factory Fortune.createByBaziChart(
    BaziChart bz, {
    DaYunAlgorithm daYunAlgorithm = DaYunAlgorithm.precise120,
  }) {
    //-1为阴，1为阳
    int yearD = bz.bazi.year.gan.index % 2 == 0 ? 1 : -1;
    int genderD = bz.gender == Gender.male ? 1 : -1;
    int direction = yearD * genderD; //-1逆行 1顺行
    final dyb = bz.bazi.month;
    final xyb = bz.bazi.time;
    AstroDateTime qiYunDate;
    double startAge;
    QiYunDt qiYunDt;
    switch (daYunAlgorithm) {
      case DaYunAlgorithm.precise120:
        (qiYunDate, startAge, qiYunDt) = _getPreciseQiYunTime(
          bz.time,
          direction,
        );
        break;
      default:
        throw UnimplementedError("该大运算法尚未实现: $daYunAlgorithm");
      //剩下的流派以后再说
    }
    return Fortune(
      bz.time.clockTime,
      qiYunDate,
      startAge,
      direction,
      dyb,
      xyb,
      qiYunDt,
    );
  }

  ///计算起运时间
  ///
  ///[birthday]出生时间
  ///
  ///[direction]方向，-1为逆1为顺
  ///
  ///返回J2000钟表时间
  static (AstroDateTime, double, QiYunDt) _getPreciseQiYunTime(
    TimePack birthday,
    int direction,
  ) {
    double deltaBtJieAndBtd;

    if (direction == -1) {
      // 逆行
      final prevJie = getPrevJieJd(birthday.bjClt) ?? 0;
      deltaBtJieAndBtd = birthday.bjClt.toJ2000() - prevJie;
    } else {
      // 顺行
      final nextJie = getNextJieJd(birthday.bjClt) ?? 0;
      deltaBtJieAndBtd = nextJie - birthday.bjClt.toJ2000();
    }

    // 1. 120倍膨胀，得到大运流逝的“玄学总天数”
    double qiyunJD = deltaBtJieAndBtd * 120.0;

    // 2. 剥离玄学标签：拆解成年、月、日、时、分、秒
    int y = (qiyunJD / 360).floor();
    double remDays = qiyunJD % 360;

    int m = (remDays / 30).floor();
    remDays = remDays % 30;

    int d = remDays.floor();

    double remTimeVal = remDays - d;
    double totalSecondsRem = remTimeVal * 86400;

    int h = (totalSecondsRem / 3600).floor();
    int mi = ((totalSecondsRem % 3600) / 60).floor();
    int s = (totalSecondsRem % 60).round();

    // 3. 日历步进 (复刻 Python 的 relativedelta)
    // 获取出生的原始年月日时分秒
    int finalYear = birthday.clockTime.year + y;
    int finalMonth = birthday.clockTime.month + m;

    // 处理月份溢出 (比如 10月 + 5个月 = 15月 -> 变成明年 3月)
    if (finalMonth > 12) {
      // 这里用 ~/ 整除，算出要进几位年
      finalYear += (finalMonth - 1) ~/ 12;
      // 剩下的就是最终月份 (1-12)
      finalMonth = (finalMonth - 1) % 12 + 1;
    }

    // 4. 处理天、时、分、秒的偏移
    // 我们先构造出加完“年月”的基准点，然后再把剩下的天数和时分秒用 Duration 加进去
    AstroDateTime baseDate = AstroDateTime(
      finalYear,
      finalMonth,
      1,
      birthday.clockTime.hour,
      birthday.clockTime.minute,
      birthday.clockTime.second,
    );

    // 用 Duration 加减剩下的物理时间是绝对安全的
    AstroDateTime finalDate = baseDate.add(
      Duration(
        days: d + birthday.clockTime.day - 1,
        hours: h,
        minutes: mi,
        seconds: s,
      ),
    );

    // 返回起运的精确岁数 (物理天数 / 3 = 年)
    double startAge = deltaBtJieAndBtd / 3.0;
    return (finalDate, startAge, QiYunDt(y, m, d, h, mi, s));
  }

  Decade getDecadeByIndex(int index) {
    return Decade.createByIndex(
      index,
      qiYunTime,
      birthday,
      daYunBase,
      direction,
    );
  }

  GanZhi getXiaoYunByAge(int age) {
    return xiaoYunBase + age * direction;
  }
}

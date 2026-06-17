import 'package:bazi_core/bazi_core.dart';

class Relationship {
  /// 获取天干相对于日主的十神关系
  static ShiShen getShiShen(TianGan dayMaster, TianGan targetGan) {
    int self = dayMaster.index;
    int target = targetGan.index;
    return ShiShen.values[((((target >>> 1) - (self >>> 1) + 5) % 5) << 1) |
        ((self ^ target) & 1)];
  }

  /// 获取地支藏干相对于日主的十神列表
  static List<ShiShen> getCangGanShiShen(TianGan dayMaster, DiZhi targetZhi) {
    return BaziTable.getCangGan(
      targetZhi,
    ).map((gan) => getShiShen(dayMaster, gan)).toList();
  }
}

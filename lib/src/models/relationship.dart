import 'package:bazi_core/bazi_core.dart';
import 'package:bazi_core/src/models/bazi_table.dart';

class Relationship {
  // 当日主为“阳干”时，目标干与日主的位移(0-9)对应的十神
  static const List<ShiShen> _yangMasterTb = [
    ShiShen.biJian,    // +0 (甲见甲)
    ShiShen.jieCai,    // +1 (甲见乙)
    ShiShen.shiShen,   // +2 (甲见丙)
    ShiShen.shangGuan, // +3 (甲见丁)
    ShiShen.pianCai,   // +4 (甲见戊)
    ShiShen.zhengCai,  // +5 (甲见己)
    ShiShen.qiSha,     // +6 (甲见庚)
    ShiShen.zhengGuan, // +7 (甲见辛)
    ShiShen.pianYin,   // +8 (甲见壬)
    ShiShen.zhengYin,  // +9 (甲见癸)
  ];

  // 当日主为“阴干”时，目标干与日主的位移(0-9)对应的十神
  static const List<ShiShen> _yinMasterTb = [
    ShiShen.biJian,    // +0 (乙见乙)
    ShiShen.shangGuan, // +1 (乙见丙)
    ShiShen.shiShen,   // +2 (乙见丁)
    ShiShen.zhengCai,  // +3 (乙见戊)
    ShiShen.pianCai,   // +4 (乙见己)
    ShiShen.zhengGuan, // +5 (乙见庚)
    ShiShen.qiSha,     // +6 (乙见辛)
    ShiShen.zhengYin,  // +7 (乙见壬)
    ShiShen.pianYin,   // +8 (乙见癸)
    ShiShen.jieCai,    // +9 (乙见甲)
  ];
  
  /// 获取天干相对于日主的十神关系
  static ShiShen getShiShen(TianGan dayMaster, TianGan targetGan){
    // 统一计算位移 d (0-9)
    int d = (targetGan.index - dayMaster.index + 10) % 10;
    
    if (BaziTable.getYinYangOfGan(dayMaster) == YinYang.yang) {
      return _yangMasterTb[d];
    } else {
      return _yinMasterTb[d];
    }
  }

  /// 获取地支藏干相对于日主的十神列表
  static List<ShiShen> getCangGanShiShen(TianGan dayMaster, DiZhi targetZhi) {
    return BaziTable.getCangGan(targetZhi)
        .map((gan) => getShiShen(dayMaster, gan))
        .toList();
  }
}

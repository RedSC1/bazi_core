//下面这些是ai生成的代码，以后有空我会人工校验的，包括shensha.dart,但是目前没空，以后再说吧。。
//神煞功能谨慎使用。。我看dart这边也没有能算神煞的库吧好像。。

import 'package:bazi_core/src/models/enums.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 纳音五行辅助类
class NayinHelper {
  /// 60甲子纳音五行表 (顺序：甲子, 乙丑, 丙寅, 丁卯...)
  static const List<WuXing> _nayinWuXing = [
    WuXing.metal, WuXing.metal, // 甲子乙丑海中金
    WuXing.fire, WuXing.fire, // 丙寅丁卯炉中火
    WuXing.wood, WuXing.wood, // 戊辰己巳大林木
    WuXing.earth, WuXing.earth, // 庚午辛未路旁土
    WuXing.metal, WuXing.metal, // 壬申癸酉剑锋金
    WuXing.fire, WuXing.fire, // 甲戌乙亥山头火
    WuXing.water, WuXing.water, // 丙子丁丑涧下水
    WuXing.earth, WuXing.earth, // 戊寅己卯城头土
    WuXing.metal, WuXing.metal, // 庚辰辛巳白蜡金
    WuXing.wood, WuXing.wood, // 壬午癸未杨柳木
    WuXing.water, WuXing.water, // 甲申乙酉泉中水
    WuXing.earth, WuXing.earth, // 丙戌丁亥屋上土
    WuXing.fire, WuXing.fire, // 戊子己丑霹雳火
    WuXing.wood, WuXing.wood, // 庚寅辛卯松柏木
    WuXing.water, WuXing.water, // 壬辰癸巳长流水
    WuXing.metal, WuXing.metal, // 甲午乙未沙中金
    WuXing.fire, WuXing.fire, // 丙申丁酉山下火
    WuXing.wood, WuXing.wood, // 戊戌己亥平地木
    WuXing.earth, WuXing.earth, // 庚子辛丑壁上土
    WuXing.metal, WuXing.metal, // 壬寅癸卯金箔金
    WuXing.fire, WuXing.fire, // 甲辰乙巳覆灯火
    WuXing.water, WuXing.water, // 丙午丁未天河水
    WuXing.earth, WuXing.earth, // 戊申己酉大驿土
    WuXing.metal, WuXing.metal, // 庚戌辛亥钗钏金
    WuXing.wood, WuXing.wood, // 壬子癸丑桑柘木
    WuXing.water, WuXing.water, // 甲寅乙卯大溪水
    WuXing.earth, WuXing.earth, // 丙辰丁巳沙中土
    WuXing.fire, WuXing.fire, // 戊午己未天上火
    WuXing.wood, WuXing.wood, // 庚申辛酉石榴木
    WuXing.water, WuXing.water, // 壬戌癸亥大海水
  ];

  /// 获取干支的纳音五行
  static WuXing getNayinWuXing(GanZhi gz) {
    // GanZhi 的 index 应该是 0-59 (甲子=0)
    // 假设 sxwnl_spa_dart 的 GanZhi 实现了 index 属性或类似机制
    // 如果没有 index，我们需要手动计算： (干index * 6 + 支index) / 2 ... 不对，这是复杂的公式
    // 最简单是 (干index - 支index) / 2 ... 也不对
    // 60甲子表是固定的。
    // 我们可以用 (gan.index, zhi.index) 查表，或者假设 GanZhi 有顺序。
    // 这里我们简单实现一个计算逻辑：
    // 甲子(0,0)=0, 乙丑(1,1)=1 ...
    // 60甲子序列生成：
    int offset = (gz.gan.index - gz.zhi.index);
    if (offset < 0) offset += 12;
    // 公式：(天干索引 * 6 + 地支索引) / 2 ... 好像也不是
    // 让我们直接用笨办法：遍历匹配
    // 或者利用 GanZhi 对象的内置属性，如果有的话。
    // 既然我看不到 GanZhi 源码，我先假设它没有 index 属性，手动计算 0-59 索引。

    // 寻找 0-59 的索引
    // 0: 甲子, 1: 乙丑...
    // 索引 = (天干索引 + (6 - 地支索引 % 6) * 10) % 60 ? 不太对
    // 正确公式： i = (gan * 6 - zhi * 5 + 60) % 60 ? 不对
    // 通用公式： i = (gan + (gan < zhi ? 12 : 0) - zhi) / 2 * 10 + zhi ... 也不直观

    // 还是用最稳妥的查表法（基于 Enum 索引）
    // 60甲子顺序：
    // 0.甲子 1.乙丑 2.丙寅 3.丁卯 4.戊辰 5.己巳 6.庚午 7.辛未 8.壬申 9.癸酉 10.甲戌 11.乙亥
    // 12.丙子 ...

    // 实际上：GanZhi.index 通常是有的。如果没有，我们可以计算：
    // 设 x = gan.index (0-9), y = zhi.index (0-11)
    // 如果 x % 2 != y % 2，则是无效干支（但在 GanZhi 对象里应该是合法的）
    // 索引 = (x * 6 + y) % 60 ???
    // 比如 甲(0)子(0) -> 0. 乙(1)丑(1) -> 7 ?? 不对.

    // 让我们用一个简单的循环来确定索引，只算一次
    int index = -1;
    for (int i = 0; i < 60; i++) {
      int g = i % 10;
      int z = i % 12;
      if (g == gz.gan.index && z == gz.zhi.index) {
        index = i;
        break;
      }
    }

    if (index != -1) {
      return _nayinWuXing[index ~/ 2 * 2]; // 纳音每两个一组相同
    }

    // Fallback
    return WuXing.metal;
  }

  /// 获取五行的【长生】之地 (按古法水土同宫)
  /// 古籍原文：
  /// 金长生巳，木长生亥，火长生寅
  /// 水土长生申 (原文：水土长生申)
  static DiZhi getAncientZhangSheng(WuXing wx) {
    switch (wx) {
      case WuXing.wood:
        return DiZhi.hai;
      case WuXing.fire:
        return DiZhi.yin;
      case WuXing.metal:
        return DiZhi.si;
      case WuXing.water:
      case WuXing.earth: // 水土同宫
        return DiZhi.shen;
    }
  }

  /// 获取五行的【临官】之地 (按古法水土同宫)
  /// 长生 -> 沐浴 -> 冠带 -> 临官 (第4位)
  /// 顺行：
  /// 木(亥) -> 子 -> 丑 -> 寅(临官)
  /// 火(寅) -> 卯 -> 辰 -> 巳(临官)
  /// 金(巳) -> 午 -> 未 -> 申(临官)
  /// 水土(申) -> 酉 -> 戌 -> 亥(临官)
  static DiZhi getAncientLinGuan(WuXing wx) {
    switch (wx) {
      case WuXing.wood:
        return DiZhi.yin;
      case WuXing.fire:
        return DiZhi.si;
      case WuXing.metal:
        return DiZhi.shen;
      case WuXing.water:
      case WuXing.earth:
        return DiZhi.hai;
    }
  }

  /// 获取五行的【帝旺】之地 (按古法水土同宫)
  /// 临官 -> 帝旺 (第5位)
  /// 木(寅) -> 卯
  /// 火(巳) -> 午
  /// 金(申) -> 酉
  /// 水土(亥) -> 子
  static DiZhi getAncientDiWang(WuXing wx) {
    switch (wx) {
      case WuXing.wood:
        return DiZhi.mao;
      case WuXing.fire:
        return DiZhi.wu;
      case WuXing.metal:
        return DiZhi.you;
      case WuXing.water:
      case WuXing.earth:
        return DiZhi.zi;
    }
  }
}

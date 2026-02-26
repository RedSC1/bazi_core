import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'enums.dart';

/// 八字基础属性查表类
/// 
/// 采用静态常量表设计
class BaziTable {
  // --- 天干五行映射表 (0:甲, 1:乙, 2:丙, 3:丁, 4:戊, 5:己, 6:庚, 7:辛, 8:壬, 9:癸) ---
  static const List<WuXing> _tianGanWuXingTable = [
    WuXing.wood,  WuXing.wood,  // 甲乙 -> 木
    WuXing.fire,  WuXing.fire,  // 丙丁 -> 火
    WuXing.earth, WuXing.earth, // 戊己 -> 土
    WuXing.metal, WuXing.metal, // 庚辛 -> 金
    WuXing.water, WuXing.water, // 壬癸 -> 水
  ];

  // --- 地支五行映射表 (0:子, 1:丑, 2:寅, 3:卯, 4:辰, 5:巳, 6:午, 7:未, 8:申, 9:酉, 10:戌, 11:亥) ---
  static const List<WuXing> _diZhiWuXingTable = [
    WuXing.water, WuXing.earth, WuXing.wood,  WuXing.wood,  // 子丑寅卯
    WuXing.earth, WuXing.fire,  WuXing.fire,  WuXing.earth, // 辰巳午未
    WuXing.metal, WuXing.metal, WuXing.earth, WuXing.water, // 申酉戌亥
  ];

  // --- 地支藏干映射表 ---
  static final List<List<TianGan>> _diZhiCangGanTable = [
    [TianGan.values[9]], // 子: 癸
    [TianGan.values[5], TianGan.values[9], TianGan.values[7]], // 丑: 己癸辛
    [TianGan.values[0], TianGan.values[2], TianGan.values[4]], // 寅: 甲丙戊
    [TianGan.values[1]], // 卯: 乙
    [TianGan.values[4], TianGan.values[1], TianGan.values[9]], // 辰: 戊乙癸
    [TianGan.values[2], TianGan.values[6], TianGan.values[4]], // 巳: 丙庚戊
    [TianGan.values[3], TianGan.values[5]], // 午: 丁己
    [TianGan.values[5], TianGan.values[3], TianGan.values[1]], // 未: 己丁乙
    [TianGan.values[6], TianGan.values[8], TianGan.values[4]], // 申: 庚壬戊
    [TianGan.values[7]], // 酉: 辛
    [TianGan.values[4], TianGan.values[7], TianGan.values[3]], // 戌: 戊辛丁
    [TianGan.values[8], TianGan.values[0]], // 亥: 壬甲
  ];

  // --- 静态获取方法 ---

  /// 获取天干五行
  static WuXing getWuXingOfGan(TianGan gan) => _tianGanWuXingTable[gan.index % 10];

  /// 获取地支五行
  static WuXing getWuXingOfZhi(DiZhi zhi) => _diZhiWuXingTable[zhi.index % 12];

  /// 获取地支藏干 (顺序为：本气、中气、余气)
  static List<TianGan> getCangGan(DiZhi zhi) => _diZhiCangGanTable[zhi.index % 12];

  /// 获取天干阴阳
  /// (偶数 index 为阳，奇数 index 为阴)
  static YinYang getYinYangOfGan(TianGan gan) => 
      (gan.index % 2 == 0) ? YinYang.yang : YinYang.yin;

  /// 获取地支阴阳
  /// (注意：这是地支本身的阴阳属性，即 0:子(阳), 1:丑(阴)...)
  static YinYang getYinYangOfZhi(DiZhi zhi) => 
      (zhi.index % 2 == 0) ? YinYang.yang : YinYang.yin;

  /// 获取地支藏干阴阳
  static List<YinYang> getYinYangOfCangGan(DiZhi zhi) {
    return getCangGan(zhi).map((gan) => getYinYangOfGan(gan)).toList();
  }

  /// 获取长生十二神
  /// 
  /// [algo] 土同宫算法，默认为火土同宫 (fireEarth)
  static TwelveLifeStage getLifeStage(
    TianGan gan, 
    DiZhi zhi, {
    EarthPalaceAlgorithm algo = EarthPalaceAlgorithm.fireEarth,
  }) {
    // 基础起点表 (火土同宫版)
    List<int> startIdxTable = [11, 6, 2, 9, 2, 9, 5, 0, 8, 3];
    
    // 如果是水土同宫，修正戊(index 4)和己(index 5)的起点
    if (algo == EarthPalaceAlgorithm.waterEarth) {
      startIdxTable[4] = 8; // 戊随壬 (壬从申8开始)
      startIdxTable[5] = 3; // 己随癸 (癸从卯3开始)
    }

    int startZhiIdx = startIdxTable[gan.index % 10];
    int targetZhiIdx = zhi.index % 12;

    int stageIdx;
    if (getYinYangOfGan(gan) == YinYang.yang) {
      // 阳干：顺行
      stageIdx = (targetZhiIdx - startZhiIdx + 12) % 12;
    } else {
      // 阴干：逆行
      stageIdx = (startZhiIdx - targetZhiIdx + 12) % 12;
    }

    return TwelveLifeStage.values[stageIdx];
  }
}

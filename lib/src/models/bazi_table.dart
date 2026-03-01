import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'enums.dart';

/// 八字基础属性查表类
///
/// 采用静态常量表设计
class BaziTable {
  // --- 天干五行映射表 (0:甲, 1:乙, 2:丙, 3:丁, 4:戊, 5:己, 6:庚, 7:辛, 8:壬, 9:癸) ---
  static const List<WuXing> _tianGanWuXingTable = [
    WuXing.wood, WuXing.wood, // 甲乙 -> 木
    WuXing.fire, WuXing.fire, // 丙丁 -> 火
    WuXing.earth, WuXing.earth, // 戊己 -> 土
    WuXing.metal, WuXing.metal, // 庚辛 -> 金
    WuXing.water, WuXing.water, // 壬癸 -> 水
  ];

  // --- 地支五行映射表 (0:子, 1:丑, 2:寅, 3:卯, 4:辰, 5:巳, 6:午, 7:未, 8:申, 9:酉, 10:戌, 11:亥) ---
  static const List<WuXing> _diZhiWuXingTable = [
    WuXing.water, WuXing.earth, WuXing.wood, WuXing.wood, // 子丑寅卯
    WuXing.earth, WuXing.fire, WuXing.fire, WuXing.earth, // 辰巳午未
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

  // ===========================================================================
  // 天干关系查表
  // ===========================================================================

  // 1. 天干五合配对表 (0-5, 1-6, 2-7, 3-8, 4-9)
  static const List<int> _stemComboPartners = [5, 6, 7, 8, 9, 0, 1, 2, 3, 4];

  // 2. 天干五合化合五行结果 (甲己土, 乙庚金, 丙辛水, 丁壬木, 戊癸火)
  static const List<WuXing> _stemComboResults = [
    WuXing.earth, WuXing.metal, WuXing.water, WuXing.wood, WuXing.fire, // 0-4
    WuXing.earth, WuXing.metal, WuXing.water, WuXing.wood, WuXing.fire, // 5-9
  ];

  // 3. 天干同性相克配对表 (index + 4) % 10
  // 甲(0)克戊(4), 乙(1)克己(5), 丙(2)克庚(6), 丁(3)克辛(7), 戊(4)克壬(8)...
  static const List<int> _stemRestraintPartners = [
    4,
    5,
    6,
    7,
    8,
    9,
    0,
    1,
    2,
    3,
  ];

  // 4. 天干四冲配对表 (甲庚, 乙辛, 丙壬, 丁癸; 戊己填 -1)
  static const List<int> _stemClashPartners = [6, 7, 8, 9, -1, -1, 0, 1, 2, 3];

  // --- 静态获取方法 ---

  /// 获取天干五行
  static WuXing getWuXingOfGan(TianGan gan) =>
      _tianGanWuXingTable[gan.index % 10];

  /// 获取地支五行
  static WuXing getWuXingOfZhi(DiZhi zhi) => _diZhiWuXingTable[zhi.index % 12];

  /// 获取地支藏干 (顺序为：本气、中气、余气)
  static List<TianGan> getCangGan(DiZhi zhi) =>
      _diZhiCangGanTable[zhi.index % 12];

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

  // ===========================================================================
  // 天干关系判定方法
  // ===========================================================================

  /// 【天干五合】判定
  static bool isStemCombination(TianGan a, TianGan b) =>
      _stemComboPartners[a.index % 10] == b.index % 10;

  /// 获取【天干五合】的化合结果 (若不构成五合则返回 null)
  static WuXing? getStemCombinationResult(TianGan a, TianGan b) =>
      isStemCombination(a, b) ? _stemComboResults[a.index % 10] : null;

  /// 获取天干五合的配对天干
  static TianGan getStemCombinationPartner(TianGan gan) =>
      TianGan.values[_stemComboPartners[gan.index % 10]];

  /// 【天干相克】判定 (仅限同性相克：阳克阳、阴克阴)
  static bool isStemRestraint(TianGan a, TianGan b) {
    int idxA = a.index % 10;
    int idxB = b.index % 10;
    return _stemRestraintPartners[idxA] == idxB ||
        _stemRestraintPartners[idxB] == idxA;
  }

  /// 【天干相冲】判定 (甲庚、乙辛、丙壬、丁癸)
  static bool isStemClash(TianGan a, TianGan b) {
    int p = _stemClashPartners[a.index % 10];
    return p != -1 && p == b.index % 10;
  }

  // ===========================================================================
  // 地支关系查表 (0:子, 1:丑, 2:寅, 3:卯, 4:辰, 5:巳, 6:午, 7:未, 8:申, 9:酉, 10:戌, 11:亥)
  // ===========================================================================

  // 1. 地支六合配对表 (子丑, 寅亥, 卯戌, 辰酉, 巳申, 午未)
  static const List<int> _branchComboPartners = [
    1,
    0,
    11,
    10,
    9,
    8,
    7,
    6,
    5,
    4,
    3,
    2,
  ];

  // 2. 地支六合化合五行结果 (子丑土, 寅亥木, 卯戌火, 辰酉金, 巳申水, 午未土)
  static const List<WuXing> _branchComboResults = [
    WuXing.earth, WuXing.earth, // 0:子, 1:丑 -> 土
    WuXing.wood, WuXing.fire, // 2:寅, 3:卯 -> 木, 火
    WuXing.metal, WuXing.water, // 4:辰, 5:巳 -> 金, 水
    WuXing.earth, WuXing.earth, // 6:午, 7:未 -> 土
    WuXing.water, WuXing.metal, // 8:申, 9:酉 -> 水, 金
    WuXing.fire, WuXing.wood, // 10:戌, 11:亥 -> 火, 木
  ];

  // 3. 地支六冲配对表 (index + 6) % 12
  static const List<int> _branchClashTable = [
    6,
    7,
    8,
    9,
    10,
    11,
    0,
    1,
    2,
    3,
    4,
    5,
  ];

  // 4. 地支六害配对表 (子未, 丑午, 寅巳, 卯辰, 申亥, 酉戌)
  static const List<int> _branchHarmTable = [
    7,
    6,
    5,
    4,
    3,
    2,
    1,
    0,
    11,
    10,
    9,
    8,
  ];

  // 5. 地支六破配对表 (子酉, 卯午, 辰丑, 未戌, 寅亥, 巳申)
  static const List<int> _branchDestructionTable = [
    9,
    4,
    11,
    6,
    1,
    8,
    3,
    10,
    5,
    0,
    7,
    2,
  ];

  // 6. 地支相绝配对表 (寅酉, 卯申, 巳子, 午亥; 其他不参与填 -1)
  static const List<int> _branchSeveranceTable = [
    5,
    -1,
    9,
    8,
    -1,
    0,
    11,
    -1,
    3,
    2,
    -1,
    6,
  ];

  // 7. 地支自刑列表 (辰午酉亥)
  static const Set<int> _branchSelfPunishmentSet = {4, 6, 9, 11};

  // 8. 地支相刑表 (两两相刑，含子卯刑及三刑组中的两两相刑)
  // 映射关系：子0-卯3, 寅2-巳5, 巳5-申8, 申8-寅2, 丑1-戌10, 戌10-未7, 未7-丑1
  static const Map<int, List<int>> _branchPunishmentMap = {
    0: [3], 3: [0], // 子卯
    2: [5, 8], 5: [2, 8], 8: [2, 5], // 寅巳申 互相刑
    1: [10, 7], 10: [1, 7], 7: [1, 10], // 丑戌未 互相刑
  };

  // 9. 地支暗合配对表 (寅丑2-1, 午亥6-11, 卯申3-8; 其他不参与填 -1)
  static const List<int> _branchHiddenComboTable = [
    -1,
    2,
    1,
    8,
    -1,
    -1,
    11,
    -1,
    3,
    -1,
    -1,
    6,
  ];

  // 10. 地支三合局组 (顺序：长生、中神、墓库)
  static const List<List<int>> _branchTripleCombinationGroups = [
    [8, 0, 4], // 申子辰 (水)
    [11, 3, 7], // 亥卯未 (木)
    [2, 6, 10], // 寅午戌 (火)
    [5, 9, 1], // 巳酉丑 (金)
  ];

  // 11. 地支三合局结果
  static const List<WuXing> _branchTripleCombinationResults = [
    WuXing.water,
    WuXing.wood,
    WuXing.fire,
    WuXing.metal,
  ];

  // 12. 地支三会局组 (顺序：方、位、气)
  static const List<List<int>> _branchTripleDirectionGroups = [
    [11, 0, 1], // 亥子丑 (水)
    [2, 3, 4], // 寅卯辰 (木)
    [5, 6, 7], // 巳午未 (火)
    [8, 9, 10], // 申酉戌 (金)
  ];

  // 13. 地支三会局结果
  static const List<WuXing> _branchTripleDirectionResults = [
    WuXing.water,
    WuXing.wood,
    WuXing.fire,
    WuXing.metal,
  ];

  // 14. 三刑全组 (寅巳申, 丑戌未)
  static const List<List<int>> _branchTriplePunishmentGroups = [
    [2, 5, 8],
    [1, 10, 7],
  ];

  // ===========================================================================
  // 静态获取方法 (组合关系)
  // ===========================================================================

  /// 获取地支三合局配置
  static List<List<int>> get branchTripleCombinationGroups =>
      _branchTripleCombinationGroups;

  /// 获取地支三合局对应的化合五行
  static WuXing getTripleCombinationWuXing(int groupIdx) =>
      _branchTripleCombinationResults[groupIdx];

  /// 获取地支三会局配置
  static List<List<int>> get branchTripleDirectionGroups =>
      _branchTripleDirectionGroups;

  /// 获取地支三会局对应的化合五行
  static WuXing getTripleDirectionWuXing(int groupIdx) =>
      _branchTripleDirectionResults[groupIdx];

  /// 获取地支三刑全配置
  static List<List<int>> get branchTriplePunishmentGroups =>
      _branchTriplePunishmentGroups;

  // ===========================================================================
  // 地支关系判定方法
  // ===========================================================================

  /// 【地支六合】判定
  static bool isBranchCombination(DiZhi a, DiZhi b) =>
      _branchComboPartners[a.index % 12] == b.index % 12;

  /// 获取【地支六合】的化合结果
  static WuXing? getBranchCombinationResult(DiZhi a, DiZhi b) =>
      isBranchCombination(a, b) ? _branchComboResults[a.index % 12] : null;

  /// 获取地支六合的配对地支
  static DiZhi getBranchCombinationPartner(DiZhi zhi) =>
      DiZhi.values[_branchComboPartners[zhi.index % 12]];

  /// 【地支六冲】判定
  static bool isBranchClash(DiZhi a, DiZhi b) =>
      _branchClashTable[a.index % 12] == b.index % 12;

  /// 【地支六害】判定
  static bool isBranchHarm(DiZhi a, DiZhi b) =>
      _branchHarmTable[a.index % 12] == b.index % 12;

  /// 【地支六破】判定
  static bool isBranchDestruction(DiZhi a, DiZhi b) =>
      _branchDestructionTable[a.index % 12] == b.index % 12;

  /// 【地支相绝】判定
  static bool isBranchSeverance(DiZhi a, DiZhi b) {
    int p = _branchSeveranceTable[a.index % 12];
    return p != -1 && p == b.index % 12;
  }

  /// 【地支自刑】判定 (两个地支必须相同且属于辰午酉亥之一)
  static bool isBranchSelfPunishment(DiZhi a, DiZhi b) =>
      a == b && _branchSelfPunishmentSet.contains(a.index % 12);

  /// 【地支相刑】判定 (两两相刑)
  static bool isBranchPunishment(DiZhi a, DiZhi b) {
    if (a == b) return false;
    final punished = _branchPunishmentMap[a.index % 12];
    return punished != null && punished.contains(b.index % 12);
  }

  /// 【地支暗合】判定 (寅丑、午亥、卯申)
  static bool isBranchHiddenCombination(DiZhi a, DiZhi b) {
    int p = _branchHiddenComboTable[a.index % 12];
    return p != -1 && p == b.index % 12;
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

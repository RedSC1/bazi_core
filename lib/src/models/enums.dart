/// 大运起运/交运时间的计算算法流派
///
/// 八字排盘中，不同流派有细微差异。
enum DaYunAlgorithm {
  //默认流派，按照一年360天来计算
  //内部用JulianDay的差值*120再用一年360天一年12个月一个月30天的方式来计算（时分秒同理）
  precise120,
}

enum Gender { male, female }

enum YinYang { yin, yang }

enum WuXing { water, wood, metal, earth, fire }

/// 十神
enum ShiShen {
  biJian, // 比肩
  jieCai, // 劫财
  shiShen, // 食神
  shangGuan, // 伤官
  pianCai, // 偏财
  zhengCai, // 正财
  qiSha, // 七杀 (偏官)
  zhengGuan, // 正官
  pianYin, // 偏印 (枭神)
  zhengYin, // 正印
}

/// 长生十二神
enum TwelveLifeStage {
  zhangSheng, // 长生
  muYu, // 沐浴
  guanDai, // 冠带
  linGuan, // 临官
  diWang, // 帝旺
  shuai, // 衰
  bing, // 病
  si, // 死
  mu, // 墓
  jue, // 绝
  tai, // 胎
  yang, // 养
}

/// 土同宫算法
enum EarthPalaceAlgorithm {
  fireEarth, // 火土同宫 (戊随丙, 己随丁)
  waterEarth, // 水土同宫 (戊随壬, 己随癸)
}

/// 柱的类型 (用于标记干支的来源位置)
enum PillarType {
  /// 年柱
  year,

  /// 月柱
  month,

  /// 日柱
  day,

  /// 时柱
  hour,

  /// 命宫
  mingGong,

  /// 身宫
  shenGong,

  /// 胎元
  taiYuan,

  /// 胎息
  taiXi,

  /// 大运
  decade,

  /// 流年
  flowYear,

  /// 流月
  flowMonth,

  /// 流日
  flowDay,

  /// 流时
  flowHour,
}

enum BaziInteraction {
  // --- 天干关系 ---
  /// 天干五合 (如：甲己合)
  stemCombination,

  /// 天干四冲 (如：甲庚冲)
  stemClash,

  /// 天干相克 (如：甲克戊)
  stemRestraint,

  // --- 地支关系 ---
  /// 地支六合 (如：子丑合)
  branchCombination,

  /// 地支六冲 (如：子午冲)
  branchClash,

  /// 地支六害 (如：子未害)
  branchHarm,

  /// 地支六破 (如：子酉破)
  branchDestruction,

  // --- 刑的逻辑拆分 ---
  /// 地支三刑全 (如：寅巳申全)
  branchTriplePunishment,

  /// 地支相刑 (如：子卯刑，或三刑组中只出现两个，如寅巳)
  branchPunishment,

  /// 地支自刑 (如：辰辰、午午、酉酉、亥亥)
  branchSelfPunishment,

  // --- 合局/会局 ---
  /// 地支三合局 (如：申子辰)
  branchTripleCombination,

  /// 地支三会局 (如：亥子丑)
  branchTripleDirection,

  /// 地支半三合 (如：申子、子辰)
  branchHalfCombination,

  /// 地支拱合 (如：申辰拱子)
  branchArchingCombination,

  // --- 其他 ---
  /// 地支暗合 (如：寅丑、午亥)
  branchHiddenCombination,

  /// 地支绝/相绝 (如：寅酉、卯申)
  branchSeverance,
}

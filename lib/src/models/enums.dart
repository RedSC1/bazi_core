/// 大运起运/交运时间的计算算法流派
///
/// 八字排盘中，不同流派有细微差异。
enum DaYunAlgorithm {
  //默认流派，按照一年360天来计算
  //内部用JulianDay的差值*120再用一年360天一年12个月一个月30天的方式来计算（时分秒同理）
  precise120,
}

enum Gender{
  male,
  female,
}

enum YinYang{
  yin,
  yang,
}

enum WuXing {
  water,
  wood,
  metal,
  earth,
  fire,
}

/// 十神
enum ShiShen {
  biJian,    // 比肩
  jieCai,    // 劫财
  shiShen,   // 食神
  shangGuan, // 伤官
  pianCai,   // 偏财
  zhengCai,  // 正财
  qiSha,     // 七杀 (偏官)
  zhengGuan, // 正官
  pianYin,   // 偏印 (枭神)
  zhengYin,  // 正印
}

/// 长生十二神
enum TwelveLifeStage {
  zhangSheng, // 长生
  muYu,       // 沐浴
  guanDai,    // 冠带
  linGuan,    // 临官
  diWang,     // 帝旺
  shuai,      // 衰
  bing,       // 病
  si,         // 死
  mu,         // 墓
  jue,        // 绝
  tai,        // 胎
  yang,       // 养
}

/// 土同宫算法
enum EarthPalaceAlgorithm {
  fireEarth,  // 火土同宫 (戊随丙, 己随丁)
  waterEarth, // 水土同宫 (戊随壬, 己随癸)
}

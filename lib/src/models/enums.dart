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
  female
}
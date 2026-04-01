// 沟槽的人元司令分野表，我翻书翻了一晚上。。
// 我也不知道网上流传的那些天数到底是哪来的，反正我查了《三命通会》原文，全对不上。
// 就拿寅月戊土司令来说，三命通会写的是 5天，网上流传版说是 7天，
// 目前与主流排盘算法对齐，采用 8 天周期。
// 索性写了俩表：一个严格按三命通会原著，一个按网络流传/商业妥协版。
// 留个入参枚举，你们调用的时候自己看着选吧。。
// 还有，这个到底是24小时算一天还是过了0点就算一天？？？？？？？？
// 三命通会原文如下：
//
// 夫一气浑沦，形质未离，熟为阴阳？太始既肇，裂一为三，倏息乃分，
// 天得之而轻清为阳，地得之而重浊为阴，人位乎天地之中，禀阳阴冲和之气。
// 故此轻清者为十干，主禄，谓之天元，
// 重浊者为十二支，主身，谓之地元，
// 天地多正其位，成才于两间者，乃所谓人也。
// 故支吕所藏者主命，谓之人元，名为司事之神，以命术言之为月令。
//
// 如正月建寅，寅中有艮土用事五日，丙火长生五日，甲木二十日；
// 二月建卯，卯中有甲木用事七日，乙木二十三日；
// 三月建辰，辰中有乙木用事七日，壬水墓库五日，戊土一十八日；
// 四月建已，已中有戊土七日，庚金长生五日，丙火一十八日；
// 五月建午，午中丙火用事七日，丁火二十三日；
// 六月建未，未中有丁火用事七日，甲木墓库五日，已土一十八日；
// 七月建申，申中有坤土用事五日，壬水长生五日，庚金二十日；
// 八月建酉，酉中有庚金用事七日，辛金二十三日；
// 九月建戌，戌中有辛金用事七日，丙火墓库五日，戊土一十八日；
// 十月建亥，亥中有戊土五日，甲木长生五日，壬水用事二十日；
// 十一月建子，子中有壬水用事七日，癸水二十三日；
// 十二月建丑，丑中有癸水用事七日，庚金墓库五日，已土一十八日。
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 人元司令版本
enum SiLingVersion {
  /// 严格按《三命通会》原文 (5-5-20 等)
  sanMingTongHui,

  /// 网络流传版 / 商业排盘常用 (7-7-16 等)
  common,
}

/// 人元司令单项（月地支中某天干"用事"的天数）
class SiLingEntry {
  /// 司令的天干
  final TianGan gan;

  /// 司权天数
  final int days;

  /// 原文名称 (如 "艮土"、"坤土"、"甲木" 等)
  final String origin;

  const SiLingEntry(this.gan, this.days, this.origin);

  @override
  String toString() => '$origin($gan ${days}天)';
}

/// 人元司令计算结果
class SiLingResult {
  /// 当前司令的天干
  final TianGan gan;

  /// 原文名称
  final String origin;

  /// 距上一个节（月首）已过天数
  final double daysSinceJie;

  /// 当前所在月地支
  final DiZhi monthZhi;

  const SiLingResult({
    required this.gan,
    required this.origin,
    required this.daysSinceJie,
    required this.monthZhi,
  });

  @override
  String toString() => '$origin($gan) [距节${daysSinceJie.toStringAsFixed(2)}天]';
}

/// 人元司令分野表与计算逻辑
class SiLing {
  // ============================================================
  // 表一：《三命通会》原文版
  // ============================================================
  static const Map<DiZhi, List<SiLingEntry>> _sanMingTable = {
    // 正月(寅)：艮土5天 -> 丙火5天 -> 甲木20天
    DiZhi.yin: [
      SiLingEntry(TianGan.wu, 5, '艮土'),
      SiLingEntry(TianGan.bing, 5, '丙火'),
      SiLingEntry(TianGan.jia, 20, '甲木'),
    ],
    // 二月(卯)：甲木7天 -> 乙木23天
    DiZhi.mao: [
      SiLingEntry(TianGan.jia, 7, '甲木'),
      SiLingEntry(TianGan.yi, 23, '乙木'),
    ],
    // 三月(辰)：乙木7天 -> 壬水5天 -> 戊土18天
    DiZhi.chen: [
      SiLingEntry(TianGan.yi, 7, '乙木'),
      SiLingEntry(TianGan.ren, 5, '壬水'),
      SiLingEntry(TianGan.wu, 18, '戊土'),
    ],
    // 四月(巳)：戊土7天 -> 庚金5天 -> 丙火18天
    DiZhi.si: [
      SiLingEntry(TianGan.wu, 7, '戊土'),
      SiLingEntry(TianGan.geng, 5, '庚金'),
      SiLingEntry(TianGan.bing, 18, '丙火'),
    ],
    // 五月(午)：丙火7天 -> 丁火23天
    DiZhi.wu: [
      SiLingEntry(TianGan.bing, 7, '丙火'),
      SiLingEntry(TianGan.ding, 23, '丁火'),
    ],
    // 六月(未)：丁火7天 -> 甲木5天 -> 己土18天
    DiZhi.wei: [
      SiLingEntry(TianGan.ding, 7, '丁火'),
      SiLingEntry(TianGan.jia, 5, '甲木'),
      SiLingEntry(TianGan.ji, 18, '己土'),
    ],
    // 七月(申)：坤土5天 -> 壬水5天 -> 庚金20天
    DiZhi.shen: [
      SiLingEntry(TianGan.wu, 5, '坤土'),
      SiLingEntry(TianGan.ren, 5, '壬水'),
      SiLingEntry(TianGan.geng, 20, '庚金'),
    ],
    // 八月(酉)：庚金7天 -> 辛金23天
    DiZhi.you: [
      SiLingEntry(TianGan.geng, 7, '庚金'),
      SiLingEntry(TianGan.xin, 23, '辛金'),
    ],
    // 九月(戌)：辛金7天 -> 丙火5天 -> 戊土18天
    DiZhi.xu: [
      SiLingEntry(TianGan.xin, 7, '辛金'),
      SiLingEntry(TianGan.bing, 5, '丙火'),
      SiLingEntry(TianGan.wu, 18, '戊土'),
    ],
    // 十月(亥)：戊土5天 -> 甲木5天 -> 壬水20天
    DiZhi.hai: [
      SiLingEntry(TianGan.wu, 5, '戊土'),
      SiLingEntry(TianGan.jia, 5, '甲木'),
      SiLingEntry(TianGan.ren, 20, '壬水'),
    ],
    // 十一月(子)：壬水7天 -> 癸水23天
    DiZhi.zi: [
      SiLingEntry(TianGan.ren, 7, '壬水'),
      SiLingEntry(TianGan.gui, 23, '癸水'),
    ],
    // 十二月(丑)：癸水7天 -> 庚金5天 -> 己土18天
    DiZhi.chou: [
      SiLingEntry(TianGan.gui, 7, '癸水'),
      SiLingEntry(TianGan.geng, 5, '庚金'),
      SiLingEntry(TianGan.ji, 18, '己土'),
    ],
  };

  // ============================================================
  // 表二：网络流传版 / 商业排盘常用版
  // ============================================================
  static const Map<DiZhi, List<SiLingEntry>> _commonTable = {
    // 寅月：戊土7天 -> 丙火7天 -> 甲木16天
    DiZhi.yin: [
      SiLingEntry(TianGan.wu, 7, '戊土'),
      SiLingEntry(TianGan.bing, 7, '丙火'),
      SiLingEntry(TianGan.jia, 16, '甲木'),
    ],
    // 卯月：甲木10天 -> 乙木20天
    DiZhi.mao: [
      SiLingEntry(TianGan.jia, 10, '甲木'),
      SiLingEntry(TianGan.yi, 20, '乙木'),
    ],
    // 辰月：乙木9天 -> 癸水3天 -> 戊土18天
    DiZhi.chen: [
      SiLingEntry(TianGan.yi, 9, '乙木'),
      SiLingEntry(TianGan.gui, 3, '癸水'),
      SiLingEntry(TianGan.wu, 18, '戊土'),
    ],
    // 巳月：戊土5天 -> 庚金9天 -> 丙火16天
    DiZhi.si: [
      SiLingEntry(TianGan.wu, 5, '戊土'),
      SiLingEntry(TianGan.geng, 9, '庚金'),
      SiLingEntry(TianGan.bing, 16, '丙火'),
    ],
    // 午月：丙火10天 -> 己土9天 -> 丁火11天
    DiZhi.wu: [
      SiLingEntry(TianGan.bing, 10, '丙火'),
      SiLingEntry(TianGan.ji, 9, '己土'),
      SiLingEntry(TianGan.ding, 11, '丁火'),
    ],
    // 未月：丁火9天 -> 乙木3天 -> 己土18天
    DiZhi.wei: [
      SiLingEntry(TianGan.ding, 9, '丁火'),
      SiLingEntry(TianGan.yi, 3, '乙木'),
      SiLingEntry(TianGan.ji, 18, '己土'),
    ],
    // 申月：戊土10天 -> 壬水3天 -> 庚金17天
    DiZhi.shen: [
      SiLingEntry(TianGan.wu, 10, '戊土'),
      SiLingEntry(TianGan.ren, 3, '壬水'),
      SiLingEntry(TianGan.geng, 17, '庚金'),
    ],
    // 酉月：庚金10天 -> 辛金20天
    DiZhi.you: [
      SiLingEntry(TianGan.geng, 10, '庚金'),
      SiLingEntry(TianGan.xin, 20, '辛金'),
    ],
    // 戌月：辛金9天 -> 丁火3天 -> 戊土18天
    DiZhi.xu: [
      SiLingEntry(TianGan.xin, 9, '辛金'),
      SiLingEntry(TianGan.ding, 3, '丁火'),
      SiLingEntry(TianGan.wu, 18, '戊土'),
    ],
    // 亥月：戊土7天 -> 甲木5天 -> 壬水18天
    DiZhi.hai: [
      SiLingEntry(TianGan.wu, 7, '戊土'),
      SiLingEntry(TianGan.jia, 5, '甲木'),
      SiLingEntry(TianGan.ren, 18, '壬水'),
    ],
    // 子月：壬水10天 -> 癸水20天
    DiZhi.zi: [
      SiLingEntry(TianGan.ren, 10, '壬水'),
      SiLingEntry(TianGan.gui, 20, '癸水'),
    ],
    // 丑月：癸水9天 -> 辛金3天 -> 己土18天
    DiZhi.chou: [
      SiLingEntry(TianGan.gui, 9, '癸水'),
      SiLingEntry(TianGan.xin, 3, '辛金'),
      SiLingEntry(TianGan.ji, 18, '己土'),
    ],
  };

  /// 根据版本获取对应的表
  static Map<DiZhi, List<SiLingEntry>> getTable(SiLingVersion version) {
    switch (version) {
      case SiLingVersion.sanMingTongHui:
        return _sanMingTable;
      case SiLingVersion.common:
        return _commonTable;
    }
  }

  /// 计算人元司令
  ///
  /// [bjClt] 北京钟表时间 (120°E)
  /// [monthZhi] 八字月支
  /// [version] 使用哪个版本的天数表，默认三命通会
  static SiLingResult? calculate(
    AstroDateTime bjClt,
    DiZhi monthZhi, {
    SiLingVersion version = SiLingVersion.sanMingTongHui,
  }) {
    final jieDistance = getJieDistance(bjClt);
    if (jieDistance == null) return null;

    final daysSinceJie = jieDistance.daysSincePrevJie;
    final table = getTable(version);
    final entries = table[monthZhi];
    if (entries == null) return null;

    // 累加每段天数，找到当前时间落在哪一段
    double accumulated = 0;
    for (final entry in entries) {
      accumulated += entry.days;
      if (daysSinceJie < accumulated) {
        return SiLingResult(
          gan: entry.gan,
          origin: entry.origin,
          daysSinceJie: daysSinceJie,
          monthZhi: monthZhi,
        );
      }
    }

    // 兜底：如果超出总天数（不应该发生），返回最后一项（本气）
    final last = entries.last;
    return SiLingResult(
      gan: last.gan,
      origin: last.origin,
      daysSinceJie: daysSinceJie,
      monthZhi: monthZhi,
    );
  }
}


// 反正我就这么写了，两个表+24小时换天
// 玄学界的 undefined behavior 实锤了。先 commit 了
// ai说tyme库(https://6tail.cn/tyme.html)是0点换天，不管了
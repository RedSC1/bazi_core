// ============================================================================
// 🚨 实验性功能免责声明 (Experimental Feature Disclaimer) 🚨
// ============================================================================
// 注意：本文件包含的庞大神煞推演逻辑，全是由 AI 辅助生成的！
// 1. 【未经人工校验】：因为古代神煞口诀多如牛毛且逻辑极度混乱，作者本人看着这两千多行
//    的屎山代码实在头疼，因此 **并未进行任何人工逐行校验和单元测试**。
// 2. 【存在幻觉风险】：AI 在解析古代文言文时，极可能出现逻辑缝合、版本冲突，或者
//    纯粹的 AI 幻觉（比如搞错阴阳极性、把吉凶写反、生造神煞等）。
// 3. 【仅供娱乐】：本模块作为 [实验性功能] 仅供前端 UI 凑字数和玄学娱乐参考。排出的
//    神煞结果如果出现“既是大吉又是大凶”的自相矛盾，或者纯属瞎扯，本引擎概不负责。
//
// 调用建议：如果您在 UI 层展示了本文件的返回结果，请务必给用户提供相应的“实验性”
// 提示，切勿将其作为核心命运研判的依据。
// ============================================================================

import 'package:bazi_core/bazi_core.dart';
import 'package:bazi_core/src/models/nayin_helper.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 神煞基类
abstract class ShenSha {
  final String name;
  const ShenSha(this.name);

  /// 检查特定柱是否带有该神煞
  ///
  /// [bz] 八字原局上下文
  /// [gz] 当前被检查的柱的干支
  /// [targetType] 当前柱的类型（支持原局四柱、大运、流年等）
  bool check(BaziChart bz, GanZhi gz, PillarType targetType);
}

/// =========================================
/// 神煞通用判定引擎子类
/// =========================================

/// 【类型一：以天干查地支】 (如：天乙贵人、文昌贵人)
/// 以某柱（通常是日干或年干）的天干为基准，在其他柱的地支中寻找匹配项。
class StemToBranchShenSha extends ShenSha {
  final Map<TianGan, List<DiZhi>> rules;
  // 作为查找基准的柱索引列表，默认查日主和年主
  final List<PillarType> baseColumns;

  const StemToBranchShenSha(
    String name,
    this.rules, {
    this.baseColumns = const [PillarType.day, PillarType.year],
  }) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 目标检查的必须是一个地支，我们拿当前柱的 zhi 去校验
    final targetZhi = gz.zhi;

    for (var colType in baseColumns) {
      final baseGan = _getGanByType(bz, colType);
      if (baseGan == null) continue;

      final validBranches = rules[baseGan];
      if (validBranches != null && validBranches.contains(targetZhi)) {
        return true;
      }
    }
    return false;
  }

  TianGan? _getGanByType(BaziChart bz, PillarType type) {
    switch (type) {
      case PillarType.year:
        return bz.bazi.year.gan;
      case PillarType.month:
        return bz.bazi.month.gan;
      case PillarType.day:
        return bz.bazi.day.gan;
      case PillarType.hour:
        return bz.bazi.time.gan;
      default:
        return null;
    }
  }
}

/// 【类型二：以地支查地支】 (如：驿马、桃花)
/// 以某柱（通常是日支或年支）的地支为基准，在其他柱的地支中寻找匹配项。
class BranchToBranchShenSha extends ShenSha {
  final Map<DiZhi, List<DiZhi>> rules;
  // 作为查找基准的柱索引列表，默认查日支和年支
  final List<PillarType> baseColumns;

  const BranchToBranchShenSha(
    String name,
    this.rules, {
    this.baseColumns = const [PillarType.day, PillarType.year],
  }) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final targetZhi = gz.zhi;

    for (var colType in baseColumns) {
      final baseZhi = _getZhiByType(bz, colType);
      if (baseZhi == null) continue;

      final validBranches = rules[baseZhi];
      if (validBranches != null && validBranches.contains(targetZhi)) {
        return true;
      }
    }
    return false;
  }

  DiZhi? _getZhiByType(BaziChart bz, PillarType type) {
    switch (type) {
      case PillarType.year:
        return bz.bazi.year.zhi;
      case PillarType.month:
        return bz.bazi.month.zhi;
      case PillarType.day:
        return bz.bazi.day.zhi;
      case PillarType.hour:
        return bz.bazi.time.zhi;
      default:
        return null;
    }
  }
}

/// 【类型三：整柱自身特征】 (如：魁罡、阴阳差错)
/// 不看别人的脸色，只要当前柱的干支组合本身在给定的特殊列表里就成立。
class PillarShenSha extends ShenSha {
  // 符合条件的干支组合名称列表，如 ['庚辰', '壬辰', '戊戌', '庚戌']
  final List<String> validCombinations;
  // 指定必须在哪一柱生效。如果不指定，则任何一柱碰到都算。例如魁罡通常只论日柱。
  final List<PillarType>? validColumns;

  const PillarShenSha(String name, this.validCombinations, {this.validColumns})
    : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    if (validColumns != null && !validColumns!.contains(targetType)) {
      return false; // 当前柱不在生效柱列表内
    }
    return validCombinations.contains(gz.toString());
  }
}

/// 【类型四：以月支查其他柱干支】 (如：天德贵人、月德贵人)
/// 以月柱的地支（月令）为基准，在其他柱的天干或地支中寻找匹配项。
class MonthBranchToZhuShenSha extends ShenSha {
  // 规则表：以月支查天干 (如天德贵人里的 正月生见丁干)
  final Map<DiZhi, List<TianGan>>? targetStems;
  // 规则表：以月支查地支 (如天德贵人里的 卯月生见申支)
  final Map<DiZhi, List<DiZhi>>? targetBranches;

  const MonthBranchToZhuShenSha(
    String name, {
    this.targetStems,
    this.targetBranches,
  }) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final monthZhi = bz.bazi.month.zhi;

    // 检查目标柱的天干是否符合要求
    if (targetStems != null && targetStems![monthZhi] != null) {
      if (targetStems![monthZhi]!.contains(gz.gan)) {
        return true;
      }
    }

    // 检查目标柱的地支是否符合要求
    if (targetBranches != null && targetBranches![monthZhi] != null) {
      if (targetBranches![monthZhi]!.contains(gz.zhi)) {
        return true;
      }
    }

    return false;
  }
}

/// =========================================
/// 古法纳音学堂词馆系列实现
/// =========================================

/// 【纳音学堂/词馆】(正学堂/正词馆)
/// “夫学堂者...如金命见辛巳...纳音又属金是也。”
/// 规则：以年柱(或日柱)纳音五行为准，查长生(学堂)或临官(词馆)地支，且目标柱纳音五行必须相同。
class NayinShenSha extends ShenSha {
  final bool isZhangSheng; // true=学堂(长生), false=词馆(临官)

  const NayinShenSha(String name, {required this.isZhangSheng}) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 古法通常重年命，也兼看日命。此处为了全面，如果任一基准符合则算成立。
    // 但古籍原文“金命见辛巳”，通常指年命。
    // 我们优先查年柱，若需要也可扩展查日柱。这里仅查年柱以符古法“命”之意。
    final baseGZ = bz.bazi.year;
    final baseNayin = NayinHelper.getNayinWuXing(baseGZ);

    // 1. 确定目标地支
    DiZhi targetZhi;
    if (isZhangSheng) {
      targetZhi = NayinHelper.getAncientZhangSheng(baseNayin);
    } else {
      targetZhi = NayinHelper.getAncientLinGuan(baseNayin);
    }

    // 2. 检查地支是否匹配
    if (gz.zhi != targetZhi) {
      return false;
    }

    // 3. 检查纳音五行是否相同 ("纳音又属金是也")
    final currentNayin = NayinHelper.getNayinWuXing(gz);
    return currentNayin == baseNayin;
  }
}

/// 【官贵学堂/词馆】(学堂会禄)
/// “以官贵长生之位为学堂，官贵临官之位为词馆也。”
/// 规则：日干 -> 正官五行 -> 长生/临官支。
class OfficialShenSha extends ShenSha {
  final bool isZhangSheng;

  const OfficialShenSha(String name, {required this.isZhangSheng})
    : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final dayGan = bz.bazi.day.gan;

    // 1. 找正官五行
    // 克我者为官杀。这里简化处理，直接找正官的天干，取其五行。
    // 实际上只要是被克五行即可。
    // 甲木(木) -> 克我者金。
    // 乙木(木) -> 克我者金。
    final dayWuXing = BaziTable.getWuXingOfGan(dayGan);
    WuXing officialWuXing;
    switch (dayWuXing) {
      case WuXing.wood:
        officialWuXing = WuXing.metal;
        break;
      case WuXing.fire:
        officialWuXing = WuXing.water;
        break;
      case WuXing.earth:
        officialWuXing = WuXing.wood;
        break;
      case WuXing.metal:
        officialWuXing = WuXing.fire;
        break;
      case WuXing.water:
        officialWuXing = WuXing.earth;
        break;
    }

    // 2. 找该五行的长生/临官
    DiZhi targetZhi;
    if (isZhangSheng) {
      targetZhi = NayinHelper.getAncientZhangSheng(officialWuXing);
    } else {
      targetZhi = NayinHelper.getAncientLinGuan(officialWuXing);
    }

    return gz.zhi == targetZhi;
  }
}

/// 【官星学堂】(生处见克)
/// “有生处见克，如甲乙人辛亥...谓之官星学堂。”
/// 规则：日主长生支 + 该柱天干为正官。
class OfficialStarShenSha extends ShenSha {
  const OfficialStarShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final dayGan = bz.bazi.day.gan;
    final dayWuXing = BaziTable.getWuXingOfGan(dayGan);

    // 1. 找日主长生
    final zhangSheng = NayinHelper.getAncientZhangSheng(dayWuXing);
    if (gz.zhi != zhangSheng) return false;

    // 2. 找正官天干
    // 甲(0) -> 辛(7). 规律：(index - 3 + 10) % 10
    // 乙(1) -> 庚(6). (index - 5 + 10) % 10 ? 不对。
    // 只能查表。
    final officialGanIndex = _getOfficialGanIndex(dayGan.index);

    return gz.gan.index == officialGanIndex;
  }

  int _getOfficialGanIndex(int dayIndex) {
    // 正官：克我异性
    // 0(甲) <- 7(辛)
    // 1(乙) <- 6(庚)
    // 2(丙) <- 9(癸)
    // 3(丁) <- 8(壬)
    // 4(戊) <- 1(乙)
    // 5(己) <- 0(甲)
    // 6(庚) <- 3(丁)
    // 7(辛) <- 2(丙)
    // 8(壬) <- 5(己)
    // 9(癸) <- 4(戊)
    const map = [7, 6, 9, 8, 1, 0, 3, 2, 5, 4];
    return map[dayIndex];
  }
}

/// 【学堂会贵】(纳音帝旺 + 天乙贵人)
/// “有纳音见帝旺之位而逢天乙贵处其上...”
/// 规则：年命纳音帝旺支 && 是天乙贵人。
class NayinNobleShenSha extends ShenSha {
  const NayinNobleShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final yearGZ = bz.bazi.year;
    final nayin = NayinHelper.getNayinWuXing(yearGZ);

    // 1. 纳音帝旺
    final diWang = NayinHelper.getAncientDiWang(nayin);
    if (gz.zhi != diWang) return false;

    // 2. 检查是否为天乙贵人 (以年干或日干查)
    // 复用天乙贵人口诀逻辑
    return _isNoble(bz.bazi.year.gan, gz.zhi) ||
        _isNoble(bz.bazi.day.gan, gz.zhi);
  }

  bool _isNoble(TianGan gan, DiZhi zhi) {
    // 甲戊庚牛羊(丑未)
    // 乙己鼠猴乡(子申)
    // 丙丁猪鸡位(亥you)
    // 壬癸兔蛇藏(mao si)
    // 六辛逢马虎(wu yin)
    switch (gan) {
      case TianGan.jia:
      case TianGan.wu:
      case TianGan.geng:
        return zhi == DiZhi.chou || zhi == DiZhi.wei;
      case TianGan.yi:
      case TianGan.ji:
        return zhi == DiZhi.zi || zhi == DiZhi.shen;
      case TianGan.bing:
      case TianGan.ding:
        return zhi == DiZhi.hai || zhi == DiZhi.you;
      case TianGan.ren:
      case TianGan.gui:
        return zhi == DiZhi.mao || zhi == DiZhi.si;
      case TianGan.xin:
        return zhi == DiZhi.wu || zhi == DiZhi.yin;
    }
  }
}

/// 【空亡】(旬空)
/// 规则：以日柱（或年柱）查旬空，看其他地支是否落入空亡。
class KongWangShenSha extends ShenSha {
  const KongWangShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 1. 以日柱查空亡 (日空)
    final dayKongWang = bz.bazi.day.getKongWang();
    if (dayKongWang.contains(gz.zhi)) {
      return true;
    }

    // 2. 以年柱查空亡 (年空)
    final yearKongWang = bz.bazi.year.getKongWang();
    if (yearKongWang.contains(gz.zhi)) {
      return true;
    }

    return false;
  }
}

/// 通用：月支查天干神煞
class MonthBranchToStemShenSha extends ShenSha {
  final Map<DiZhi, List<TianGan>> targetStems;

  const MonthBranchToStemShenSha(String name, {required this.targetStems})
    : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final monthZhi = bz.bazi.month.zhi;
    final validStems = targetStems[monthZhi];
    if (validStems == null) return false;

    return validStems.contains(gz.gan);
  }
}

/// 【天厨贵人】(本旬食神)
/// “甲人见丙寅...遁得本旬中真食神。”
/// 规则：四柱中某一柱，必须是“年柱(或日柱)所在旬”中的“食神”干支。
class TianChuShenSha extends ShenSha {
  const TianChuShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 分别检查年柱和日柱的本旬食神
    if (_isXunShiShen(bz.bazi.year, gz)) return true;
    if (_isXunShiShen(bz.bazi.day, gz)) return true;
    return false;
  }

  /// 检查 [target] 是否是 [base] 所在旬的食神
  bool _isXunShiShen(GanZhi base, GanZhi target) {
    // 1. 找到 base 的食神天干
    // 甲(0) -> 丙(2)
    // 乙(1) -> 丁(3)
    // 规律：(base.gan.index + 2) % 10 ? 不对，这是顺生。
    // 甲木生丙火。0 -> 2.
    // 乙木生丁火。1 -> 3.
    // 丙火生戊土。2 -> 4.
    // 庚金生壬水。6 -> 8.
    // 壬水生甲木。8 -> 0.
    // 癸水生乙木。9 -> 1.
    // 规律确为：(gan + 2) % 10 ?
    // 让我们验证一下阴干：
    // 乙(1) -> 丁(3). 1+2=3. 对。
    // 丁(3) -> 己(5). 3+2=5. 对。
    // 辛(7) -> 癸(9). 7+2=9. 对。
    // 癸(9) -> 乙(1). 9+2=11->1. 对。
    // 所以食神天干索引 = (base.gan.index + 2) % 10。
    final shiShenGanIndex = (base.gan.index + 2) % 10;

    // 2. 如果 target 的天干不是食神，直接排除
    if (target.gan.index != shiShenGanIndex) return false;

    // 3. 检查是否同旬
    // 同旬意味着：(target.gan - target.zhi) == (base.gan - base.zhi) (模12/10同余逻辑)
    // 或者简单点：计算旬首是否相同。
    // 旬首索引 = (gan - zhi) ...
    // 既然要判定 target 是否在 base 的旬里，且我们已经确认了 target 的天干是食神
    // 那么只需要确认 target 的地支是否正确。
    // 在同一旬中，天干确定了，地支也就确定了。
    // 比如甲子旬(甲子...癸酉)，食神是丙。
    // 甲(0)子(0) -> 旬首(0-0=0).
    // 丙(2) -> 地支必须满足 (2 - zhi) = 0 (mod 12) ? 不对。
    // 旬首计算公式：XunShou = (gan - zhi) % 12. (若负数+12) ?
    // 让我们推导：
    // 甲(0)子(0) -> 0.
    // 丙(2)寅(2) -> 0.
    // 乙(1)丑(1) -> 0.
    // 癸(9)酉(9) -> 0.
    // 所以：(gan - zhi) % 12 必须相等。

    int baseDiff = (base.gan.index - base.zhi.index) % 12;
    if (baseDiff < 0) baseDiff += 12;

    int targetDiff = (target.gan.index - target.zhi.index) % 12;
    if (targetDiff < 0) targetDiff += 12;

    return baseDiff == targetDiff;
  }
}

/// 【天医】(月建后一位)
/// 规则：以月支查地支，取月支前一位(逆行)。
class TianYiShenSha extends ShenSha {
  const TianYiShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final monthZhi = bz.bazi.month.zhi;
    // 逆行一位: (index - 1 + 12) % 12
    final targetIndex = (monthZhi.index - 1 + 12) % 12;
    return gz.zhi.index == targetIndex;
  }
}

/// 【天德合】(天德的合干/合支)
/// 规则：与天德贵人相合。
class TianDeHeShenSha extends ShenSha {
  const TianDeHeShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final monthZhi = bz.bazi.month.zhi;

    // 直接根据口诀匹配
    // 寅月壬、卯月巳、辰月丁、巳月丙、午月寅、未月己、
    // 申月戊、酉月亥、戌月辛、亥月庚、子月申、丑月乙
    switch (monthZhi) {
      case DiZhi.yin: // 寅月见壬
        return gz.gan == TianGan.ren;
      case DiZhi.mao: // 卯月见巳
        return gz.zhi == DiZhi.si;
      case DiZhi.chen: // 辰月见丁
        return gz.gan == TianGan.ding;
      case DiZhi.si: // 巳月见丙
        return gz.gan == TianGan.bing;
      case DiZhi.wu: // 午月见寅
        return gz.zhi == DiZhi.yin;
      case DiZhi.wei: // 未月见己
        return gz.gan == TianGan.ji;
      case DiZhi.shen: // 申月见戊
        return gz.gan == TianGan.wu;
      case DiZhi.you: // 酉月见亥
        return gz.zhi == DiZhi.hai;
      case DiZhi.xu: // 戌月见辛
        return gz.gan == TianGan.xin;
      case DiZhi.hai: // 亥月见庚
        return gz.gan == TianGan.geng;
      case DiZhi.zi: // 子月见申
        return gz.zhi == DiZhi.shen;
      case DiZhi.chou: // 丑月见乙
        return gz.gan == TianGan.yi;
    }
  }
}

/// 【三奇贵人】
/// 规则：四柱天干中包含特定的三个字。
class SanQiShenSha extends ShenSha {
  final List<TianGan> requiredStems;

  const SanQiShenSha(String name, this.requiredStems) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 就在日柱显示
    if (targetType != PillarType.day) return false;

    final stems = {
      bz.bazi.year.gan,
      bz.bazi.month.gan,
      bz.bazi.day.gan,
      bz.bazi.time.gan,
    };

    for (var s in requiredStems) {
      if (!stems.contains(s)) return false;
    }
    return true;
  }
}

/// 【魁罡】
/// 规则：日柱为 庚辰、壬辰、戊戌、庚戌 之一。
class KuiGangShenSha extends ShenSha {
  const KuiGangShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 只查日柱
    if (targetType != PillarType.day) return false;

    // 庚辰
    if (gz.gan == TianGan.geng && gz.zhi == DiZhi.chen) return true;
    // 壬辰
    if (gz.gan == TianGan.ren && gz.zhi == DiZhi.chen) return true;
    // 戊戌
    if (gz.gan == TianGan.wu && gz.zhi == DiZhi.xu) return true;
    // 庚戌
    if (gz.gan == TianGan.geng && gz.zhi == DiZhi.xu) return true;

    return false;
  }
}

/// =========================================
/// 神煞注册表 (全局中心)
/// =========================================
final List<ShenSha> shenShaRegistry = [
  // -------------------------
  // 1. 天乙贵人 (Stem -> Branch)
  // 口诀：甲戊庚牛羊，乙己鼠猴乡，丙丁猪鸡位，壬癸兔蛇藏，六辛逢马虎，此是贵人方。
  // 以日干和年干查四柱地支。
  // -------------------------
  StemToBranchShenSha('天乙贵人', {
    TianGan.jia: [DiZhi.chou, DiZhi.wei],
    TianGan.wu: [DiZhi.chou, DiZhi.wei],
    TianGan.geng: [DiZhi.chou, DiZhi.wei],
    TianGan.yi: [DiZhi.zi, DiZhi.shen],
    TianGan.ji: [DiZhi.zi, DiZhi.shen],
    TianGan.bing: [DiZhi.hai, DiZhi.you],
    TianGan.ding: [DiZhi.hai, DiZhi.you],
    TianGan.ren: [DiZhi.mao, DiZhi.si],
    TianGan.gui: [DiZhi.mao, DiZhi.si],
    TianGan.xin: [DiZhi.yin, DiZhi.wu],
  }),

  // -------------------------
  // 1.1 驿马 (Branch -> Branch)
  // 经典口诀：申子辰马在寅，寅午戌马在申，巳酉丑马在亥，亥卯未马在巳。
  // 理论来源（先天三合数）：
  // “所谓驿马者，乃先天三合数也...自子顺至申，凡二十有一而为火局(寅午戌)之驿马...
  // 亥卯未之数...凡十八而为木局之驿马(巳)...
  // 甲子辰(申子辰)之数...自午逆至寅，凡二十有一，而为水局之驿马...
  // 巳酉丑之数...自午至亥，凡十有八，而为金局之驿马。”
  // -------------------------
  BranchToBranchShenSha('驿马', {
    DiZhi.shen: [DiZhi.yin],
    DiZhi.zi: [DiZhi.yin],
    DiZhi.chen: [DiZhi.yin],

    DiZhi.yin: [DiZhi.shen],
    DiZhi.wu: [DiZhi.shen],
    DiZhi.xu: [DiZhi.shen],

    DiZhi.si: [DiZhi.hai],
    DiZhi.you: [DiZhi.hai],
    DiZhi.chou: [DiZhi.hai],

    DiZhi.hai: [DiZhi.si],
    DiZhi.mao: [DiZhi.si],
    DiZhi.wei: [DiZhi.si],
  }),

  // -------------------------
  // 1.2 咸池 (桃花) (Branch -> Branch)
  // 口诀：寅午戌见卯，申子辰见酉，巳酉丑见午，亥卯未见子。
  // 本质：五行局的沐浴(败)位。
  // 查找方式：以年、日支查余三支。
  // -------------------------
  BranchToBranchShenSha('咸池(桃花)', {
    // 寅午戌 -> 卯
    DiZhi.yin: [DiZhi.mao],
    DiZhi.wu: [DiZhi.mao],
    DiZhi.xu: [DiZhi.mao],

    // 申子辰 -> 酉
    DiZhi.shen: [DiZhi.you],
    DiZhi.zi: [DiZhi.you],
    DiZhi.chen: [DiZhi.you],

    // 巳酉丑 -> 午
    DiZhi.si: [DiZhi.wu],
    DiZhi.you: [DiZhi.wu],
    DiZhi.chou: [DiZhi.wu],

    // 亥卯未 -> 子
    DiZhi.hai: [DiZhi.zi],
    DiZhi.mao: [DiZhi.zi],
    DiZhi.wei: [DiZhi.zi],
  }),

  // -------------------------
  // 1.3 红鸾 (Branch -> Branch)
  // 口诀：子卯、丑寅、寅丑、卯子、辰亥、巳戌、午酉、未申、申未、酉午、戌巳、亥辰。
  // 查找方式：以年支查余三支。
  // -------------------------
  BranchToBranchShenSha(
    '红鸾',
    {
      DiZhi.zi: [DiZhi.mao],
      DiZhi.chou: [DiZhi.yin],
      DiZhi.yin: [DiZhi.chou],
      DiZhi.mao: [DiZhi.zi],
      DiZhi.chen: [DiZhi.hai],
      DiZhi.si: [DiZhi.xu],
      DiZhi.wu: [DiZhi.you],
      DiZhi.wei: [DiZhi.shen],
      DiZhi.shen: [DiZhi.wei],
      DiZhi.you: [DiZhi.wu],
      DiZhi.xu: [DiZhi.si],
      DiZhi.hai: [DiZhi.chen],
    },
    baseColumns: [PillarType.year], // 红鸾通常只查年支
  ),

  // -------------------------
  // 1.4 天喜 (Branch -> Branch)
  // 规则：红鸾的对冲位即为天喜。
  // 例如：子年红鸾在卯，卯酉冲，故天喜在酉。
  // 查找方式：以年支查余三支。
  // -------------------------
  BranchToBranchShenSha(
    '天喜',
    {
      DiZhi.zi: [DiZhi.you],
      DiZhi.chou: [DiZhi.shen],
      DiZhi.yin: [DiZhi.wei],
      DiZhi.mao: [DiZhi.wu],
      DiZhi.chen: [DiZhi.si],
      DiZhi.si: [DiZhi.chen],
      DiZhi.wu: [DiZhi.mao],
      DiZhi.wei: [DiZhi.yin],
      DiZhi.shen: [DiZhi.chou],
      DiZhi.you: [DiZhi.zi],
      DiZhi.xu: [DiZhi.hai],
      DiZhi.hai: [DiZhi.xu],
    },
    baseColumns: [PillarType.year], // 天喜通常只查年支
  ),

  // -------------------------
  // 1.5 羊刃 (Stem -> Branch)
  // 规则：日干（或年干）的帝旺位。
  // 阳干：甲卯、丙戊午、庚酉、壬子。
  // 阴干（逆行长生帝旺）：乙寅、丁己巳、辛申、癸亥。
  // -------------------------
  StemToBranchShenSha(
    '羊刃',
    {
      TianGan.jia: [DiZhi.mao],
      TianGan.yi: [DiZhi.yin],
      TianGan.bing: [DiZhi.wu],
      TianGan.ding: [DiZhi.si],
      TianGan.wu: [DiZhi.wu],
      TianGan.ji: [DiZhi.si],
      TianGan.geng: [DiZhi.you],
      TianGan.xin: [DiZhi.shen],
      TianGan.ren: [DiZhi.zi],
      TianGan.gui: [DiZhi.hai],
    },
    baseColumns: [PillarType.day], // 用户要求：只看日干
  ),

  // -------------------------
  // 1.5.1 飞刃 (Stem -> Branch)
  // 规则：羊刃的对冲位。
  // 甲(刃卯)冲酉，乙(刃寅)冲申，丙戊(刃午)冲子，丁己(刃巳)冲亥，
  // 庚(刃酉)冲卯，辛(刃申)冲寅，壬(刃子)冲午，癸(刃亥)冲巳。
  // -------------------------
  StemToBranchShenSha(
    '飞刃',
    {
      TianGan.jia: [DiZhi.you],
      TianGan.yi: [DiZhi.shen],
      TianGan.bing: [DiZhi.zi],
      TianGan.ding: [DiZhi.hai],
      TianGan.wu: [DiZhi.zi],
      TianGan.ji: [DiZhi.hai],
      TianGan.geng: [DiZhi.mao],
      TianGan.xin: [DiZhi.yin],
      TianGan.ren: [DiZhi.wu],
      TianGan.gui: [DiZhi.si],
    },
    baseColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.6 福星贵人 (Stem -> Branch)
  // 口诀：甲丙相邀入虎(寅)鼠(子)，乙癸兔(卯)牛(丑)求，戊申、己未、丁亥、庚午、辛巳、壬辰。
  // 查找方式：以年、日干查四柱地支。
  // -------------------------
  StemToBranchShenSha('福星贵人', {
    TianGan.jia: [DiZhi.yin, DiZhi.zi],
    TianGan.bing: [DiZhi.yin, DiZhi.zi],

    TianGan.yi: [DiZhi.mao, DiZhi.chou],
    TianGan.gui: [DiZhi.mao, DiZhi.chou],

    TianGan.wu: [DiZhi.shen],
    TianGan.ji: [DiZhi.wei],
    TianGan.ding: [DiZhi.hai],
    TianGan.geng: [DiZhi.wu],
    TianGan.xin: [DiZhi.si],
    TianGan.ren: [DiZhi.chen],
  }),

  // -------------------------
  // 1.7 灾煞 (Branch -> Branch)
  // 理论来源：“常居劫煞之前，冲破将星，谓之灾煞。”
  // 规则：三合局中神（帝旺）的对冲位。
  // 申子辰(将星子) -> 午；寅午戌(将星午) -> 子；
  // 巳酉丑(将星酉) -> 卯；亥卯未(将星卯) -> 酉。
  // 查找方式：以年、日支查余三支。
  // -------------------------
  BranchToBranchShenSha('灾煞', {
    // 申子辰 -> 午
    DiZhi.shen: [DiZhi.wu],
    DiZhi.zi: [DiZhi.wu],
    DiZhi.chen: [DiZhi.wu],

    // 寅午戌 -> 子
    DiZhi.yin: [DiZhi.zi],
    DiZhi.wu: [DiZhi.zi],
    DiZhi.xu: [DiZhi.zi],

    // 巳酉丑 -> 卯
    DiZhi.si: [DiZhi.mao],
    DiZhi.you: [DiZhi.mao],
    DiZhi.chou: [DiZhi.mao],

    // 亥卯未 -> 酉
    DiZhi.hai: [DiZhi.you],
    DiZhi.mao: [DiZhi.you],
    DiZhi.wei: [DiZhi.you],
  }),

  // -------------------------
  // 1.7 劫煞 (Branch -> Branch)
  // 理论来源：“劫在五行绝处...申子辰以巳为劫煞...寅午戌以亥为劫煞...”
  // 规则：三合局五行的绝地。
  // 查找方式：以年、日支查余三支。
  // -------------------------
  BranchToBranchShenSha('劫煞', {
    // 申子辰(水绝在巳)
    DiZhi.shen: [DiZhi.si],
    DiZhi.zi: [DiZhi.si],
    DiZhi.chen: [DiZhi.si],

    // 寅午戌(火绝在亥)
    DiZhi.yin: [DiZhi.hai],
    DiZhi.wu: [DiZhi.hai],
    DiZhi.xu: [DiZhi.hai],

    // 巳酉丑(金绝在寅)
    DiZhi.si: [DiZhi.yin],
    DiZhi.you: [DiZhi.yin],
    DiZhi.chou: [DiZhi.yin],

    // 亥卯未(木绝在申)
    DiZhi.hai: [DiZhi.shen],
    DiZhi.mao: [DiZhi.shen],
    DiZhi.wei: [DiZhi.shen],
  }),

  // -------------------------
  // 1.8 亡神 (Branch -> Branch)
  // 理论来源：“亡在五行临官...申子辰以亥为亡神...寅午戌以巳为亡神...”
  // 规则：三合局五行的临官(禄)地。
  // 查找方式：以年、日支查余三支。
  // -------------------------
  BranchToBranchShenSha('亡神', {
    // 申子辰(水禄在亥)
    DiZhi.shen: [DiZhi.hai],
    DiZhi.zi: [DiZhi.hai],
    DiZhi.chen: [DiZhi.hai],

    // 寅午戌(火禄在巳)
    DiZhi.yin: [DiZhi.si],
    DiZhi.wu: [DiZhi.si],
    DiZhi.xu: [DiZhi.si],

    // 巳酉丑(金禄在申)
    DiZhi.si: [DiZhi.shen],
    DiZhi.you: [DiZhi.shen],
    DiZhi.chou: [DiZhi.shen],

    // 亥卯未(木禄在寅)
    DiZhi.hai: [DiZhi.yin],
    DiZhi.mao: [DiZhi.yin],
    DiZhi.wei: [DiZhi.yin],
  }),

  // -------------------------
  // 1.9 空亡 (Kong Wang)
  // 规则：以日柱（或年柱）查旬空。
  // 方法：调用 GanZhi.getKongWang() 获取空亡地支列表。
  // -------------------------
  KongWangShenSha('空亡'),

  // -------------------------
  // 1.10 天厨贵人 (本旬食神)
  // 规则：四柱中某一柱，必须是“年柱(或日柱)所在旬”中的“食神”干支。
  // -------------------------
  TianChuShenSha('天厨贵人(本旬)'),

  // -------------------------
  // 1.11 天厨贵人 (正宗/食神建禄)
  // 口诀：甲丙爱行双妃(巳)游，乙丁狮子(午)己金牛(酉)，戊坐阴阳(申)庚鱼双(亥)，
  // 癸用天喝(卯)壬人马(寅)，辛到宝瓶(子)禄自由。
  // 规则：食神之禄位。
  // -------------------------
  StemToBranchShenSha('天厨贵人', {
    TianGan.jia: [DiZhi.si], // 食丙禄巳
    TianGan.yi: [DiZhi.wu], // 食丁禄午
    TianGan.bing: [DiZhi.si], // 食戊禄巳
    TianGan.ding: [DiZhi.wu], // 食己禄午
    TianGan.wu: [DiZhi.shen], // 食庚禄申
    TianGan.ji: [DiZhi.you], // 食辛禄酉
    TianGan.geng: [DiZhi.hai], // 食壬禄亥
    TianGan.xin: [DiZhi.zi], // 食癸禄子
    TianGan.ren: [DiZhi.yin], // 食甲禄寅
    TianGan.gui: [DiZhi.mao], // 食乙禄卯
  }),

  // -------------------------
  // 1.12 德秀贵人 (Month Branch -> Stem)
  // 口诀：寅午戌月，丙丁为德，戊癸为秀。申子辰月，壬癸戊己为德，丙辛甲己为秀。
  // 巳酉丑月，庚辛为德，乙庚为秀。亥卯未月，甲乙为德，丁壬为秀。
  // -------------------------
  MonthBranchToStemShenSha(
    '德秀贵人',
    targetStems: {
      // 寅午戌 (火局) -> 丙丁戊癸
      DiZhi.yin: [TianGan.bing, TianGan.ding, TianGan.wu, TianGan.gui],
      DiZhi.wu: [TianGan.bing, TianGan.ding, TianGan.wu, TianGan.gui],
      DiZhi.xu: [TianGan.bing, TianGan.ding, TianGan.wu, TianGan.gui],

      // 申子辰 (水局) -> 壬癸戊己 + 丙辛甲己
      DiZhi.shen: [
        TianGan.ren,
        TianGan.gui,
        TianGan.wu,
        TianGan.ji,
        TianGan.bing,
        TianGan.xin,
        TianGan.jia,
      ],
      DiZhi.zi: [
        TianGan.ren,
        TianGan.gui,
        TianGan.wu,
        TianGan.ji,
        TianGan.bing,
        TianGan.xin,
        TianGan.jia,
      ],
      DiZhi.chen: [
        TianGan.ren,
        TianGan.gui,
        TianGan.wu,
        TianGan.ji,
        TianGan.bing,
        TianGan.xin,
        TianGan.jia,
      ],

      // 巳酉丑 (金局) -> 庚辛 + 乙庚
      DiZhi.si: [TianGan.geng, TianGan.xin, TianGan.yi],
      DiZhi.you: [TianGan.geng, TianGan.xin, TianGan.yi],
      DiZhi.chou: [TianGan.geng, TianGan.xin, TianGan.yi],

      // 亥卯未 (木局) -> 甲乙 + 丁壬
      DiZhi.hai: [TianGan.jia, TianGan.yi, TianGan.ding, TianGan.ren],
      DiZhi.mao: [TianGan.jia, TianGan.yi, TianGan.ding, TianGan.ren],
      DiZhi.wei: [TianGan.jia, TianGan.yi, TianGan.ding, TianGan.ren],
    },
  ),

  // -------------------------
  // 1.13 天医 (Month Branch -> Branch)
  // 口诀：正月见丑，二月见寅...（月建后一位）
  // -------------------------
  TianYiShenSha('天医'),

  // -------------------------
  // 1.13.1 血刃 (Month Branch -> Branch)
  // 口诀：寅月丑，卯月未，辰月寅，巳月申，午月卯，未月酉，
  // 申月辰，酉月戌，戌月巳，亥月亥，子月午，丑月子。
  // -------------------------
  BranchToBranchShenSha(
    '血刃',
    {
      DiZhi.yin: [DiZhi.chou],
      DiZhi.mao: [DiZhi.wei],
      DiZhi.chen: [DiZhi.yin],
      DiZhi.si: [DiZhi.shen],
      DiZhi.wu: [DiZhi.mao],
      DiZhi.wei: [DiZhi.you],
      DiZhi.shen: [DiZhi.chen],
      DiZhi.you: [DiZhi.xu],
      DiZhi.xu: [DiZhi.si],
      DiZhi.hai: [DiZhi.hai],
      DiZhi.zi: [DiZhi.wu],
      DiZhi.chou: [DiZhi.zi],
    },
    baseColumns: [PillarType.month],
  ),

  // -------------------------
  // 1.14 月德合 (Month Branch -> Stem)
  // 口诀：寅午戌月见辛，申子辰月见丁，亥卯未月见己，巳酉丑月见乙。
  // -------------------------
  MonthBranchToStemShenSha(
    '月德合',
    targetStems: {
      // 寅午戌 (火局) -> 月德丙 -> 合辛
      DiZhi.yin: [TianGan.xin],
      DiZhi.wu: [TianGan.xin],
      DiZhi.xu: [TianGan.xin],

      // 申子辰 (水局) -> 月德壬 -> 合丁
      DiZhi.shen: [TianGan.ding],
      DiZhi.zi: [TianGan.ding],
      DiZhi.chen: [TianGan.ding],

      // 亥卯未 (木局) -> 月德甲 -> 合己
      DiZhi.hai: [TianGan.ji],
      DiZhi.mao: [TianGan.ji],
      DiZhi.wei: [TianGan.ji],

      // 巳酉丑 (金局) -> 月德庚 -> 合乙
      DiZhi.si: [TianGan.yi],
      DiZhi.you: [TianGan.yi],
      DiZhi.chou: [TianGan.yi],
    },
  ),

  // -------------------------
  // 1.14.1 勾绞煞 (Gou Jiao Sha)
  // 规则：
  // 阳男阴女：命前三辰为勾，命后三辰为绞。
  // 阴男阳女：命前三辰为绞，命后三辰为勾。
  // 口诀：子见卯、丑见辰...（此为命前三辰，即阳男阴女之勾，阴男阳女之绞）。
  // -------------------------
  GouJiaoShenSha('勾煞', isGou: true),
  GouJiaoShenSha('绞煞', isGou: false),

  // -------------------------
  // 1.14.2 元辰 (大耗)
  // 规则：阳男阴女，冲前一位；阴男阳女，冲后一位。
  // -------------------------
  YuanChenShenSha('元辰'),
  GuChenGuaSuShenSha('孤辰', isGu: true),
  GuChenGuaSuShenSha('寡宿', isGu: false),
  // 1.14.3 红艳煞 (Stem -> Branch)
  // 规则：以日干查四柱地支：甲乙见午；丙见寅；丁见未；戊己见辰；庚见戌；辛见酉；壬见子；癸见申。
  // 常见所见十组合只是其中日柱本身命中的特例表达，真实规则是“日干见某支”。
  StemToBranchShenSha(
    '红艳煞',
    {
      TianGan.jia: [DiZhi.wu],
      TianGan.yi: [DiZhi.wu],
      TianGan.bing: [DiZhi.yin],
      TianGan.ding: [DiZhi.wei],
      TianGan.wu: [DiZhi.chen],
      TianGan.ji: [DiZhi.chen],
      TianGan.geng: [DiZhi.xu],
      TianGan.xin: [DiZhi.you],
      TianGan.ren: [DiZhi.zi],
      TianGan.gui: [DiZhi.shen],
    },
    baseColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.14.4 金舆 (Stem -> Branch)
  // 规则：禄前二辰为金舆。
  // 甲禄在寅，辰为金舆；乙禄在卯，巳为金舆；丙戊禄在巳，未为金舆；
  // 丁己禄在午，申为金舆；庚禄在申，戌为金舆；辛禄在酉，亥为金舆；
  // 壬禄在亥，丑为金舆；癸禄在子，寅为金舆。
  // -------------------------
  StemToBranchShenSha(
    '金舆',
    {
      TianGan.jia: [DiZhi.chen],
      TianGan.yi: [DiZhi.si],
      TianGan.bing: [DiZhi.wei],
      TianGan.wu: [DiZhi.wei],
      TianGan.ding: [DiZhi.shen],
      TianGan.ji: [DiZhi.shen],
      TianGan.geng: [DiZhi.xu],
      TianGan.xin: [DiZhi.hai],
      TianGan.ren: [DiZhi.chou],
      TianGan.gui: [DiZhi.yin],
    },
    baseColumns: [PillarType.day], // 通常以日干查
  ),

  // -------------------------
  // 1.14.5 金神 (Jin Shen)
  // 规则：
  // 1. 日干必须为 甲 或 己。
  // 2. 时柱必须为 癸酉、己巳、乙丑 之一。
  // 3. (格局成败需看火制，此处仅标记神煞)
  // -------------------------
  JinShenShenSha('金神'),

  // -------------------------
  // 1.14.6 天赦 (Tian She)
  // 规则：
  // 春月（寅卯辰）见戊寅日；
  // 夏月（巳午未）见甲午日；
  // 秋月（申酉戌）见戊申日；
  // 冬月（亥子丑）见甲子日。
  // -------------------------
  TianSheShenSha('天赦日'),

  // -------------------------
  // 1.14.7 流霞 (Liu Xia)
  // 规则：
  // 甲酉 乙戌 丙未 丁申 戊巳
  // 己午 庚辰 辛卯 壬亥 癸寅
  // -------------------------
  StemToBranchShenSha(
    '流霞',
    {
      TianGan.jia: [DiZhi.you],
      TianGan.yi: [DiZhi.xu],
      TianGan.bing: [DiZhi.wei],
      TianGan.ding: [DiZhi.shen],
      TianGan.wu: [DiZhi.si],
      TianGan.ji: [DiZhi.wu],
      TianGan.geng: [DiZhi.chen],
      TianGan.xin: [DiZhi.mao],
      TianGan.ren: [DiZhi.hai],
      TianGan.gui: [DiZhi.yin],
    },
    baseColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.14.8 丧门 (Sang Men)
  // 规则：岁前二辰为丧门。
  // 子见寅 丑见卯 寅见辰 卯见巳 辰见午 巳见未
  // 午见申 未见酉 申见戌 酉见亥 戌见子 亥见丑
  // -------------------------
  BranchToBranchShenSha(
    '丧门',
    {
      DiZhi.zi: [DiZhi.yin],
      DiZhi.chou: [DiZhi.mao],
      DiZhi.yin: [DiZhi.chen],
      DiZhi.mao: [DiZhi.si],
      DiZhi.chen: [DiZhi.wu],
      DiZhi.si: [DiZhi.wei],
      DiZhi.wu: [DiZhi.shen],
      DiZhi.wei: [DiZhi.you],
      DiZhi.shen: [DiZhi.xu],
      DiZhi.you: [DiZhi.hai],
      DiZhi.xu: [DiZhi.zi],
      DiZhi.hai: [DiZhi.chou],
    },
    baseColumns: [PillarType.year], // 通常以年支查
  ),

  // -------------------------
  // 1.14.9 吊客 (Diao Ke)
  // 规则：岁后二辰为吊客。
  // 子见戌 丑见亥 寅见子 卯见丑 辰见寅 巳见卯
  // 午见辰 未见巳 申见午 酉见未 戌见申 亥见酉
  // -------------------------
  BranchToBranchShenSha(
    '吊客',
    {
      DiZhi.zi: [DiZhi.xu],
      DiZhi.chou: [DiZhi.hai],
      DiZhi.yin: [DiZhi.zi],
      DiZhi.mao: [DiZhi.chou],
      DiZhi.chen: [DiZhi.yin],
      DiZhi.si: [DiZhi.mao],
      DiZhi.wu: [DiZhi.chen],
      DiZhi.wei: [DiZhi.si],
      DiZhi.shen: [DiZhi.wu],
      DiZhi.you: [DiZhi.wei],
      DiZhi.xu: [DiZhi.shen],
      DiZhi.hai: [DiZhi.you],
    },
    baseColumns: [PillarType.year], // 通常以年支查
  ),

  // -------------------------
  // 1.14.10 披麻 (Pi Ma)
  // 规则：年支后三位为披麻。
  // 子见酉 丑见戌 寅见亥 卯见子 辰见丑 巳见寅
  // 午见卯 未见辰 申见巳 酉见午 戌见未 亥见申
  // -------------------------
  BranchToBranchShenSha(
    '披麻',
    {
      DiZhi.zi: [DiZhi.you],
      DiZhi.chou: [DiZhi.xu],
      DiZhi.yin: [DiZhi.hai],
      DiZhi.mao: [DiZhi.zi],
      DiZhi.chen: [DiZhi.chou],
      DiZhi.si: [DiZhi.yin],
      DiZhi.wu: [DiZhi.mao],
      DiZhi.wei: [DiZhi.chen],
      DiZhi.shen: [DiZhi.si],
      DiZhi.you: [DiZhi.wu],
      DiZhi.xu: [DiZhi.wei],
      DiZhi.hai: [DiZhi.shen],
    },
    baseColumns: [PillarType.year], // 通常以年支查
  ),

  // -------------------------
  // 1.14.11 童子 (Tong Zi)
  // 规则：春秋寅子贵，冬夏卯未辰；
  // 金木午卯合，水火酉戌多；
  // 土命逢辰巳，童子定不错。
  // 解释：
  // 1. 季分法（春秋/冬夏）：
  //    春（寅卯辰）/秋（申酉戌）月 -> 见 寅 或 子
  //    冬（亥子丑）/夏（巳午未）月 -> 见 卯 或 未 或 辰
  // 2. 纳音法（年柱/日柱纳音）：
  //    纳音金/木 -> 见 午 或 卯
  //    纳音水/火 -> 见 酉 或 戌
  //    纳音土    -> 见 辰 或 巳
  // -------------------------
  TongZiShenSha('童子'),

  // -------------------------
  // 1.15 天德合 (Month Branch -> Stem/Branch)
  // 规则：天德的合干/合支。
  // 正寅壬，二卯巳，三辰丁，四巳丙，五午寅，六未己，
  // 七申戊，八酉亥，九戌辛，十亥庚，十一子申，十二丑乙。
  // -------------------------
  TianDeHeShenSha('天德合'),

  // -------------------------
  // 1.17 三奇贵人 (All Stems)
  // 规则：四柱天干中包含特定的三个字。
  // 天上三奇：甲戊庚；地下三奇：乙丙丁；人中三奇：壬癸辛。
  // -------------------------
  SanQiShenSha('三奇贵人(天)', [TianGan.jia, TianGan.wu, TianGan.geng]),
  SanQiShenSha('三奇贵人(地)', [TianGan.yi, TianGan.bing, TianGan.ding]),
  SanQiShenSha('三奇贵人(人)', [TianGan.ren, TianGan.gui, TianGan.xin]),

  // -------------------------
  // 1.18 将星 (Year/Day Branch -> Branch)
  // 规则：三合中位为将星。
  // 申子辰见子，寅午戌见午，巳酉丑见酉，亥卯未见卯。
  // -------------------------
  BranchToBranchShenSha('将星', {
    DiZhi.shen: [DiZhi.zi],
    DiZhi.zi: [DiZhi.zi],
    DiZhi.chen: [DiZhi.zi],
    DiZhi.yin: [DiZhi.wu],
    DiZhi.wu: [DiZhi.wu],
    DiZhi.xu: [DiZhi.wu],
    DiZhi.si: [DiZhi.you],
    DiZhi.you: [DiZhi.you],
    DiZhi.chou: [DiZhi.you],
    DiZhi.hai: [DiZhi.mao],
    DiZhi.mao: [DiZhi.mao],
    DiZhi.wei: [DiZhi.mao],
  }),

  // -------------------------
  // 1.19 华盖 (Year/Day Branch -> Branch)
  // 规则：三合库位为华盖。
  // 申子辰见辰，寅午戌见戌，巳酉丑见丑，亥卯未见未。
  // -------------------------
  BranchToBranchShenSha('华盖', {
    DiZhi.shen: [DiZhi.chen],
    DiZhi.zi: [DiZhi.chen],
    DiZhi.chen: [DiZhi.chen],
    DiZhi.yin: [DiZhi.xu],
    DiZhi.wu: [DiZhi.xu],
    DiZhi.xu: [DiZhi.xu],
    DiZhi.si: [DiZhi.chou],
    DiZhi.you: [DiZhi.chou],
    DiZhi.chou: [DiZhi.chou],
    DiZhi.hai: [DiZhi.wei],
    DiZhi.mao: [DiZhi.wei],
    DiZhi.wei: [DiZhi.wei],
  }),

  // -------------------------
  // 1.20 魁罡 (Day Pillar)
  // 规则：日柱为 庚辰、壬辰、戊戌、庚戌 之一。
  // -------------------------
  PillarShenSha('魁罡', ['庚辰', '壬辰', '戊戌', '庚戌'], validColumns: [PillarType.day]),

  // -------------------------
  // 1.21 十灵日 (Day Pillar)
  // 规则：日柱为 甲辰、乙亥、丙辰、丁酉、戊午、庚戌、庚寅、辛亥、壬寅、癸未 之一。
  // -------------------------
  PillarShenSha(
    '十灵日',
    ['甲辰', '乙亥', '丙辰', '丁酉', '戊午', '庚戌', '庚寅', '辛亥', '壬寅', '癸未'],
    validColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.22 八专日 (Day Pillar)
  // 规则：日柱为 甲寅、乙卯、丁未、戊戌、己未、庚申、辛酉、癸丑 之一。
  // -------------------------
  PillarShenSha(
    '八专日',
    ['甲寅', '乙卯', '丁未', '戊戌', '己未', '庚申', '辛酉', '癸丑'],
    validColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.23 六秀日 (Day Pillar)
  // 规则：日柱为 丙午、丁未、戊子、戊午、己丑、己未 之一。
  // -------------------------
  PillarShenSha(
    '六秀日',
    ['丙午', '丁未', '戊子', '戊午', '己丑', '己未'],
    validColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.24 九丑日 (Day Pillar)
  // 规则：日柱为 丁酉、戊子、戊午、己卯、己酉、辛卯、辛酉、壬子、壬午 之一。
  // -------------------------
  PillarShenSha(
    '九丑日',
    ['丁酉', '戊子', '戊午', '己卯', '己酉', '辛卯', '辛酉', '壬子', '壬午'],
    validColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.25 四废日 (Day Pillar)
  // 规则：
  // 春月（寅卯辰）见 庚申、辛酉；
  // 夏月（巳午未）见 壬子、癸亥；
  // 秋月（申酉戌）见 甲寅、乙卯；
  // 冬月（亥子丑）见 丙午、丁巳。
  // -------------------------
  SiFeiShenSha('四废日'),

  // -------------------------
  // 1.26 十恶大败 (Day Pillar)
  // 规则：日柱为 甲辰、乙巳、丙申、丁亥、戊戌、己丑、庚辰、辛巳、壬申、癸亥 之一。
  // 即禄入空亡。
  // -------------------------
  PillarShenSha(
    '十恶大败',
    ['甲辰', '乙巳', '丙申', '丁亥', '戊戌', '己丑', '庚辰', '辛巳', '壬申', '癸亥'],
    validColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.27 天罗地网
  // 规则：
  // 戌亥为天罗，辰巳为地网。
  // 纳音火命人，男命见戌亥为天罗；
  // 纳音水土命人，女命见辰巳为地网；
  // 金木命人无。
  // -------------------------
  TianLuoDiWangShenSha('天罗地网'),

  // -------------------------
  // 1.28 阴差阳错 (Day Pillar)
  // 规则：日柱为 丙子、丁丑、戊寅、辛卯、壬辰、癸巳、丙午、丁未、戊申、辛酉、壬戌、癸亥 之一。
  // -------------------------
  PillarShenSha(
    '阴差阳错',
    ['丙子', '丁丑', '戊寅', '辛卯', '壬辰', '癸巳', '丙午', '丁未', '戊申', '辛酉', '壬戌', '癸亥'],
    validColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.29 孤鸾煞 (Day Pillar)
  // 规则：日柱为 乙巳、丁巳、辛亥、戊申、甲寅、戊午、壬子、丙午。
  // -------------------------
  PillarShenSha(
    '孤鸾煞',
    ['乙巳', '丁巳', '辛亥', '戊申', '甲寅', '戊午', '壬子', '丙午'],
    validColumns: [PillarType.day],
  ),

  // -------------------------
  // 1.30 拱禄
  // 规则：日时同干，拱夹禄神。
  // 癸亥、癸丑拱子禄；丁巳、丁未拱午禄；己未、己巳拱午禄；戊辰、戊午拱巳禄。
  // -------------------------
  GongLuGongGuiShenSha('拱禄', {
    TianGan.gui: {DiZhi.hai, DiZhi.chou}, // 拱子
    TianGan.ding: {DiZhi.si, DiZhi.wei}, // 拱午
    TianGan.ji: {DiZhi.wei, DiZhi.si}, // 拱午
    TianGan.wu: {DiZhi.chen, DiZhi.wu}, // 拱巳
  }),

  // -------------------------
  // 1.31 拱贵
  // 规则：日时同干，拱夹贵人（天乙贵人或官星贵人）。
  // 甲申、甲戌拱酉（官贵）；乙未、乙酉拱申（官贵）；
  // 甲寅、甲子拱丑（官贵兼天乙）；戊申、戊午拱未（官贵兼天乙）；辛丑、辛卯拱寅（官贵兼天乙）。
  // -------------------------
  GongLuGongGuiShenSha('拱贵', {
    TianGan.jia: {DiZhi.shen, DiZhi.xu, DiZhi.yin, DiZhi.zi}, // 拱酉、拱丑
    TianGan.yi: {DiZhi.wei, DiZhi.you}, // 拱申
    TianGan.wu: {DiZhi.shen, DiZhi.wu}, // 拱未
    TianGan.xin: {DiZhi.chou, DiZhi.mao}, // 拱寅
  }),

  // -------------------------
  // 1.32 地转
  // 规则：
  // 春 (寅卯辰月) 见 辛卯 (辛纳音木，卯为木，专旺于春)
  // 夏 (巳午未月) 见 戊午 (戊纳音火，午为火，专旺于夏)
  // 秋 (申酉戌月) 见 癸酉 (癸纳音金，酉为金，专旺于秋)
  // 冬 (亥子丑月) 见 丙子 (丙纳音水，子为水，专旺于冬)
  // -------------------------
  DiZhuanShenSha('地转'),

  // -------------------------
  // 1.33 天转
  // 规则：
  // 春 (寅卯辰月) 见 乙卯 (天干乙木，地支卯木，专旺于春)
  // 夏 (巳午未月) 见 丙午 (天干丙火，地支午火，专旺于夏)
  // 秋 (申酉戌月) 见 辛酉 (天干辛金，地支酉金，专旺于秋)
  // 冬 (亥子丑月) 见 壬子 (天干壬水，地支子水，专旺于冬)
  // -------------------------
  TianZhuanShenSha('天转'),

  // -------------------------
  // 2. 太极贵人 (Stem -> Branch)
  // 口诀：甲乙生人子午中，丙丁鸡兔定亨通，戊己两干临四季（辰戌丑未），庚辛寅亥禄丰隆，壬癸巳申偏喜美，值此应当福气钟。
  // 以日干和年干查地支。
  // -------------------------
  StemToBranchShenSha('太极贵人', {
    TianGan.jia: [DiZhi.zi, DiZhi.wu],
    TianGan.yi: [DiZhi.zi, DiZhi.wu],
    TianGan.bing: [DiZhi.you, DiZhi.mao],
    TianGan.ding: [DiZhi.you, DiZhi.mao],
    TianGan.wu: [DiZhi.chen, DiZhi.xu, DiZhi.chou, DiZhi.wei],
    TianGan.ji: [DiZhi.chen, DiZhi.xu, DiZhi.chou, DiZhi.wei],
    TianGan.geng: [DiZhi.yin, DiZhi.hai],
    TianGan.xin: [DiZhi.yin, DiZhi.hai],
    TianGan.ren: [DiZhi.si, DiZhi.shen],
    TianGan.gui: [DiZhi.si, DiZhi.shen],
  }),

  // -------------------------
  // 3. 文昌贵人 (Stem -> Branch)
  // 口诀：甲乙巳午报君知，丙戊申宫丁己鸡，庚猪辛鼠壬逢虎，癸人见卯入云梯。
  // 以日干和年干查地支。
  // -------------------------
  StemToBranchShenSha('文昌贵人', {
    TianGan.jia: [DiZhi.si],
    TianGan.yi: [DiZhi.wu],
    TianGan.bing: [DiZhi.shen],
    TianGan.wu: [DiZhi.shen],
    TianGan.ding: [DiZhi.you],
    TianGan.ji: [DiZhi.you],
    TianGan.geng: [DiZhi.hai],
    TianGan.xin: [DiZhi.zi],
    TianGan.ren: [DiZhi.yin],
    TianGan.gui: [DiZhi.mao],
  }),

  // -------------------------
  // 4. 国印贵人 (Stem -> Branch)
  // 口诀：甲见戌，乙见亥，丙见丑，丁见寅，戊见丑，己见寅，庚见辰，辛见巳，壬见未，癸见申。
  // 以日干和年干查地支。
  // -------------------------
  StemToBranchShenSha('国印贵人', {
    TianGan.jia: [DiZhi.xu],
    TianGan.yi: [DiZhi.hai],
    TianGan.bing: [DiZhi.chou],
    TianGan.ding: [DiZhi.yin],
    TianGan.wu: [DiZhi.chou],
    TianGan.ji: [DiZhi.yin],
    TianGan.geng: [DiZhi.chen],
    TianGan.xin: [DiZhi.si],
    TianGan.ren: [DiZhi.wei],
    TianGan.gui: [DiZhi.shen],
  }),

  // -------------------------
  // 5. 天德贵人 (Month Branch -> Stem/Branch)
  // 经典口诀：正丁二申宫，三壬四辛同，五亥六甲上，七癸八寅逢。九丙十归乙，子己丑庚中。
  // -------------------------
  MonthBranchToZhuShenSha(
    '天德贵人',
    targetStems: {
      DiZhi.yin: [TianGan.ding], // 正月(寅)丁
      DiZhi.chen: [TianGan.ren], // 三月(辰)壬
      DiZhi.si: [TianGan.xin], // 四月(巳)辛
      DiZhi.wei: [TianGan.jia], // 六月(未)甲
      DiZhi.shen: [TianGan.gui], // 七月(申)癸
      DiZhi.xu: [TianGan.bing], // 九月(戌)丙
      DiZhi.hai: [TianGan.yi], // 十月(亥)乙
      DiZhi.chou: [TianGan.geng], // 十二月(丑)庚
    },
    targetBranches: {
      DiZhi.mao: [DiZhi.shen], // 二月(卯)申
      DiZhi.wu: [DiZhi.hai], // 五月(午)亥
      DiZhi.you: [DiZhi.yin], // 八月(酉)寅
      DiZhi.zi: [DiZhi.si], // 十一月(子)巳
    },
  ),

  // -------------------------
  // 6. 月德贵人 (Month Branch -> Stem)
  // 口诀：寅午戌月在丙，申子辰月在壬，亥卯未月在甲，巳酉丑月在庚。
  // -------------------------
  MonthBranchToZhuShenSha(
    '月德贵人',
    targetStems: {
      DiZhi.yin: [TianGan.bing],
      DiZhi.wu: [TianGan.bing],
      DiZhi.xu: [TianGan.bing],
      DiZhi.shen: [TianGan.ren],
      DiZhi.zi: [TianGan.ren],
      DiZhi.chen: [TianGan.ren],
      DiZhi.hai: [TianGan.jia],
      DiZhi.mao: [TianGan.jia],
      DiZhi.wei: [TianGan.jia],
      DiZhi.si: [TianGan.geng],
      DiZhi.you: [TianGan.geng],
      DiZhi.chou: [TianGan.geng],
    },
  ),

  // -------------------------
  // 7. 禄神 (建禄) (Stem -> Branch)
  // 口诀：甲禄在寅，乙禄在卯，丙戊禄在巳，丁己禄在午，庚禄在申，辛禄在酉，壬禄在亥，癸禄在子。
  // -------------------------
  StemToBranchShenSha(
    '禄神',
    {
      TianGan.jia: [DiZhi.yin],
      TianGan.yi: [DiZhi.mao],
      TianGan.bing: [DiZhi.si],
      TianGan.ding: [DiZhi.wu],
      TianGan.wu: [DiZhi.si],
      TianGan.ji: [DiZhi.wu],
      TianGan.geng: [DiZhi.shen],
      TianGan.xin: [DiZhi.you],
      TianGan.ren: [DiZhi.hai],
      TianGan.gui: [DiZhi.zi],
    },
    baseColumns: [PillarType.day],
  ),

  // ===========================================
  // 古法学堂词馆系列 (替代原有的通用版)
  // ===========================================

  // 8. 日干学堂 (原通用版学堂，为了兼容性保留并改名，或者直接替换。这里作为补充存在)
  // 许多现代派别仍用此法。
  StemToBranchShenSha(
    '日干学堂',
    {
      TianGan.jia: [DiZhi.hai],
      TianGan.yi: [DiZhi.wu],
      TianGan.bing: [DiZhi.yin],
      TianGan.ding: [DiZhi.you],
      TianGan.wu: [DiZhi.yin],
      TianGan.ji: [DiZhi.you],
      TianGan.geng: [DiZhi.si],
      TianGan.xin: [DiZhi.zi],
      TianGan.ren: [DiZhi.shen],
      TianGan.gui: [DiZhi.mao],
    },
    baseColumns: [PillarType.day],
  ),

  // 9. 日干词馆 (原通用版词馆)
  StemToBranchShenSha(
    '日干词馆',
    {
      TianGan.jia: [DiZhi.yin],
      TianGan.yi: [DiZhi.mao],
      TianGan.bing: [DiZhi.si],
      TianGan.ding: [DiZhi.wu],
      TianGan.wu: [DiZhi.si],
      TianGan.ji: [DiZhi.wu],
      TianGan.geng: [DiZhi.shen],
      TianGan.xin: [DiZhi.you],
      TianGan.ren: [DiZhi.hai],
      TianGan.gui: [DiZhi.zi],
    },
    baseColumns: [PillarType.day],
  ),

  // 10. 正学堂 (纳音)
  // “夫学堂者，如人读书之在学堂...如金命见辛巳”
  // 口诀：金命见巳，辛巳为正；木命见亥，己亥为正；水命见申，甲申为正；土命见申，戊申为正；火命见寅，丙寅为正。
  // 查找方式：纳音查法和子平法（需纳音五行相同且坐长生）。
  NayinShenSha('正学堂', isZhangSheng: true),

  // 11. 正词馆 (纳音)
  // “词馆者，如今官翰林...如金命壬申”
  NayinShenSha('正词馆', isZhangSheng: false),

  // 12. 官贵学堂
  // “以官贵长生之位为学堂”
  OfficialShenSha('官贵学堂', isZhangSheng: true),

  // 13. 官贵词馆
  // “官贵临官之位为词馆也”
  OfficialShenSha('官贵词馆', isZhangSheng: false),

  // 15. 官星学堂
  // “有生处见克...谓之官星学堂”
  OfficialStarShenSha('官星学堂'),

  // 16. 学堂会贵
  // “有纳音见帝旺之位而逢天乙贵处其上”
  NayinNobleShenSha('学堂会贵'),
];

/// 【勾绞煞】
/// 规则：
/// 阳男阴女：命前三辰为勾，命后三辰为绞。
/// 阴男阳女：命前三辰为绞，命后三辰为勾。
class GouJiaoShenSha extends ShenSha {
  final bool isGou;
  const GouJiaoShenSha(String name, {required this.isGou}) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 1. 获取年干和年支
    final yearGan = bz.bazi.year.gan;
    final yearZhi = bz.bazi.year.zhi;

    // 2. 判断年干阴阳 (0:甲 阳, 1:乙 阴...)
    final isYearYang = yearGan.index % 2 == 0;

    // 3. 判断性别
    final isMale = bz.gender == Gender.male;

    // 4. 判断顺逆
    // 阳男(T,T) -> 顺(T)
    // 阴女(F,F) -> 顺(T)
    // 阴男(T,F) -> 逆(F)
    // 阳女(F,T) -> 逆(F)
    // 顺：前勾后绞
    // 逆：前绞后勾
    final isForward = (isMale == isYearYang);

    // 5. 计算目标地支
    // 命前三辰 (+3)
    final forwardInd = (yearZhi.index + 3) % 12;
    // 命后三辰 (-3)
    final backwardInd = (yearZhi.index - 3 + 12) % 12;

    int targetInd;
    if (isGou) {
      // 找勾煞
      // 顺：前为勾；逆：后为勾
      targetInd = isForward ? forwardInd : backwardInd;
    } else {
      // 找绞煞
      // 顺：后为绞；逆：前为绞
      targetInd = isForward ? backwardInd : forwardInd;
    }

    return gz.zhi.index == targetInd;
  }
}

/// 【元辰】 (大耗)
/// 规则：
/// 阳男阴女：冲前一位（即对冲地支 + 1）。
/// 阴男阳女：冲后一位（即对冲地支 - 1）。
/// 例：甲子(阳)男，冲午，午前一位为未。
/// 例：乙丑(阴)男，冲未，未后一位为午。
class YuanChenShenSha extends ShenSha {
  const YuanChenShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final yearGan = bz.bazi.year.gan;
    final yearZhi = bz.bazi.year.zhi;

    // 1. 计算对冲地支 (六冲)
    final chongIndex = (yearZhi.index + 6) % 12;

    // 2. 判断年干阴阳
    final isYearYang = yearGan.index % 2 == 0;

    // 3. 判断性别
    final isMale = bz.gender == Gender.male;

    // 4. 判断顺逆 (阳男阴女为顺，阴男阳女为逆)
    final isForward = (isMale == isYearYang);

    // 5. 计算元辰位置
    int targetIndex;
    if (isForward) {
      // 冲前一位 (顺行+1)
      targetIndex = (chongIndex + 1) % 12;
    } else {
      // 冲后一位 (逆行-1)
      targetIndex = (chongIndex - 1 + 12) % 12;
    }

    return gz.zhi.index == targetIndex;
  }
}

class GuChenGuaSuShenSha extends ShenSha {
  final bool isGu;
  const GuChenGuaSuShenSha(String name, {required this.isGu}) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    final yz = bz.bazi.year.zhi;
    DiZhi gu;
    DiZhi gua;
    if (yz == DiZhi.hai || yz == DiZhi.zi || yz == DiZhi.chou) {
      gu = DiZhi.yin;
      gua = DiZhi.xu;
    } else if (yz == DiZhi.yin || yz == DiZhi.mao || yz == DiZhi.chen) {
      gu = DiZhi.si;
      gua = DiZhi.chou;
    } else if (yz == DiZhi.si || yz == DiZhi.wu || yz == DiZhi.wei) {
      gu = DiZhi.shen;
      gua = DiZhi.chen;
    } else {
      gu = DiZhi.hai;
      gua = DiZhi.wei;
    }
    return gz.zhi == (isGu ? gu : gua);
  }
}

/// 【金神】
/// 规则：
/// 1. 仅限时柱。
/// 2. 日干必须为 甲 或 己。
/// 3. 时柱必须为 癸酉、己巳、乙丑 之一。
class JinShenShenSha extends ShenSha {
  const JinShenShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 1. 仅限时柱
    if (targetType != PillarType.hour) return false;

    // 2. 检查日干
    final dayGan = bz.bazi.day.gan;
    if (dayGan != TianGan.jia && dayGan != TianGan.ji) {
      return false;
    }

    // 3. 检查时柱是否为“金神三时”
    // 癸酉 (Gui-You), 己巳 (Ji-Si), 乙丑 (Yi-Chou)
    if (gz.gan == TianGan.gui && gz.zhi == DiZhi.you) return true;
    if (gz.gan == TianGan.ji && gz.zhi == DiZhi.si) return true;
    if (gz.gan == TianGan.yi && gz.zhi == DiZhi.chou) return true;

    return false;
  }
}

/// 【四废日】
/// 规则：
/// 春月（寅卯辰）见 庚申、辛酉；
/// 夏月（巳午未）见 壬子、癸亥；
/// 秋月（申酉戌）见 甲寅、乙卯；
/// 冬月（亥子丑）见 丙午、丁巳。
class SiFeiShenSha extends ShenSha {
  const SiFeiShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 仅查日柱
    if (targetType != PillarType.day) return false;

    final monthZhi = bz.bazi.month.zhi;
    final dayStr = gz.toString();

    // 春 (寅卯辰) -> 金 (庚申, 辛酉)
    if ([DiZhi.yin, DiZhi.mao, DiZhi.chen].contains(monthZhi)) {
      return ['庚申', '辛酉'].contains(dayStr);
    }

    // 夏 (巳午未) -> 水 (壬子, 癸亥)
    if ([DiZhi.si, DiZhi.wu, DiZhi.wei].contains(monthZhi)) {
      return ['壬子', '癸亥'].contains(dayStr);
    }

    // 秋 (申酉戌) -> 木 (甲寅, 乙卯)
    if ([DiZhi.shen, DiZhi.you, DiZhi.xu].contains(monthZhi)) {
      return ['甲寅', '乙卯'].contains(dayStr);
    }

    // 冬 (亥子丑) -> 火 (丙午, 丁巳)
    if ([DiZhi.hai, DiZhi.zi, DiZhi.chou].contains(monthZhi)) {
      return ['丙午', '丁巳'].contains(dayStr);
    }

    return false;
  }
}

/// 【天赦】
/// 规则：
/// 春月（寅卯辰）见戊寅日；
/// 夏月（巳午未）见甲午日；
/// 秋月（申酉戌）见戊申日；
/// 冬月（亥子丑）见甲子日。
class TianSheShenSha extends ShenSha {
  const TianSheShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 仅在日柱判定
    if (targetType != PillarType.day) return false;

    final mz = bz.bazi.month.zhi;
    final dayGan = gz.gan;
    final dayZhi = gz.zhi;

    // 春 (寅卯辰) -> 戊寅
    if (mz == DiZhi.yin || mz == DiZhi.mao || mz == DiZhi.chen) {
      return dayGan == TianGan.wu && dayZhi == DiZhi.yin;
    }

    // 夏 (巳午未) -> 甲午
    if (mz == DiZhi.si || mz == DiZhi.wu || mz == DiZhi.wei) {
      return dayGan == TianGan.jia && dayZhi == DiZhi.wu;
    }

    // 秋 (申酉戌) -> 戊申
    if (mz == DiZhi.shen || mz == DiZhi.you || mz == DiZhi.xu) {
      return dayGan == TianGan.wu && dayZhi == DiZhi.shen;
    }

    // 冬 (亥子丑) -> 甲子
    if (mz == DiZhi.hai || mz == DiZhi.zi || mz == DiZhi.chou) {
      return dayGan == TianGan.jia && dayZhi == DiZhi.zi;
    }

    return false;
  }
}

/// 【天罗地网】
/// 规则：
/// 戌亥为天罗，辰巳为地网。
/// 纳音火命人，男命见戌亥为天罗；
/// 纳音水土命人，女命见辰巳为地网；
/// 金木命人无。
class TianLuoDiWangShenSha extends ShenSha {
  const TianLuoDiWangShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 1. 纳音限制
    // 金木二命无之。
    final nayin = NayinHelper.getNayinWuXing(bz.bazi.year);
    if (nayin == WuXing.metal || nayin == WuXing.wood) {
      return false;
    }

    final zhi = gz.zhi;
    // 仅在戌亥、辰巳柱上检查
    if (![DiZhi.xu, DiZhi.hai, DiZhi.chen, DiZhi.si].contains(zhi)) {
      return false;
    }

    final isMale = bz.gender == Gender.male;

    // 获取局中所有地支（包括自身）
    // BaZi没有pillars属性，手动构造
    final chartBranches = {
      bz.bazi.year.zhi,
      bz.bazi.month.zhi,
      bz.bazi.day.zhi,
      bz.bazi.time.zhi,
    };

    // 如果当前是在大运或流年检查，且自身不在原局中，需考虑自身
    // check函数通常只判断当前gz是否符合神煞条件，这里我们判断gz是否构成神煞的一部分
    // 需配合原局中是否有另一半

    // 2. 天罗 (戌亥)
    // 条件：火命人 + 男命 + (戌 & 亥)
    if (nayin == WuXing.fire && isMale) {
      if (zhi == DiZhi.xu || zhi == DiZhi.hai) {
        // 需见另一半
        // 若当前是戌，需见亥；若当前是亥，需见戌
        final other = (zhi == DiZhi.xu) ? DiZhi.hai : DiZhi.xu;
        // 检查原局是否有另一半，或者当前gz本身就是另一半（如果是流年大运的情况，需结合上下文，但这里check只看静态+gz）
        // 简单逻辑：原局有other，则当前zhi构成天罗
        return chartBranches.contains(other);
      }
    }

    // 3. 地网 (辰巳)
    // 条件：水土命人 + 女命 + (辰 & 巳)
    if ((nayin == WuXing.water || nayin == WuXing.earth) && !isMale) {
      if (zhi == DiZhi.chen || zhi == DiZhi.si) {
        // 需见另一半
        final other = (zhi == DiZhi.chen) ? DiZhi.si : DiZhi.chen;
        return chartBranches.contains(other);
      }
    }

    return false;
  }
}

/// 【拱禄/拱贵】
/// 规则：
/// 1. 日时同干。
/// 2. 日时地支拱夹出禄神或贵人。
/// 3. 填实则凶（本实现仅检测结构，不判断填实吉凶，但通常填实不入格或为凶）。
class GongLuGongGuiShenSha extends ShenSha {
  final Map<TianGan, Set<DiZhi>> combinations;

  const GongLuGongGuiShenSha(String name, this.combinations) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 仅在日柱显示（代表日时关系）
    if (targetType != PillarType.day) {
      return false;
    }

    // 1. 日时同干
    final dayGan = bz.bazi.day.gan;
    final timeGan = bz.bazi.time.gan;
    if (dayGan != timeGan) {
      return false;
    }

    // 2. 检查天干是否在定义中
    if (!combinations.containsKey(dayGan)) {
      return false;
    }

    final dayZhi = bz.bazi.day.zhi;
    final timeZhi = bz.bazi.time.zhi;
    final validZhis = combinations[dayGan]!;

    // 3. 检查日时地支是否都在集合中
    // 并且两者不相同（必须是拱夹，如果是同一个字，不算拱，或者算伏吟）
    // 古籍例子都是不同的字：癸亥、癸丑；丁巳、丁未。
    if (dayZhi == timeZhi) {
      return false;
    }

    // 特殊处理：甲干有两组 (申戌拱酉, 寅子拱丑)
    if (dayGan == TianGan.jia) {
      // 组1：申、戌
      if ((dayZhi == DiZhi.shen && timeZhi == DiZhi.xu) ||
          (dayZhi == DiZhi.xu && timeZhi == DiZhi.shen)) {
        return true;
      }
      // 组2：寅、子
      if ((dayZhi == DiZhi.yin && timeZhi == DiZhi.zi) ||
          (dayZhi == DiZhi.zi && timeZhi == DiZhi.yin)) {
        return true;
      }
      return false;
    }

    // 其他天干只有一组
    // 必须两个地支都在集合中
    // 注意：combinations value 是 Set，只要两个都在即可
    if (validZhis.contains(dayZhi) && validZhis.contains(timeZhi)) {
      return true;
    }

    return false;
  }
}

/// 【地转】
/// 规则：
/// 春 (寅卯辰月) 见 辛卯 (辛卯纳音松柏木，卯为木，专旺于春)
/// 夏 (巳午未月) 见 戊午 (戊午纳音天上火，午为火，专旺于夏)
/// 秋 (申酉戌月) 见 癸酉 (癸酉纳音剑锋金，酉为金，专旺于秋)
/// 冬 (亥子丑月) 见 丙子 (丙子纳音涧下水，子为水，专旺于冬)
///
/// 注：也有说法是“天转”是干支纳音同旺于季，“地转”是纳音与地支同旺于季。
/// 春：辛卯（纳音木，地支木）
/// 夏：戊午（纳音火，地支火）
/// 秋：癸酉（纳音金，地支金）
/// 冬：丙子（纳音水，地支水）
class DiZhuanShenSha extends ShenSha {
  const DiZhuanShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 通常在日柱查，也有在时柱查的，这里不限制柱类型，只要出现就算
    // 但通常是日主

    final mz = bz.bazi.month.zhi;
    final gzStr = gz.toString();

    // 春
    if (mz == DiZhi.yin || mz == DiZhi.mao || mz == DiZhi.chen) {
      return gzStr == '辛卯';
    }
    // 夏
    if (mz == DiZhi.si || mz == DiZhi.wu || mz == DiZhi.wei) {
      return gzStr == '戊午';
    }
    // 秋
    if (mz == DiZhi.shen || mz == DiZhi.you || mz == DiZhi.xu) {
      return gzStr == '癸酉';
    }
    // 冬
    if (mz == DiZhi.hai || mz == DiZhi.zi || mz == DiZhi.chou) {
      return gzStr == '丙子';
    }

    return false;
  }
}

/// 【天转】
/// 规则：
/// 春 (寅卯辰月) 见 乙卯 (天干乙木，地支卯木，专旺于春)
/// 夏 (巳午未月) 见 丙午 (天干丙火，地支午火，专旺于夏)
/// 秋 (申酉戌月) 见 辛酉 (天干辛金，地支酉金，专旺于秋)
/// 冬 (亥子丑月) 见 壬子 (天干壬水，地支子水，专旺于冬)
///
/// 注：天转是指干支同旺于季。
class TianZhuanShenSha extends ShenSha {
  const TianZhuanShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 通常在日柱查，也有在时柱查的

    final mz = bz.bazi.month.zhi;
    final gzStr = gz.toString();

    // 春
    if (mz == DiZhi.yin || mz == DiZhi.mao || mz == DiZhi.chen) {
      return gzStr == '乙卯';
    }
    // 夏
    if (mz == DiZhi.si || mz == DiZhi.wu || mz == DiZhi.wei) {
      return gzStr == '丙午';
    }
    // 秋
    if (mz == DiZhi.shen || mz == DiZhi.you || mz == DiZhi.xu) {
      return gzStr == '辛酉';
    }
    // 冬
    if (mz == DiZhi.hai || mz == DiZhi.zi || mz == DiZhi.chou) {
      return gzStr == '壬子';
    }

    return false;
  }
}

/// 【童子】
/// 规则：
/// 1. 春秋寅子贵：春（寅卯辰）秋（申酉戌）月生人，见寅或子。
/// 2. 冬夏卯未辰：冬（亥子丑）夏（巳午未）月生人，见卯或未或辰。
/// 3. 金木午卯合：纳音五行金、木者，见午或卯。
/// 4. 水火酉戌多：纳音五行水、火者，见酉或戌。
/// 5. 土命逢辰巳：纳音五行土者，见辰或巳。
/// 注：通常以时支为主，日支次之。
class TongZiShenSha extends ShenSha {
  const TongZiShenSha(String name) : super(name);

  @override
  bool check(BaziChart bz, GanZhi gz, PillarType targetType) {
    // 仅在日支、时支查童子
    if (targetType != PillarType.day && targetType != PillarType.hour) {
      return false;
    }

    final mz = bz.bazi.month.zhi;
    final zhi = gz.zhi;

    // ---------------------
    // 1. 按季节查（口诀：春秋寅子贵，冬夏卯未辰）
    // ---------------------
    // 春 (寅卯辰) / 秋 (申酉戌)
    bool isSpring = mz == DiZhi.yin || mz == DiZhi.mao || mz == DiZhi.chen;
    bool isAutumn = mz == DiZhi.shen || mz == DiZhi.you || mz == DiZhi.xu;

    if (isSpring || isAutumn) {
      if (zhi == DiZhi.yin || zhi == DiZhi.zi) return true;
    }

    // 冬 (亥子丑) / 夏 (巳午未)
    bool isWinter = mz == DiZhi.hai || mz == DiZhi.zi || mz == DiZhi.chou;
    bool isSummer = mz == DiZhi.si || mz == DiZhi.wu || mz == DiZhi.wei;

    if (isWinter || isSummer) {
      if (zhi == DiZhi.mao || zhi == DiZhi.wei || zhi == DiZhi.chen) {
        return true;
      }
    }

    // ---------------------
    // 2. 按纳音查（口诀：金木午卯合，水火酉戌多，土命逢辰巳）
    // ---------------------
    // 命主纳音：通常取年柱纳音，也有兼看日柱纳音。这里取年柱纳音。
    final wuxing = NayinHelper.getNayinWuXing(bz.bazi.year);

    if (wuxing == WuXing.metal || wuxing == WuXing.wood) {
      if (zhi == DiZhi.wu || zhi == DiZhi.mao) return true;
    }

    if (wuxing == WuXing.water || wuxing == WuXing.fire) {
      if (zhi == DiZhi.you || zhi == DiZhi.xu) return true;
    }

    if (wuxing == WuXing.earth) {
      if (zhi == DiZhi.chen || zhi == DiZhi.si) return true;
    }

    return false;
  }
}



// ============================================================================
// EOF 开发者附言 (Developer's Note)
// ============================================================================
// 感谢您阅读至此。作为开发者，在完成本模块的编写后，
// 留下一些关于这套系统的客观思考：
// 
// 1. 本文件收录的众多神煞（如天罗地网、十恶大败、孤鸾等），在底层逻辑的梳理过程中
//    被证明更多是古代命理学在不同历史时期的经验主义产物，甚至包含大量为了迎合
//    古代世俗心理而生造的标签，缺乏严密的推演基石。
// 
// 2. 传统命理学的周边生态存在诸多难以自洽的逻辑冲突。例如传统的纳音系统中，
//    将纯火之极的“丙午”强行定义为“天河水”，这在基础的五行生克架构上是完全悖逆的。
// 
// 3. 在用现代软件工程视角剖析了整套排盘与五行算法后，可以清晰地得出结论：
//    八字体系根本不存在所谓的“玄学魔法”或“天机”。剥开其神秘主义的外衣，
//    它的底层核心仅仅是一个基于 10 与 12 最小公倍数（60进制）的循环日历算法，
//    其外层包裹的，则是古人受限于时代认知所构建的社会期望与心理学映射模型。
// 
// 总结：
// 编写此库旨在以现代软件工程的范式，客观还原并归档这一传统的文化模型。
// 建议各位开发者及使用者，将其视为一项民俗文化研究工具或排盘 UI 引擎，切勿以此断定人生。
// 
// 命运的算法，终究运行在我们自己的行动之中。
//
// https://github.com/RedSC1
// ============================================================================
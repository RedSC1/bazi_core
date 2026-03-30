import 'package:bazi_core/src/astronomy/time_adapter.dart';
import 'package:bazi_core/src/models/bazi_table.dart';
import 'package:bazi_core/src/models/enums.dart';
import 'package:bazi_core/src/models/interaction_calculator.dart';
import 'package:bazi_core/src/models/si_ling.dart';
import 'package:bazi_core/src/models/extra_pillars_config.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

class BaziChart {
  TimePack time;
  BaZi bazi;
  LunarDate lunarDate;
  Gender gender;

  /// 命宫
  late final GanZhi mingGong;

  /// 身宫
  late final GanZhi shenGong;

  /// 胎元
  late final GanZhi taiYuan;

  /// 胎息
  late final GanZhi taiXi;

  /// 人元司令
  late final SiLingResult? siLing;

  BaziChart(
    this.time,
    this.bazi,
    this.lunarDate,
    this.gender, {
    SiLingVersion siLingVersion = SiLingVersion.sanMingTongHui,
  }) {
    mingGong = _calculateMingGong();
    shenGong = _calculateShenGong();
    taiYuan = _calculateTaiYuan();
    taiXi = _calculateTaiXi();
    siLing = SiLing.calculate(
      time.bjClt,
      bazi.month.zhi,
      version: siLingVersion,
    );
  }

  //沟槽的ai幻觉，我改了一上午，就因为有个ai说这个玩意要看中气换月
  //我也不知道这说法哪来的，反正我查了三命通会，没这说法，有知道的能说一下吗？？
  //跟别的排盘软件对比了，反正他们应该都不是原文我贴下面了
  /**
 * 命宫推算逻辑 (原典出处)
 * * [总则]
 * 神无庙无所归，人无室无所栖，命无宫无所主，故有命宫之说。
 * 不然，流年星辰为凶为吉，以何凭据？
 * 此法看是何月生人，坐于何时，然后方定命坐何宫。
 * * [步骤一：月将逆推] 
 * 先将所生之月，从子上起：
 * 正月亥上，二月戌三、酉四、申五、未六、午七、巳八、辰九、卯十、寅十一、丑十二，逆行十二位。
 * (注：即以子位作为起点，逆时针数到出生之月，定位“月将”)
 * * [步骤二：时辰顺推，逢卯安命]
 * 次将所生之时，加于所生之月，顺行十二位，逢卯即安命宫。
 * 经云：天轮转出地轮上，卯上分明是命宫是也。
 * (注：将出生时辰的对应地支，放在上一步求出的“月将”位置上，顺时针数，数到地支“卯”所在的位置，该位置的静态地支即为命宫)
 * * [案例推演]
 * 假令甲子年三月生人，得戌时生：
 * 1. 却将正月加子，二月在亥，三月在戌为止 (求月将：三月在戌)
 * 2. 又将戌时加在戌上，亥上亥，子上子，丑上丑，寅上寅，卯上卯，逢卯便是，即命坐卯宫是也。(顺推求宫)
 * * [步骤三：五虎遁起天干]
 * 仍随甲子年起，亦如起月之法。
 * 甲己之年丙作首，乃丁卯宫也。
 * (注：以年干起五虎遁，推算命宫的天干)
 * * [应用]
 * 次看三方并本命流干犯何星凶吉推之。
 */

  /// 计算命宫
  /// 算法来源：《三命通会》
  GanZhi _calculateMingGong() {
    final m = bazi.month.zhi.index; // 八字月支 (0-based)
    final h = bazi.time.zhi.index; // 八字时支 (0-based)

    // 月序号：寅=1(正月), 卯=2(二月) ... 丑=12(十二月)
    final monthNum = (m - 2 + 12) % 12 + 1;

    // 步骤一：从子上起正月，逆行至生月
    // 正月在子(0)，二月在亥(11)，三月在戌(10)...
    final monthPos = (0 - (monthNum - 1) + 12) % 12;

    // 步骤二：将生时加于月将位，顺行至卯(3)，逢卯即安命宫
    final branchIndex = (monthPos + (3 - h + 12) % 12) % 12;

    // 步骤三：五虎遁起天干
    final stem = _calculateStemForGong(branchIndex);
    return GanZhi(stem, DiZhi.values[branchIndex]);
  }

  /// 计算身宫
  // 这个公式我不知道是哪里来的。。反正跟别的八字软件一样。。
  // 这个身宫目前我没有找到就讲这个的古书的原文
  // 神奇小口诀
  GanZhi _calculateShenGong() {
    final m = bazi.month.zhi.index; // 八字月支 (0-based)
    final h = bazi.time.zhi.index; // 八字时支 (0-based)

    // 身宫公式：(m + h + 1) % 12
    final branchIndex = (m + h + 1) % 12;

    // 五虎遁起天干
    final stem = _calculateStemForGong(branchIndex);
    return GanZhi(stem, DiZhi.values[branchIndex]);
  }

  /// 计算胎元
  GanZhi _calculateTaiYuan() {
    // 胎元：月干后一位，月支后三位
    // 在六十甲子序列中，相当于月柱 - 9
    return bazi.month - 9;
  }

  /// 计算胎息
  GanZhi _calculateTaiXi() {
    // 胎息：日柱的天干五合与地支六合
    final stem = BaziTable.getStemCombinationPartner(bazi.day.gan);
    final branch = BaziTable.getBranchCombinationPartner(bazi.day.zhi);
    return GanZhi(stem, branch);
  }

  /// 根据五虎遁推算宫位天干
  TianGan _calculateStemForGong(int branchIndex) {
    // 五虎遁年上起月法（也适用于命宫/身宫）
    // 甲己之年丙作首 -> 甲(0)/己(5) -> 丙(2) (丙寅)
    // 年干 index % 5 * 2 + 2 = 寅月天干
    final yearStemIndex = bazi.year.gan.index;
    final startStemIndex = (yearStemIndex % 5) * 2 + 2;

    // 寅的 index 是 2
    // 偏移量 = 目标地支 - 寅（必须顺推，用 mod 12 保证非负）
    final offset = (branchIndex - 2 + 12) % 12;

    var stemIndex = (startStemIndex + offset) % 10;
    if (stemIndex < 0) stemIndex += 10;

    return TianGan.values[stemIndex];
  }

  factory BaziChart.createBySolarDate({
    required AstroDateTime clockTime,
    Location location = defaultLoc,
    double timeZone = 8,
    RatHourMode ratHourMode = RatHourMode.noSplit, // 默认不分(即23点换日)，可配置
    bool useTrueSolarTime = true, // 默认使用真太阳时
    Gender gender = Gender.male,
  }) {
    TimePack timepack = TimePack.createBySolarTime(
      clockTime: clockTime,
      location: defaultLoc,
      timezone: timeZone,
      ratHourMode: ratHourMode,
      useTrueSolarTime: useTrueSolarTime,
    );
    BaZi bz = TimeAdaptor.fromSolar(timepack);
    LunarDate ld = LunarDate.fromSolar(
      timepack.bjClt,
      ratHourMode: ratHourMode,
    );
    return BaziChart(timepack, bz, ld, gender);
  }
  factory BaziChart.createByLunarDate({
    required int year,
    required String monthName,
    required int day,
    required int hour,
    required int minute,
    int second = 0,
    bool? isleap,
    Location location = defaultLoc,
    double timeZone = 8,
    RatHourMode ratHourMode = RatHourMode.noSplit, // 默认不分(即23点换日)，可配置
    bool useTrueSolarTime = true, // 默认使用真太阳时
    Gender gender = Gender.male,
  }) {
    final lunarDate = LunarDate.fromString(
      year,
      monthName,
      day,
      isLeap: isleap,
    );
    AstroDateTime temp = lunarDate.toSolar;
    final clockTime = AstroDateTime(
      temp.year,
      temp.month,
      temp.day,
      hour,
      minute,
      second,
    );
    final tp = TimePack.createBySolarTime(
      clockTime: clockTime,
      timezone: timeZone,
      location: location,
      ratHourMode: ratHourMode,
      useTrueSolarTime: useTrueSolarTime,
    );
    final bz = TimeAdaptor.fromSolar(tp);
    return BaziChart(tp, bz, lunarDate, gender);
  }

  /// 获取八字原局内部的所有干支感应 (刑冲合害等)
  List<InteractionResult> getAllInteractions({
    ExtraPillarsConfig extraPillars = const ExtraPillarsConfig(),
  }) {
    return getInteractionsWith(extraPillars: extraPillars);
  }

  /// 获取八字原局与外部（如大运、流年）组合后的所有感应
  ///
  /// [otherStems] 和 [otherBranches] 允许传入额外的干支节点进行池化扫描
  List<InteractionResult> getInteractionsWith({
    List<InteractionNode<TianGan>> otherStems = const [],
    List<InteractionNode<DiZhi>> otherBranches = const [],
    ExtraPillarsConfig extraPillars = const ExtraPillarsConfig(),
  }) {
    // 1. 构建天干池 (原局四柱 + 外部传入)
    final List<InteractionNode<TianGan>> stemPool = [
      InteractionNode(PillarType.year, bazi.year.gan),
      InteractionNode(PillarType.month, bazi.month.gan),
      InteractionNode(PillarType.day, bazi.day.gan),
      InteractionNode(PillarType.hour, bazi.time.gan),
      ...otherStems,
    ];

    if (extraPillars.enableMingGong) {
      stemPool.add(InteractionNode(PillarType.mingGong, mingGong.gan));
    }
    if (extraPillars.enableShenGong) {
      stemPool.add(InteractionNode(PillarType.shenGong, shenGong.gan));
    }
    if (extraPillars.enableTaiYuan) {
      stemPool.add(InteractionNode(PillarType.taiYuan, taiYuan.gan));
    }
    if (extraPillars.enableTaiXi) {
      stemPool.add(InteractionNode(PillarType.taiXi, taiXi.gan));
    }

    // 2. 构建地支池 (原局四柱 + 外部传入)
    final List<InteractionNode<DiZhi>> branchPool = [
      InteractionNode(PillarType.year, bazi.year.zhi),
      InteractionNode(PillarType.month, bazi.month.zhi),
      InteractionNode(PillarType.day, bazi.day.zhi),
      InteractionNode(PillarType.hour, bazi.time.zhi),
      ...otherBranches,
    ];

    if (extraPillars.enableMingGong) {
      branchPool.add(InteractionNode(PillarType.mingGong, mingGong.zhi));
    }
    if (extraPillars.enableShenGong) {
      branchPool.add(InteractionNode(PillarType.shenGong, shenGong.zhi));
    }
    if (extraPillars.enableTaiYuan) {
      branchPool.add(InteractionNode(PillarType.taiYuan, taiYuan.zhi));
    }
    if (extraPillars.enableTaiXi) {
      branchPool.add(InteractionNode(PillarType.taiXi, taiXi.zhi));
    }

    // 3. 执行计算
    final List<InteractionResult> results = [];
    results.addAll(
      BaziInteractionCalculator.calculateStemInteractions(stemPool),
    );
    results.addAll(
      BaziInteractionCalculator.calculateBranchInteractions(branchPool),
    );

    return results;
  }
}

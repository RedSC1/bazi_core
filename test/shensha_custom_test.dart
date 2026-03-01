import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

// Helper to create GanZhi from string
GanZhi gz(String s) {
  return GanZhi(TianGan.fromName(s[0]), DiZhi.fromName(s[1]));
}

// Helper to create BaziChart with manual pillars
BaziChart createChart(String year, String month, String day, String time) {
  final bazi = BaZi(
    year: gz(year),
    month: gz(month),
    day: gz(day),
    time: gz(time),
  );

  // Minimal mock for other fields
  // We don't really use time/lunarDate for these ShenSha checks
  // except maybe gender for TianLuoDiWang (not testing here)
  final dummyTime = AstroDateTime(2000, 1, 1, 12, 0, 0);
  final timePack = TimePack.createBySolarTime(clockTime: dummyTime);
  final lunarDate = LunarDate.fromSolar(dummyTime);

  return BaziChart(timePack, bazi, lunarDate, Gender.male);
}

void main() {
  group('神煞测试', () {
    test('地转日 (DiZhuan)', () {
      // 春 (寅卯辰月) 见 辛卯
      final c1 = createChart('甲子', '丙寅', '辛卯', '甲午');
      final s1 = DiZhuanShenSha('地转');
      final r1 = s1.check(c1, c1.bazi.day, PillarType.day);
      print('寅月辛卯日 -> 地转: $r1');
      expect(r1, isTrue, reason: '寅月辛卯日应为地转');

      // 夏 (巳午未月) 见 戊午
      final c2 = createChart('甲子', '己巳', '戊午', '甲午');
      final r2 = s1.check(c2, c2.bazi.day, PillarType.day);
      print('巳月戊午日 -> 地转: $r2');
      expect(r2, isTrue, reason: '巳月戊午日应为地转');

      // 秋 (申酉戌月) 见 癸酉
      final c3 = createChart('甲子', '壬申', '癸酉', '甲午');
      expect(
        s1.check(c3, c3.bazi.day, PillarType.day),
        isTrue,
        reason: '申月癸酉日应为地转',
      );

      // 冬 (亥子丑月) 见 丙子
      final c4 = createChart('甲子', '乙亥', '丙子', '甲午');
      expect(
        s1.check(c4, c4.bazi.day, PillarType.day),
        isTrue,
        reason: '亥月丙子日应为地转',
      );

      // Negative case
      final c5 = createChart('甲子', '丙寅', '甲子', '甲午');
      expect(
        s1.check(c5, c5.bazi.day, PillarType.day),
        isFalse,
        reason: '寅月甲子日不应为地转',
      );
    });

    test('天转日 (TianZhuan)', () {
      // 春 (寅卯辰月) 见 乙卯
      final c1 = createChart('甲子', '丙寅', '乙卯', '甲午');
      final s1 = TianZhuanShenSha('天转');
      final r1 = s1.check(c1, c1.bazi.day, PillarType.day);
      print('寅月乙卯日 -> 天转: $r1');
      expect(r1, isTrue, reason: '寅月乙卯日应为天转');

      // 夏 (巳午未月) 见 丙午
      final c2 = createChart('甲子', '己巳', '丙午', '甲午');
      expect(
        s1.check(c2, c2.bazi.day, PillarType.day),
        isTrue,
        reason: '巳月丙午日应为天转',
      );

      // 秋 (申酉戌月) 见 辛酉
      final c3 = createChart('甲子', '壬申', '辛酉', '甲午');
      expect(
        s1.check(c3, c3.bazi.day, PillarType.day),
        isTrue,
        reason: '申月辛酉日应为天转',
      );

      // 冬 (亥子丑月) 见 壬子
      final c4 = createChart('甲子', '乙亥', '壬子', '甲午');
      expect(
        s1.check(c4, c4.bazi.day, PillarType.day),
        isTrue,
        reason: '亥月壬子日应为天转',
      );
    });

    test('拱禄 (GongLu)', () {
      final s1 = GongLuGongGuiShenSha('拱禄', {
        TianGan.gui: {DiZhi.hai, DiZhi.chou}, // 拱子
        TianGan.ding: {DiZhi.si, DiZhi.wei}, // 拱午
        TianGan.ji: {DiZhi.wei, DiZhi.si}, // 拱午
        TianGan.wu: {DiZhi.chen, DiZhi.wu}, // 拱巳
      });

      // 癸亥日 癸丑时 -> 拱子
      final c1 = createChart('甲子', '甲子', '癸亥', '癸丑');
      final r1 = s1.check(c1, c1.bazi.day, PillarType.day);
      print('癸亥日癸丑时 -> 拱禄: $r1 (拱子)');
      expect(r1, isTrue, reason: '癸亥日癸丑时应拱禄');

      // 丁巳日 丁未时 -> 拱午
      final c2 = createChart('甲子', '甲子', '丁巳', '丁未');
      final r2 = s1.check(c2, c2.bazi.day, PillarType.day);
      print('丁巳日丁未时 -> 拱禄: $r2 (拱午)');
      expect(r2, isTrue, reason: '丁巳日丁未时应拱禄');

      // Negative: 日时不同干
      final c3 = createChart('甲子', '甲子', '癸亥', '甲丑');
      expect(
        s1.check(c3, c3.bazi.day, PillarType.day),
        isFalse,
        reason: '日时不同干不拱禄',
      );
    });

    test('拱贵 (GongGui)', () {
      final s1 = GongLuGongGuiShenSha('拱贵', {
        TianGan.jia: {DiZhi.shen, DiZhi.xu, DiZhi.yin, DiZhi.zi},
        TianGan.yi: {DiZhi.wei, DiZhi.you},
        TianGan.wu: {DiZhi.shen, DiZhi.wu},
        TianGan.xin: {DiZhi.chou, DiZhi.mao},
      });

      // 甲申日 甲戌时 -> 拱酉
      final c1 = createChart('甲子', '甲子', '甲申', '甲戌');
      final r1 = s1.check(c1, c1.bazi.day, PillarType.day);
      print('甲申日甲戌时 -> 拱贵: $r1 (拱酉)');
      expect(r1, isTrue, reason: '甲申日甲戌时应拱贵');

      // 甲寅日 甲子时 -> 拱丑
      final c2 = createChart('甲子', '甲子', '甲寅', '甲子');
      final r2 = s1.check(c2, c2.bazi.day, PillarType.day);
      print('甲寅日甲子时 -> 拱贵: $r2 (拱丑)');
      expect(r2, isTrue, reason: '甲寅日甲子时应拱贵');

      // 乙未日 乙酉时 -> 拱申
      final c3 = createChart('甲子', '甲子', '乙未', '乙酉');
      expect(
        s1.check(c3, c3.bazi.day, PillarType.day),
        isTrue,
        reason: '乙未日乙酉时应拱贵',
      );
    });
  });
}

import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  group('TaiXi Calculation', () {
    test('Day Pillar Jia Zi (甲子) should have Tai Xi Ji Chou (己丑)', () {
      final bazi = BaZi(
        year: GanZhi(TianGan.jia, DiZhi.zi),
        month: GanZhi(TianGan.jia, DiZhi.zi),
        day: GanZhi(TianGan.jia, DiZhi.zi), // Key: 甲子
        time: GanZhi(TianGan.jia, DiZhi.zi),
      );
      
      // Mock other required objects
      final timePack = TimePack.createBySolarTime(
        clockTime: AstroDateTime(2024, 1, 1, 12, 0, 0),
      );
      final lunarDate = LunarDate.fromSolar(AstroDateTime(2024, 1, 1, 12, 0, 0));
      
      final chart = BaziChart(timePack, bazi, lunarDate, Gender.male);
      
      // Tai Xi for 甲子:
      // Stem: 甲 matches 己 (Ji)
      // Branch: 子 matches 丑 (Chou)
      expect(chart.taiXi.gan, TianGan.ji);
      expect(chart.taiXi.zhi, DiZhi.chou);
    });

    test('Day Pillar Bing Yin (丙寅) should have Tai Xi Xin Hai (辛亥)', () {
      final bazi = BaZi(
        year: GanZhi(TianGan.jia, DiZhi.zi),
        month: GanZhi(TianGan.jia, DiZhi.zi),
        day: GanZhi(TianGan.bing, DiZhi.yin), // Key: 丙寅
        time: GanZhi(TianGan.jia, DiZhi.zi),
      );
      
      final timePack = TimePack.createBySolarTime(
        clockTime: AstroDateTime(2024, 1, 1, 12, 0, 0),
      );
      final lunarDate = LunarDate.fromSolar(AstroDateTime(2024, 1, 1, 12, 0, 0));
      
      final chart = BaziChart(timePack, bazi, lunarDate, Gender.male);
      
      // Tai Xi for 丙寅:
      // Stem: 丙 matches 辛 (Xin)
      // Branch: 寅 matches 亥 (Hai)
      expect(chart.taiXi.gan, TianGan.xin);
      expect(chart.taiXi.zhi, DiZhi.hai);
    });
  });
}

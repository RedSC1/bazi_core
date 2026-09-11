import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';

int gz(String v) =>
    makeGanzhi('甲乙丙丁戊己庚辛壬癸'.indexOf(v[0]), '子丑寅卯辰巳午未申酉戌亥'.indexOf(v[1]));
BigInt sha(String month, String day, String hour) => collectTargetShenSha(
  analyzePillars(
    FourPillars(year: 0, month: gz(month), day: gz(day), hour: gz(hour)),
  ),
  gz(day),
  ShenShaTarget.day,
  gender: Gender.male,
);
void main() {
  test(
    'genderless rules retain Jin-Shen, Tong-Zi, San-Qi and Gong matches',
    () {
      final cases = [
        (25, '甲子', '甲寅', '甲子', '癸酉', ShenShaTarget.hour),
        (31, '甲子', '甲寅', '甲子', '癸酉', ShenShaTarget.day),
        (33, '甲子', '戊辰', '庚午', '甲子', ShenShaTarget.day),
        (34, '乙丑', '丙寅', '丁卯', '甲子', ShenShaTarget.day),
        (35, '壬子', '癸丑', '辛卯', '甲子', ShenShaTarget.day),
        (48, '甲子', '甲寅', '癸亥', '癸丑', ShenShaTarget.day),
        (49, '甲子', '甲寅', '甲申', '甲戌', ShenShaTarget.day),
      ];
      final dependentMask = [
        18,
        19,
        20,
        45,
      ].fold(BigInt.zero, (mask, id) => mask | (BigInt.one << id));
      for (final (id, year, month, day, hour, kind) in cases) {
        final chart = analyzePillars(
          FourPillars(
            year: gz(year),
            month: gz(month),
            day: gz(day),
            hour: gz(hour),
          ),
        );
        final target = kind == ShenShaTarget.hour
            ? chart.pillars.hour
            : chart.pillars.day;
        final bits = collectTargetShenSha(chart, target, kind);
        expect(hasShenSha(bits, id), isTrue, reason: 'missing $id');
        expect(bits & dependentMask, BigInt.zero);
        for (final gender in Gender.values) {
          expect(
            bits,
            collectTargetShenSha(chart, target, kind, gender: gender) &
                ~dependentMask,
          );
        }
      }
    },
  );
  test('legacy seasonal Di-Zhuan and Tian-Zhuan cases', () {
    for (final (month, day) in [
      ('丙寅', '辛卯'),
      ('己巳', '戊午'),
      ('壬申', '癸酉'),
      ('乙亥', '丙子'),
    ]) {
      expect(hasShenSha(sha(month, day, '甲午'), 50), isTrue);
    }
    expect(hasShenSha(sha('丙寅', '甲子', '甲午'), 50), isFalse);
    for (final (month, day) in [
      ('丙寅', '乙卯'),
      ('己巳', '丙午'),
      ('壬申', '辛酉'),
      ('乙亥', '壬子'),
    ]) {
      expect(hasShenSha(sha(month, day, '甲午'), 51), isTrue);
    }
  });
  test('legacy Gong-Lu and Gong-Gui cases', () {
    for (final (day, hour) in [('癸亥', '癸丑'), ('丁巳', '丁未')]) {
      expect(hasShenSha(sha('甲子', day, hour), 48), isTrue);
    }
    // Old fixture used impossible 甲丑. Use a valid different-stem pillar for the negative case.
    expect(hasShenSha(sha('甲子', '癸亥', '乙丑'), 48), isFalse);
    for (final (day, hour) in [('甲申', '甲戌'), ('甲寅', '甲子'), ('乙未', '乙酉')]) {
      expect(hasShenSha(sha('甲子', day, hour), 49), isTrue);
    }
  });
  test('legacy exact 13:00:00 is Wei hour with civil clock', () {
    final t = ZonedTime(
      year: 2000,
      month: 1,
      day: 1,
      hour: 13,
      offsetMinutes: 480,
    );
    expect(ganzhiBranch(BaziChart.fromZonedTime(t).pillars.hour), 7);
  });
}

import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  test('searchDates returns one normal candidate on a non-jie day', () {
    final clockTime = AstroDateTime(2026, 2, 19, 12, 0, 0);
    final chart = BaziChart.createBySolarDate(clockTime: clockTime);

    final results = BaziReverseLookup.searchDates(
      BaziDateSearchQuery(
        year: chart.bazi.year,
        month: chart.bazi.month,
        day: chart.bazi.day,
        startDate: AstroDateTime(2026, 2, 19, 0, 0, 0),
        endDate: AstroDateTime(2026, 2, 19, 0, 0, 0),
      ),
    );

    expect(results, hasLength(1));
    expect(results.first.phase, BaziDatePhase.normal);
    expect(results.first.date.year, 2026);
    expect(results.first.date.month, 2);
    expect(results.first.date.day, 19);
  });

  test('searchDates splits jie day into before/after candidates', () {
    final liChun = AstroDateTime.fromJ2000(getSpecificJieQi(2026, 21));

    final results = BaziReverseLookup.searchDates(
      BaziDateSearchQuery(
        startDate: AstroDateTime(
          liChun.year,
          liChun.month,
          liChun.day,
          0,
          0,
          0,
        ),
        endDate: AstroDateTime(liChun.year, liChun.month, liChun.day, 0, 0, 0),
      ),
    );

    expect(results, hasLength(2));
    expect(
      results.map((item) => item.phase),
      containsAll(<BaziDatePhase>[
        BaziDatePhase.beforeJie,
        BaziDatePhase.afterJie,
      ]),
    );
    expect(results.every((item) => item.isJieBoundaryDay), isTrue);
  });

  test('searchDates rejects illegal year-month combination by WuHuDun', () {
    expect(
      () => BaziReverseLookup.searchDates(
        BaziDateSearchQuery(
          year: GanZhi(TianGan.jia, DiZhi.zi),
          month: GanZhi(TianGan.jia, DiZhi.yin),
          startDate: AstroDateTime(1984, 1, 1, 0, 0, 0),
          endDate: AstroDateTime(1984, 12, 31, 0, 0, 0),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('searchDates resolves Zi month across civil year boundary', () {
    final clockTime = AstroDateTime(2025, 12, 20, 12, 0, 0);
    final chart = BaziChart.createBySolarDate(clockTime: clockTime);

    final results = BaziReverseLookup.searchDates(
      BaziDateSearchQuery(
        year: chart.bazi.year,
        month: chart.bazi.month,
        day: chart.bazi.day,
        startDate: AstroDateTime(2025, 1, 1, 0, 0, 0),
        endDate: AstroDateTime(2026, 2, 28, 0, 0, 0),
      ),
    );

    expect(results, hasLength(1));
    expect(results.first.date.year, 2025);
    expect(results.first.date.month, 12);
    expect(results.first.date.day, 20);
    expect(results.first.chart.bazi.month.zhi, DiZhi.zi);
  });

  test('searchDates resolves LiChun day before/after year-month switch', () {
    final date = AstroDateTime(2026, 2, 4, 0, 0, 0);

    final beforeResults = BaziReverseLookup.searchDates(
      BaziDateSearchQuery(
        year: GanZhi(TianGan.yi, DiZhi.si),
        month: GanZhi(TianGan.ji, DiZhi.chou),
        day: GanZhi(TianGan.ji, DiZhi.you),
        startDate: date,
        endDate: date,
      ),
    );
    final afterResults = BaziReverseLookup.searchDates(
      BaziDateSearchQuery(
        year: GanZhi(TianGan.bing, DiZhi.wu),
        month: GanZhi(TianGan.geng, DiZhi.yin),
        day: GanZhi(TianGan.ji, DiZhi.you),
        startDate: date,
        endDate: date,
      ),
    );

    expect(beforeResults, hasLength(1));
    expect(beforeResults.single.phase, BaziDatePhase.beforeJie);
    expect(beforeResults.single.date.year, 2026);
    expect(beforeResults.single.date.month, 2);
    expect(beforeResults.single.date.day, 4);
    expect(beforeResults.single.chart.bazi.year.gan, TianGan.yi);
    expect(beforeResults.single.chart.bazi.year.zhi, DiZhi.si);
    expect(beforeResults.single.chart.bazi.month.gan, TianGan.ji);
    expect(beforeResults.single.chart.bazi.month.zhi, DiZhi.chou);
    expect(beforeResults.single.chart.bazi.day.gan, TianGan.ji);
    expect(beforeResults.single.chart.bazi.day.zhi, DiZhi.you);

    expect(afterResults, hasLength(1));
    expect(afterResults.single.phase, BaziDatePhase.afterJie);
    expect(afterResults.single.date.year, 2026);
    expect(afterResults.single.date.month, 2);
    expect(afterResults.single.date.day, 4);
    expect(afterResults.single.chart.bazi.year.gan, TianGan.bing);
    expect(afterResults.single.chart.bazi.year.zhi, DiZhi.wu);
    expect(afterResults.single.chart.bazi.month.gan, TianGan.geng);
    expect(afterResults.single.chart.bazi.month.zhi, DiZhi.yin);
    expect(afterResults.single.chart.bazi.day.gan, TianGan.ji);
    expect(afterResults.single.chart.bazi.day.zhi, DiZhi.you);
  });

  test('searchTimesForDate returns 12 segments when rat hour is not split', () {
    final date = AstroDateTime(2026, 2, 19, 0, 0, 0);
    final dateResults = BaziReverseLookup.searchDates(
      BaziDateSearchQuery(
        startDate: date,
        endDate: date,
        ratHourMode: RatHourMode.noSplit,
      ),
    );

    final timeResults = BaziReverseLookup.searchTimesForDate(
      BaziTimeSearchQuery(dateCandidate: dateResults.single),
    );

    expect(timeResults, hasLength(12));
    expect(timeResults.where((item) => item.label == '晚子时'), isEmpty);
    expect(timeResults.first.label, '子时');
    expect(timeResults.last.label, '亥时');
  });

  test('searchTimesForDate returns late Zi segment when rat hour is split', () {
    final date = AstroDateTime(2026, 2, 19, 0, 0, 0);
    final dateResults = BaziReverseLookup.searchDates(
      BaziDateSearchQuery(
        startDate: date,
        endDate: date,
        ratHourMode: RatHourMode.tomorrowGan,
      ),
    );
    final dateCandidate = dateResults.single;

    final allTimeResults = BaziReverseLookup.searchTimesForDate(
      BaziTimeSearchQuery(dateCandidate: dateCandidate),
    );

    expect(allTimeResults, hasLength(13));
    expect(allTimeResults.where((item) => item.label == '子时'), hasLength(1));
    expect(allTimeResults.where((item) => item.label == '晚子时'), hasLength(1));

    final lateZiChart = BaziChart.createBySolarDate(
      clockTime: AstroDateTime(2026, 2, 19, 23, 30, 0),
      ratHourMode: RatHourMode.tomorrowGan,
    );
    final filtered = BaziReverseLookup.searchTimesForDate(
      BaziTimeSearchQuery(
        dateCandidate: dateCandidate,
        time: lateZiChart.bazi.time,
      ),
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.label, '晚子时');
    expect(filtered.single.hourIndex, 0);
    expect(filtered.single.isLateZi, isTrue);
  });

  test('searchFullBazi resolves a normal full chart', () {
    final clockTime = AstroDateTime(2026, 2, 19, 10, 30, 0);
    final chart = BaziChart.createBySolarDate(clockTime: clockTime);

    final results = BaziReverseLookup.searchFullBazi(
      BaziFullSearchQuery(
        year: chart.bazi.year,
        month: chart.bazi.month,
        day: chart.bazi.day,
        time: chart.bazi.time,
        startDate: AstroDateTime(2026, 2, 19, 0, 0, 0),
        endDate: AstroDateTime(2026, 2, 19, 0, 0, 0),
      ),
    );

    expect(results, hasLength(1));
    expect(results.single.dateCandidate.date.year, 2026);
    expect(results.single.dateCandidate.date.month, 2);
    expect(results.single.dateCandidate.date.day, 19);
    expect(results.single.timeCandidate, isNotNull);
    expect(results.single.chart.bazi.time.gan, chart.bazi.time.gan);
    expect(results.single.chart.bazi.time.zhi, chart.bazi.time.zhi);
  });

  test('searchFullBazi resolves LiChun afterJie full chart', () {
    final clockTime = AstroDateTime(2026, 2, 4, 12, 0, 0);
    final chart = BaziChart.createBySolarDate(clockTime: clockTime);

    final results = BaziReverseLookup.searchFullBazi(
      BaziFullSearchQuery(
        year: chart.bazi.year,
        month: chart.bazi.month,
        day: chart.bazi.day,
        time: chart.bazi.time,
        startDate: AstroDateTime(2026, 2, 4, 0, 0, 0),
        endDate: AstroDateTime(2026, 2, 4, 0, 0, 0),
      ),
    );

    expect(results, hasLength(1));
    expect(results.single.dateCandidate.phase, BaziDatePhase.afterJie);
    expect(results.single.timeCandidate, isNotNull);
    expect(results.single.chart.bazi.year.gan, TianGan.bing);
    expect(results.single.chart.bazi.year.zhi, DiZhi.wu);
    expect(results.single.chart.bazi.month.gan, TianGan.geng);
    expect(results.single.chart.bazi.month.zhi, DiZhi.yin);
  });

  test('searchFullBazi resolves LiChun Zi-hour variants by rat hour mode', () {
    final startDate = AstroDateTime(2026, 2, 4, 0, 0, 0);
    final endDate = AstroDateTime(2026, 2, 4, 0, 0, 0);

    final beforeZi = BaziReverseLookup.searchFullBazi(
      BaziFullSearchQuery(
        year: GanZhi(TianGan.yi, DiZhi.si),
        month: GanZhi(TianGan.ji, DiZhi.chou),
        day: GanZhi(TianGan.ji, DiZhi.you),
        time: GanZhi(TianGan.jia, DiZhi.zi),
        startDate: startDate,
        endDate: endDate,
        ratHourMode: RatHourMode.noSplit,
      ),
    );
    expect(beforeZi, hasLength(1));
    expect(beforeZi.single.dateCandidate.phase, BaziDatePhase.beforeJie);
    expect(beforeZi.single.timeCandidate, isNotNull);
    expect(beforeZi.single.timeCandidate!.label, '子时');

    final noSplitLateZi = BaziReverseLookup.searchFullBazi(
      BaziFullSearchQuery(
        year: GanZhi(TianGan.bing, DiZhi.wu),
        month: GanZhi(TianGan.geng, DiZhi.yin),
        day: GanZhi(TianGan.ji, DiZhi.you),
        time: GanZhi(TianGan.jia, DiZhi.zi),
        startDate: startDate,
        endDate: endDate,
        ratHourMode: RatHourMode.noSplit,
      ),
    );
    expect(noSplitLateZi, isEmpty);

    final todayGanLateZi = BaziReverseLookup.searchFullBazi(
      BaziFullSearchQuery(
        year: GanZhi(TianGan.bing, DiZhi.wu),
        month: GanZhi(TianGan.geng, DiZhi.yin),
        day: GanZhi(TianGan.ji, DiZhi.you),
        time: GanZhi(TianGan.jia, DiZhi.zi),
        startDate: startDate,
        endDate: endDate,
        ratHourMode: RatHourMode.todayGan,
      ),
    );
    expect(todayGanLateZi, hasLength(1));
    expect(todayGanLateZi.single.dateCandidate.phase, BaziDatePhase.afterJie);
    expect(todayGanLateZi.single.timeCandidate, isNotNull);
    expect(todayGanLateZi.single.timeCandidate!.label, '晚子时');

    final tomorrowGanLateZi = BaziReverseLookup.searchFullBazi(
      BaziFullSearchQuery(
        year: GanZhi(TianGan.bing, DiZhi.wu),
        month: GanZhi(TianGan.geng, DiZhi.yin),
        day: GanZhi(TianGan.ji, DiZhi.you),
        time: GanZhi(TianGan.bing, DiZhi.zi),
        startDate: startDate,
        endDate: endDate,
        ratHourMode: RatHourMode.tomorrowGan,
      ),
    );
    expect(tomorrowGanLateZi, hasLength(1));
    expect(tomorrowGanLateZi.single.dateCandidate.phase, BaziDatePhase.afterJie);
    expect(tomorrowGanLateZi.single.timeCandidate, isNotNull);
    expect(tomorrowGanLateZi.single.timeCandidate!.label, '晚子时');

    final wrongBeforeZi = BaziReverseLookup.searchFullBazi(
      BaziFullSearchQuery(
        year: GanZhi(TianGan.yi, DiZhi.si),
        month: GanZhi(TianGan.ji, DiZhi.chou),
        day: GanZhi(TianGan.ji, DiZhi.you),
        time: GanZhi(TianGan.bing, DiZhi.zi),
        startDate: startDate,
        endDate: endDate,
        ratHourMode: RatHourMode.tomorrowGan,
      ),
    );
    expect(wrongBeforeZi, isEmpty);
  });
}

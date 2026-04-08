import 'package:bazi_core/bazi_core.dart';

void main() {
  final fullResults = BaziReverseLookup.searchFullBazi(
    BaziFullSearchQuery(
      year: GanZhi(TianGan.bing, DiZhi.wu),
      month: GanZhi(TianGan.geng, DiZhi.yin),
      day: GanZhi(TianGan.ji, DiZhi.you),
      time: GanZhi(TianGan.geng, DiZhi.wu),
      startDate: AstroDateTime(2026, 2, 4, 0, 0, 0),
      endDate: AstroDateTime(2026, 2, 4, 0, 0, 0),
    ),
  );
  print('=== Full Search Demo ===');
  print('count=${fullResults.length}');
  for (final item in fullResults) {
    final date = item.dateCandidate.date;
    final time = item.timeCandidate;
    print(
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      'phase=${item.dateCandidate.phase.name} '
      'time=${time?.label ?? '-'} '
      'sample=${time?.sampleTime ?? item.dateCandidate.sampleTime} '
      '=> ${item.chart.bazi}',
    );
  }
  print('');

  final cases = <String, BaziDateSearchQuery>{
    '丙午年 庚寅月 己酉日': BaziDateSearchQuery(
      year: GanZhi(TianGan.bing, DiZhi.wu),
      month: GanZhi(TianGan.geng, DiZhi.yin),
      day: GanZhi(TianGan.ji, DiZhi.you),
      startDate: AstroDateTime(1800, 1, 1, 0, 0, 0),
      endDate: AstroDateTime(2200, 12, 31, 0, 0, 0),
    ),
    '乙巳年 己丑月 己酉日': BaziDateSearchQuery(
      year: GanZhi(TianGan.yi, DiZhi.si),
      month: GanZhi(TianGan.ji, DiZhi.chou),
      day: GanZhi(TianGan.ji, DiZhi.you),
      startDate: AstroDateTime(1800, 1, 1, 0, 0, 0),
      endDate: AstroDateTime(2200, 12, 31, 0, 0, 0),
    ),
  };

  for (final entry in cases.entries) {
    final results = BaziReverseLookup.searchDates(entry.value);
    print('=== ${entry.key} ===');
    print('count=${results.length}');

    if (results.isEmpty) {
      print('NO MATCH');
      print('');
      continue;
    }

    for (final item in results) {
      final date = item.date;
      final sample = item.sampleTime;
      final bazi = item.chart.bazi;
      print(
        '${date.year.toString().padLeft(5)}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        'phase=${item.phase.name} '
        'sample=${sample.year}-${sample.month.toString().padLeft(2, '0')}-${sample.day.toString().padLeft(2, '0')} '
        '${sample.hour.toString().padLeft(2, '0')}:${sample.minute.toString().padLeft(2, '0')}:${sample.second.toString().padLeft(2, '0')} '
        '=> ${bazi.year} ${bazi.month} ${bazi.day}',
      );
    }

    print('');
  }
}

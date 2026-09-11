part of '../bazi_core.dart';

class BaziColumn extends DecodedPillar {
  final String key;
  final int visibleTenGod, lifeStage, nayinId;
  final List<int> hiddenStems, hiddenTenGods;
  BaziColumn(super.value, this.key, int dayMaster, EarthPalaceMode mode)
    : visibleTenGod = getTenGod(dayMaster, ganzhiStem(value)),
      lifeStage = getLifeStage(dayMaster, ganzhiBranch(value), mode),
      nayinId = getNayinId(value),
      hiddenStems = getHiddenStems(ganzhiBranch(value)),
      hiddenTenGods = List.unmodifiable(
        getHiddenStems(ganzhiBranch(value)).map((s) => getTenGod(dayMaster, s)),
      );
  BaziColumn._snapshot(BaziColumn source)
    : key = source.key,
      visibleTenGod = source.visibleTenGod,
      lifeStage = source.lifeStage,
      nayinId = source.nayinId,
      hiddenStems = List.unmodifiable(source.hiddenStems),
      hiddenTenGods = List.unmodifiable(source.hiddenTenGods),
      super(source.value);
  @override
  Map<String, Object> toJson() => {
    ...super.toJson(),
    'key': key,
    'visibleTenGod': visibleTenGod,
    'hiddenStems': hiddenStems,
    'hiddenTenGods': hiddenTenGods,
    'lifeStage': lifeStage,
    'nayinId': nayinId,
  };
}

/// Interpretation of known pillars without inventing a birth instant.
class BaziPillarAnalysis {
  final FourPillars pillars;
  final ExtraPillars extraPillars;
  final int dayMaster;
  final List<BaziColumn> columns;
  BaziPillarAnalysis._(
    this.pillars,
    this.extraPillars,
    this.dayMaster,
    this.columns,
  );
}

BaziPillarAnalysis analyzePillars(
  FourPillars pillars, {
  EarthPalaceMode earthPalaceMode = EarthPalaceMode.fireEarth,
}) {
  final dayMaster = ganzhiStem(pillars.day);
  final columns = [
    for (final e in pillars.toJson().entries)
      BaziColumn(e.value, e.key, dayMaster, earthPalaceMode),
  ];
  return BaziPillarAnalysis._(
    pillars,
    calculateExtraPillars(
      pillars.year,
      pillars.month,
      pillars.day,
      pillars.hour,
    ),
    dayMaster,
    List.unmodifiable(columns),
  );
}

class BaziChart extends BaziPillarAnalysis {
  final BaziOptions options;
  final double birthJdUT1;
  final ZonedTime? birthClockTime;
  final CalendarDate birthChartTime;
  @Deprecated('Use birthChartTime.')
  CalendarDate get birthCivilTime => birthChartTime;
  BaziChart._(
    BaziPillarAnalysis a,
    this.options,
    this.birthJdUT1,
    this.birthChartTime,
    this.birthClockTime,
  ) : super._(a.pillars, a.extraPillars, a.dayMaster, a.columns);
  factory BaziChart.fromInstant(
    Object instant,
    CalendarDate chartTime, {
    BaziOptions? options,
  }) {
    final jdUT1 = asUt1JulianDay(instant);
    final o = options ?? BaziOptions();
    final pillars = calculateFourPillars(
      jdUT1,
      chartTime,
      options: o.calendarOptions,
      ratHourMode: o.ratHourMode,
      pillarHistoricalMode: o.pillarHistoricalMode,
    );
    return BaziChart._(
      analyzePillars(pillars, earthPalaceMode: o.earthPalaceMode),
      o,
      jdUT1,
      normalizeChartVirtualTime(chartTime),
      null,
    );
  }
  factory BaziChart.fromZonedTime(ZonedTime time, {BaziOptions? options}) {
    final o = options ?? BaziOptions();
    final v = switch (o.clockMode) {
      BaziClockMode.civil => time,
      BaziClockMode.meanSolar => meanSolarTime(time, o.longitudeDeg!),
      BaziClockMode.trueSolar => trueSolarTime(time, o.longitudeDeg!),
    };
    final c = BaziChart.fromInstant(time.toJulianTime().jdUT1, v, options: o);
    return BaziChart._(c, o, c.birthJdUT1, c.birthChartTime, time);
  }
  factory BaziChart.fromSolarDay(
    CalendarDate solarDay, {
    required int hour,
    int minute = 0,
    double second = 0,
    BaziOptions? options,
  }) {
    final o = options ?? BaziOptions();
    return BaziChart.fromZonedTime(
      ZonedTime(
        year: solarDay.year,
        month: solarDay.month,
        day: solarDay.day,
        hour: hour,
        minute: minute,
        second: second,
        offsetMinutes: o.utcOffsetMinutes,
      ),
      options: o,
    );
  }
  factory BaziChart.fromLunarDay(
    LunarDate lunarDay, {
    required int hour,
    int minute = 0,
    double second = 0,
    BaziOptions? options,
  }) {
    final o = options ?? BaziOptions();
    final solarDay = lunarToSolar(lunarDay, options: o.calendarOptions);
    return BaziChart.fromSolarDay(
      solarDay,
      hour: hour,
      minute: minute,
      second: second,
      options: o,
    );
  }
  QiYunResult getQiYun() {
    final gender = options.gender;
    if (gender == null) throw StateError('Qi-Yun requires gender');
    return calculateQiYun(
      birthJdUT1,
      birthChartTime,
      this,
      gender,
      calendarOptions: options.calendarOptions,
      timeModel: options.qiYunTimeModel,
    );
  }

  List<DaYunEntry> getDaYunTable() => generateDaYun(
    birthChartTime,
    this,
    getQiYun(),
    count: options.daYunCount,
    boundaryModel: options.daYunBoundaryModel,
  );
  NatalShenShaBitsets getShenSha() =>
      collectNatalShenSha(this, gender: options.gender);
  BigInt getTargetShenSha(int pillar, ShenShaTarget kind) =>
      collectTargetShenSha(this, pillar, kind, gender: options.gender);
  List<RenyuanSilingSegment> getRenyuanSiling() => getRenyuanSilingSegments(
    ganzhiBranch(pillars.month),
    options.renyuanSilingTable,
  );
  Map<String, Object?> toJson() {
    final sha = getShenSha(), qi = options.gender == null ? null : getQiYun();
    return {
      'schemaVersion': 'bazi-chart-v1',
      'kind': 'bazi',
      'scope': 'natal',
      'birth': {
        'calendar': 'julian-gregorian-1582',
        'yearNumbering': 'astronomical',
        'jdUT1': birthJdUT1,
        'clockTime': birthClockTime?.toJson(),
        'chartTime': birthChartTime.toJson(),
        'virtualTime': birthChartTime.toJson(),
        'clockMode': options.toJson()['clockMode'],
        'longitudeDeg': options.longitudeDeg,
        'gender': options.gender?.name,
      },
      'options': options.toJson(),
      'pillars': pillars.toJson(),
      'dayMaster': dayMaster,
      'columns': [
        for (final c in columns)
          {
            ...c.toJson(),
            'visibleTenGodName': tenGodNames[c.visibleTenGod],
            'hiddenTenGodNames': c.hiddenTenGods
                .map((i) => tenGodNames[i])
                .toList(),
            'lifeStageName': lifeStageNames[c.lifeStage],
            'shenSha': [
              for (final id in shenShaIds(sha[c.key]))
                {'id': id, 'name': shenShaNameTable[id]},
            ],
          },
      ],
      'extraPillars': {
        for (final e in extraPillars.toJson().entries)
          e.key: unpackPillar(e.value).toJson(),
      },
      'relations': collectChartRelations(this).map((r) => r.toJson()).toList(),
      'renyuanSiling': getRenyuanSiling().map((s) => s.toJson()).toList(),
      'fortune': qi == null
          ? null
          : {
              'clockBasis': 'virtual-time',
              'qiYun': qi.toJson(),
              'decades':
                  generateDaYun(
                        birthChartTime,
                        this,
                        qi,
                        count: options.daYunCount,
                        boundaryModel: options.daYunBoundaryModel,
                      )
                      .map(
                        (e) => {
                          ...e.toJson(),
                          'pillarName': ganzhiName(e.pillar),
                        },
                      )
                      .toList(),
            },
    };
  }
}

BaziChart calculateBazi(
  Object instant,
  CalendarDate chartTime, {
  BaziOptions? options,
}) => BaziChart.fromInstant(instant, chartTime, options: options);
BaziChart baziForZonedTime(ZonedTime time, {BaziOptions? options}) =>
    BaziChart.fromZonedTime(time, options: options);

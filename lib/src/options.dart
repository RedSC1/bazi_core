part of '../bazi_core.dart';

/// Immutable per-chart options. No process-wide settings or FFI dependency.
class BaziOptions {
  final CalendarOptions calendarOptions;
  final RatHourMode ratHourMode;
  final PillarHistoricalMode pillarHistoricalMode;
  final EarthPalaceMode earthPalaceMode;
  final Gender? gender;
  final BaziClockMode clockMode;
  final double? longitudeDeg;
  final QiYunTimeModel qiYunTimeModel;
  final DaYunBoundaryModel daYunBoundaryModel;
  final int daYunCount;
  final RenyuanSilingTable renyuanSilingTable;
  BaziOptions({
    CalendarOptions? calendarOptions,
    this.ratHourMode = RatHourMode.nextDay,
    this.pillarHistoricalMode = PillarHistoricalMode.followCalendar,
    this.earthPalaceMode = EarthPalaceMode.fireEarth,
    this.gender,
    this.clockMode = BaziClockMode.civil,
    this.longitudeDeg,
    this.qiYunTimeModel = QiYunTimeModel.traditionalCalendar,
    this.daYunBoundaryModel = DaYunBoundaryModel.civilYears,
    this.daYunCount = 8,
    this.renyuanSilingTable = RenyuanSilingTable.sanMingTongHui,
  }) : calendarOptions = calendarOptions ?? CalendarOptions() {
    if (this.calendarOptions.utcOffsetMinutes !=
        this.calendarOptions.utcOffsetMinutes.truncateToDouble()) {
      throw ArgumentError('utcOffsetMinutes must be an integer');
    }
    if (longitudeDeg != null &&
        (!longitudeDeg!.isFinite || longitudeDeg!.abs() > 180)) {
      throw RangeError('longitudeDeg must be within ±180');
    }
    if (clockMode != BaziClockMode.civil && longitudeDeg == null) {
      throw ArgumentError('A solar clock requires longitudeDeg');
    }
    if (daYunCount < 0) throw RangeError('daYunCount must be non-negative');
  }
  CalendarMode get mode => calendarOptions.mode;
  CalendarDayBoundaryMode get dayBoundaryMode =>
      calendarOptions.dayBoundaryMode;
  double? get meridianDeg => calendarOptions.meridianDeg;

  /// Restore the persistent JSON options emitted by Dart or JS.
  factory BaziOptions.fromJson(Map<String, Object?> json) {
    T choice<T>(String key, List<T> values, List<Object> codes, T fallback) {
      if (!json.containsKey(key)) return fallback;
      final index = codes.indexOf(json[key] ?? Object());
      if (index < 0) throw ArgumentError('Unknown $key: ${json[key]}');
      return values[index];
    }

    double? number(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! num || !value.isFinite) throw ArgumentError('Invalid $key');
      return value.toDouble();
    }

    int integer(String key, int fallback) {
      if (!json.containsKey(key)) return fallback;
      final value = number(key);
      if (value == null || value != value.truncateToDouble()) {
        throw ArgumentError('Invalid integer $key');
      }
      return value.toInt();
    }

    return BaziOptions(
      calendarOptions: CalendarOptions(
        mode: choice('mode', CalendarMode.values, [
          'historical',
          'china-astronomical',
          'local-astronomical',
        ], CalendarMode.historical),
        dayBoundaryMode: choice(
          'dayBoundaryMode',
          CalendarDayBoundaryMode.values,
          ['fixed-utc-offset', 'mean-solar-meridian'],
          CalendarDayBoundaryMode.fixedUtcOffset,
        ),
        utcOffsetMinutes: integer('utcOffsetMinutes', 480).toDouble(),
        meridianDeg: number('meridianDeg'),
        eventAccuracy: choice(
          'eventAccuracy',
          Accuracy.values,
          Accuracy.values.map((v) => v.name).toList(),
          Accuracy.mid,
        ),
      ),
      ratHourMode: choice('ratHourMode', RatHourMode.values, [
        'next-day',
        'current-day',
        'current-day-tomorrow-stem',
      ], RatHourMode.nextDay),
      pillarHistoricalMode: choice(
        'pillarHistoricalMode',
        PillarHistoricalMode.values,
        ['follow-calendar', 'off', 'on'],
        PillarHistoricalMode.followCalendar,
      ),
      earthPalaceMode: choice('earthPalaceMode', EarthPalaceMode.values, [
        0,
        1,
      ], EarthPalaceMode.fireEarth),
      gender: json['gender'] == null
          ? null
          : choice('gender', Gender.values, [0, 1], Gender.female),
      clockMode: choice('clockMode', BaziClockMode.values, [
        'civil',
        'mean-solar',
        'true-solar',
      ], BaziClockMode.civil),
      longitudeDeg: number('longitudeDeg'),
      qiYunTimeModel: choice('qiYunTimeModel', QiYunTimeModel.values, [
        0,
        1,
        2,
      ], QiYunTimeModel.traditionalCalendar),
      daYunBoundaryModel: choice(
        'daYunBoundaryModel',
        DaYunBoundaryModel.values,
        [0, 1, 2],
        DaYunBoundaryModel.civilYears,
      ),
      daYunCount: integer('daYunCount', 8),
      renyuanSilingTable: choice(
        'renyuanSilingTable',
        RenyuanSilingTable.values,
        [0, 1],
        RenyuanSilingTable.sanMingTongHui,
      ),
    );
  }
  int get utcOffsetMinutes => calendarOptions.utcOffsetMinutes.toInt();
  BaziOptions copyWith({
    CalendarOptions? calendarOptions,
    RatHourMode? ratHourMode,
    PillarHistoricalMode? pillarHistoricalMode,
    EarthPalaceMode? earthPalaceMode,
    Gender? gender,
    bool clearGender = false,
    BaziClockMode? clockMode,
    double? longitudeDeg,
    bool clearLongitude = false,
    QiYunTimeModel? qiYunTimeModel,
    DaYunBoundaryModel? daYunBoundaryModel,
    int? daYunCount,
    RenyuanSilingTable? renyuanSilingTable,
  }) => BaziOptions(
    calendarOptions: calendarOptions ?? this.calendarOptions,
    ratHourMode: ratHourMode ?? this.ratHourMode,
    pillarHistoricalMode: pillarHistoricalMode ?? this.pillarHistoricalMode,
    earthPalaceMode: earthPalaceMode ?? this.earthPalaceMode,
    gender: clearGender ? null : gender ?? this.gender,
    clockMode: clockMode ?? this.clockMode,
    longitudeDeg: clearLongitude ? null : longitudeDeg ?? this.longitudeDeg,
    qiYunTimeModel: qiYunTimeModel ?? this.qiYunTimeModel,
    daYunBoundaryModel: daYunBoundaryModel ?? this.daYunBoundaryModel,
    daYunCount: daYunCount ?? this.daYunCount,
    renyuanSilingTable: renyuanSilingTable ?? this.renyuanSilingTable,
  );
  Map<String, Object?> toJson() => {
    'mode': const [
      'historical',
      'china-astronomical',
      'local-astronomical',
    ][calendarOptions.mode.index],
    'dayBoundaryMode': const [
      'fixed-utc-offset',
      'mean-solar-meridian',
    ][calendarOptions.dayBoundaryMode.index],
    'utcOffsetMinutes': utcOffsetMinutes,
    if (calendarOptions.meridianDeg != null)
      'meridianDeg': calendarOptions.meridianDeg,
    'eventAccuracy': calendarOptions.eventAccuracy.name,
    'pillarHistoricalMode': const [
      'follow-calendar',
      'off',
      'on',
    ][pillarHistoricalMode.index],
    'ratHourMode': const [
      'next-day',
      'current-day',
      'current-day-tomorrow-stem',
    ][ratHourMode.index],
    'earthPalaceMode': earthPalaceMode.index,
    if (gender != null) 'gender': gender!.index,
    'clockMode': const ['civil', 'mean-solar', 'true-solar'][clockMode.index],
    if (longitudeDeg != null) 'longitudeDeg': longitudeDeg,
    'qiYunTimeModel': qiYunTimeModel.index,
    'daYunBoundaryModel': daYunBoundaryModel.index,
    'daYunCount': daYunCount,
    'renyuanSilingTable': renyuanSilingTable.index,
  };
}

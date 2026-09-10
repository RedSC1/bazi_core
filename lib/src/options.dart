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

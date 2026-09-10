part of '../bazi_core.dart';

const tenGodNames = [
  '比肩',
  '劫财',
  '食神',
  '伤官',
  '偏财',
  '正财',
  '七杀',
  '正官',
  '偏印',
  '正印',
];
const lifeStageNames = [
  '长生',
  '沐浴',
  '冠带',
  '临官',
  '帝旺',
  '衰',
  '病',
  '死',
  '墓',
  '绝',
  '胎',
  '养',
];

enum Gender { female, male }

enum EarthPalaceMode { fireEarth, waterEarth }

enum BaziClockMode { civil, meanSolar, trueSolar }

enum QiYunTimeModel { traditionalCalendar, julianYear, tropicalYear }

enum DaYunBoundaryModel { civilYears, julianYears, tropicalYears }

enum RenyuanSilingTable { sanMingTongHui, common }

enum RenyuanSilingOrigin { stem, genEarth, kunEarth }

const _hiddenStems = [
  [9],
  [5, 9, 7],
  [0, 2, 4],
  [1],
  [4, 1, 9],
  [2, 6, 4],
  [3, 5],
  [5, 3, 1],
  [6, 8, 4],
  [7],
  [4, 7, 3],
  [8, 0],
];
const branchCombinationPartner = [1, 0, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2];
const branchTripleCombination = [
  [8, 0, 4],
  [11, 3, 7],
  [2, 6, 10],
  [5, 9, 1],
];
const branchTripleDirection = [
  [11, 0, 1],
  [2, 3, 4],
  [5, 6, 7],
  [8, 9, 10],
];
const branchTriplePunishment = [
  [2, 5, 8],
  [1, 10, 7],
];
const tripleElement = [0, 1, 4, 2];
void _stem(int v) {
  if (v < 0 || v >= 10) throw RangeError.range(v, 0, 9, 'stem');
}

void _branch(int v) {
  if (v < 0 || v >= 12) throw RangeError.range(v, 0, 11, 'branch');
}

List<int> getHiddenStems(int branch) {
  _branch(branch);
  return _hiddenStems[branch];
}

int getTenGod(int dayStem, int targetStem) {
  _stem(dayStem);
  _stem(targetStem);
  final delta = ((targetStem >> 1) + 5 - (dayStem >> 1)) % 5;
  return (delta << 1) | ((dayStem ^ targetStem) & 1);
}

List<int> getKongWang(int value) {
  final first = (10 - (ganzhiIndex(value) ~/ 10) * 2 + 12) % 12,
      second = (first + 1) % 12;
  return List.unmodifiable(
    (ganzhiStem(value) & 1) == (first & 1) ? [first, second] : [second, first],
  );
}

int getLifeStage(
  int stem,
  int branch, [
  EarthPalaceMode mode = EarthPalaceMode.fireEarth,
]) {
  _stem(stem);
  _branch(branch);
  var start = const [11, 6, 2, 9, 2, 9, 5, 0, 8, 3][stem];
  if (mode == EarthPalaceMode.waterEarth) {
    if (stem == 4) start = 8;
    if (stem == 5) start = 3;
  }
  return (stem & 1) == 0 ? (branch - start) % 12 : (start - branch) % 12;
}

class RelationFlags {
  final int flags;
  final int? combinedElement;
  const RelationFlags(this.flags, this.combinedElement);
  Map<String, Object?> toJson() => {
    'flags': flags,
    'combinedElement': combinedElement,
  };
}

class StemRelationFlag {
  static const combination = 1, clash = 2, restraint = 4;
}

class BranchRelationFlag {
  static const combination = 1,
      clash = 2,
      harm = 4,
      destruction = 8,
      punishment = 16,
      selfPunishment = 32,
      hiddenCombination = 64,
      severance = 128;
}

class BranchTripleRelationFlag {
  static const combination = 1, direction = 2, punishment = 4;
}

bool _pair(int a, int b, int c, int d) =>
    (a == c && b == d) || (a == d && b == c);
bool _triple(int a, int b, int c, List<int> g) =>
    a != b &&
    a != c &&
    b != c &&
    g.contains(a) &&
    g.contains(b) &&
    g.contains(c);
RelationFlags calculateStemRelation(int a, int b) {
  _stem(a);
  _stem(b);
  var flags = 0;
  int? element;
  if ((a + 5) % 10 == b) {
    flags |= 1;
    element = const [3, 2, 0, 1, 4, 3, 2, 0, 1, 4][a];
  }
  if (const [6, 7, 8, 9, -1, -1, 0, 1, 2, 3][a] == b) flags |= 2;
  if ((a + 4) % 10 == b || (b + 4) % 10 == a) flags |= 4;
  return RelationFlags(flags, element);
}

RelationFlags calculateBranchRelation(int a, int b) {
  _branch(a);
  _branch(b);
  var flags = 0;
  int? element;
  if (branchCombinationPartner[a] == b) {
    flags |= 1;
    element = const [3, 3, 1, 4, 2, 0, 3, 3, 0, 2, 4, 1][a];
  }
  if ((a + 6) % 12 == b) flags |= 2;
  if (const [7, 6, 5, 4, 3, 2, 1, 0, 11, 10, 9, 8][a] == b) flags |= 4;
  if (const [9, 4, 11, 6, 1, 8, 3, 10, 5, 0, 7, 2][a] == b) flags |= 8;
  if (a != b &&
      const [
        [0, 3],
        [2, 5],
        [2, 8],
        [5, 8],
        [1, 10],
        [1, 7],
        [7, 10],
      ].any((p) => _pair(a, b, p[0], p[1]))) {
    flags |= 16;
  }
  if (a == b && const [4, 6, 9, 11].contains(a)) flags |= 32;
  if (const [5, 2, 1, 8, -1, 0, 11, -1, 3, -1, -1, 6][a] == b) flags |= 64;
  if (const [5, -1, 9, 8, -1, 0, 11, -1, 3, 2, -1, 6][a] == b) flags |= 128;
  return RelationFlags(flags, element);
}

RelationFlags calculateBranchTripleRelation(int a, int b, int c) {
  _branch(a);
  _branch(b);
  _branch(c);
  var flags = 0;
  int? element;
  for (var i = 0; i < 4; i++) {
    if (_triple(a, b, c, branchTripleCombination[i])) {
      flags |= 1;
      element = tripleElement[i];
    }
    if (_triple(a, b, c, branchTripleDirection[i])) {
      flags |= 2;
      element = tripleElement[i];
    }
  }
  if (branchTriplePunishment.any((g) => _triple(a, b, c, g))) flags |= 4;
  return RelationFlags(flags, element);
}

class ExtraPillars {
  final int mingGong, shenGong, taiYuan, taiXi;
  const ExtraPillars(this.mingGong, this.shenGong, this.taiYuan, this.taiXi);
  Map<String, int> toJson() => {
    'mingGong': mingGong,
    'shenGong': shenGong,
    'taiYuan': taiYuan,
    'taiXi': taiXi,
  };
}

ExtraPillars calculateExtraPillars(int year, int month, int day, int hour) {
  final ys = ganzhiStem(year),
      mb = ganzhiBranch(month),
      hb = ganzhiBranch(hour);
  ganzhiStem(day);
  final mn = (mb + 10) % 12 + 1, mp = (12 - (mn - 1)) % 12;
  final ming = (mp + (3 - hb) % 12) % 12,
      shen = (mb + hb + 1) % 12,
      ss = (ys % 5 * 2 + 2) % 10;
  return ExtraPillars(
    makeGanzhi((ss + (ming + 10) % 12) % 10, ming),
    makeGanzhi((ss + (shen + 10) % 12) % 10, shen),
    advanceGanzhi(month, -9),
    makeGanzhi(
      (ganzhiStem(day) + 5) % 10,
      branchCombinationPartner[ganzhiBranch(day)],
    ),
  );
}

class DecodedPillar {
  final int value;
  DecodedPillar(this.value) {
    ganzhiStem(value);
  }
  int get stem => ganzhiStem(value);
  int get branch => ganzhiBranch(value);
  int get index => ganzhiIndex(value);
  String get stemName => heavenlyStems[stem];
  String get branchName => earthlyBranches[branch];
  String get name => ganzhiName(value);
  Map<String, Object> toJson() => {
    'value': value,
    'stem': stem,
    'branch': branch,
    'index': index,
    'stemName': stemName,
    'branchName': branchName,
    'name': name,
  };
}

int packPillar(int stem, int branch) => makeGanzhi(stem, branch);
DecodedPillar unpackPillar(int value) => DecodedPillar(value);

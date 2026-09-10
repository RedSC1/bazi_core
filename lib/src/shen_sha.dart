// Port of bazi-lite/src/shen-sha.ts. MPL-2.0.
part of '../bazi_core.dart';

const shenShaNameTable = [
  '天乙贵人',
  '驿马',
  '咸池（桃花）',
  '红鸾',
  '天喜',
  '羊刃',
  '飞刃',
  '福星贵人',
  '灾煞',
  '劫煞',
  '亡神',
  '空亡',
  '天厨贵人（本旬）',
  '天厨贵人',
  '德秀贵人',
  '天医',
  '血刃',
  '月德合',
  '勾煞',
  '绞煞',
  '元辰',
  '孤辰',
  '寡宿',
  '红艳煞',
  '金舆',
  '金神',
  '天赦日',
  '流霞',
  '丧门',
  '吊客',
  '披麻',
  '童子',
  '天德合',
  '三奇贵人（天）',
  '三奇贵人（地）',
  '三奇贵人（人）',
  '将星',
  '华盖',
  '魁罡',
  '十灵日',
  '八专日',
  '六秀日',
  '九丑日',
  '四废日',
  '十恶大败',
  '天罗地网',
  '阴差阳错',
  '孤鸾煞',
  '拱禄',
  '拱贵',
  '地转',
  '天转',
  '太极贵人',
  '文昌贵人',
  '国印贵人',
  '天德贵人',
  '月德贵人',
  '禄神',
  '日干学堂',
  '日干词馆',
  '正学堂',
  '正词馆',
  '官贵学堂',
  '官贵词馆',
  '官星学堂',
  '学堂会贵',
];
const _ty = [
  [1, 7],
  [0, 8],
  [9, 11],
  [9, 11],
  [1, 7],
  [0, 8],
  [1, 7],
  [2, 6],
  [3, 5],
  [3, 5],
];
const _yiMa = [
  [2],
  [11],
  [8],
  [5],
  [2],
  [11],
  [8],
  [5],
  [2],
  [11],
  [8],
  [5],
];
const _xianChi = [
  [9],
  [6],
  [3],
  [0],
  [9],
  [6],
  [3],
  [0],
  [9],
  [6],
  [3],
  [0],
];
const _hongLuan = [
  [3],
  [2],
  [1],
  [0],
  [11],
  [10],
  [9],
  [8],
  [7],
  [6],
  [5],
  [4],
];
const _tianXi = [
  [9],
  [8],
  [7],
  [6],
  [5],
  [4],
  [3],
  [2],
  [1],
  [0],
  [11],
  [10],
];
const _yangRen = [
  [3],
  [2],
  [6],
  [5],
  [6],
  [5],
  [9],
  [8],
  [0],
  [11],
];
const _feiRen = [
  [9],
  [8],
  [0],
  [11],
  [0],
  [11],
  [3],
  [2],
  [6],
  [5],
];
const _fuXing = [
  [2, 0],
  [3, 1],
  [2, 0],
  [11],
  [8],
  [7],
  [6],
  [5],
  [4],
  [3, 1],
];
const _zaiSha = [
  [6],
  [3],
  [0],
  [9],
  [6],
  [3],
  [0],
  [9],
  [6],
  [3],
  [0],
  [9],
];
const _jieSha = [
  [5],
  [2],
  [11],
  [8],
  [5],
  [2],
  [11],
  [8],
  [5],
  [2],
  [11],
  [8],
];
const _wangShen = [
  [11],
  [8],
  [5],
  [2],
  [11],
  [8],
  [5],
  [2],
  [11],
  [8],
  [5],
  [2],
];
const _tianChu = [
  [5],
  [6],
  [5],
  [6],
  [8],
  [9],
  [11],
  [0],
  [2],
  [3],
];
const _deXiu = [
  [0, 2, 4, 5, 7, 8, 9],
  [1, 6, 7],
  [2, 3, 4, 9],
  [0, 1, 3, 8],
  [0, 2, 4, 5, 7, 8, 9],
  [1, 6, 7],
  [2, 3, 4, 9],
  [0, 1, 3, 8],
  [0, 2, 4, 5, 7, 8, 9],
  [1, 6, 7],
  [2, 3, 4, 9],
  [0, 1, 3, 8],
];
const _tianYiMedicine = [
  [11],
  [0],
  [1],
  [2],
  [3],
  [4],
  [5],
  [6],
  [7],
  [8],
  [9],
  [10],
];
const _xueRen = [
  [6],
  [0],
  [1],
  [7],
  [2],
  [8],
  [3],
  [9],
  [4],
  [10],
  [5],
  [11],
];
const _yueDeHe = [
  [3],
  [1],
  [7],
  [5],
  [3],
  [1],
  [7],
  [5],
  [3],
  [1],
  [7],
  [5],
];
const _guChen = [
  [2],
  [2],
  [5],
  [5],
  [5],
  [8],
  [8],
  [8],
  [11],
  [11],
  [11],
  [2],
];
const _guaSu = [
  [10],
  [10],
  [1],
  [1],
  [1],
  [4],
  [4],
  [4],
  [7],
  [7],
  [7],
  [10],
];
const _hongYan = [
  [6],
  [6],
  [2],
  [7],
  [4],
  [4],
  [10],
  [9],
  [0],
  [8],
];
const _jinYu = [
  [4],
  [5],
  [7],
  [8],
  [7],
  [8],
  [10],
  [11],
  [1],
  [2],
];
const _liuXia = [
  [9],
  [10],
  [7],
  [8],
  [5],
  [6],
  [4],
  [3],
  [11],
  [2],
];
const _sangMen = [
  [2],
  [3],
  [4],
  [5],
  [6],
  [7],
  [8],
  [9],
  [10],
  [11],
  [0],
  [1],
];
const _diaoKe = [
  [10],
  [11],
  [0],
  [1],
  [2],
  [3],
  [4],
  [5],
  [6],
  [7],
  [8],
  [9],
];
const _piMa = [
  [9],
  [10],
  [11],
  [0],
  [1],
  [2],
  [3],
  [4],
  [5],
  [6],
  [7],
  [8],
];
const _jiangXing = [
  [0],
  [9],
  [6],
  [3],
  [0],
  [9],
  [6],
  [3],
  [0],
  [9],
  [6],
  [3],
];
const _huaGai = [
  [4],
  [1],
  [10],
  [7],
  [4],
  [1],
  [10],
  [7],
  [4],
  [1],
  [10],
  [7],
];
const _taiJi = [
  [0, 6],
  [0, 6],
  [9, 3],
  [9, 3],
  [4, 10, 1, 7],
  [4, 10, 1, 7],
  [2, 11],
  [2, 11],
  [5, 8],
  [5, 8],
];
const _wenChang = [
  [5],
  [6],
  [8],
  [9],
  [8],
  [9],
  [11],
  [0],
  [2],
  [3],
];
const _guoYin = [
  [10],
  [11],
  [1],
  [2],
  [1],
  [2],
  [4],
  [5],
  [7],
  [8],
];
const _yueDeGuiRen = [
  [8],
  [6],
  [2],
  [0],
  [8],
  [6],
  [2],
  [0],
  [8],
  [6],
  [2],
  [0],
];
const _luShen = [
  [2],
  [3],
  [5],
  [6],
  [5],
  [6],
  [8],
  [9],
  [11],
  [0],
];
const _riGanXueTang = [
  [11],
  [6],
  [2],
  [9],
  [2],
  [9],
  [5],
  [0],
  [8],
  [3],
];
const _riGanCiGuan = _luShen;

const _tianShe = [14, 30, 44, 0];
const _kuiGang = [16, 28, 34, 46];
const _shiLing = [40, 11, 52, 33, 54, 46, 26, 47, 38, 19];
const _baZhuan = [50, 51, 43, 34, 55, 56, 57, 49];
const _liuXiu = [42, 43, 24, 54, 25, 55];
const _jiuChou = [33, 24, 54, 15, 45, 27, 57, 48, 18];
const _siFei = [
  [56, 57],
  [48, 59],
  [50, 51],
  [42, 53],
];
const _shiEDaBai = [40, 41, 32, 23, 34, 25, 16, 17, 8, 59];
const _yinChaYangCuo = [12, 13, 14, 27, 28, 29, 42, 43, 44, 57, 58, 59];
const _guLuan = [41, 53, 47, 44, 50, 54, 48, 42];
const _diZhuan = [27, 54, 9, 12];
const _tianZhuan = [51, 42, 57, 48];
const _nayinZhangSheng = [8, 11, 5, 8, 2];
const _nayinLinGuan = [11, 2, 8, 11, 5];
const _nayinDiWang = [0, 3, 9, 0, 6];
const _stemElement = [1, 1, 4, 4, 3, 3, 2, 2, 0, 0];
const _officialElement = [3, 2, 4, 1, 0];
const _officialStem = [7, 6, 9, 8, 1, 0, 3, 2, 5, 4];

bool _contains(List<List<int>> table, int source, int target) =>
    table[source].contains(target);
bool _hasIndex(List<int> values, int index) => values.contains(index);
bool _sameXun(int a, int b) => ganzhiIndex(a) ~/ 10 == ganzhiIndex(b) ~/ 10;
bool _kongWangContains(int base, int target) =>
    getKongWang(base).contains(ganzhiBranch(target));
bool _unorderedPair(int a, int b, int c, int d) =>
    (a == c && b == d) || (a == d && b == c);
bool _isTianDeHe(int monthBranch, int target) {
  const stems = [-1, 1, 8, -1, 3, 2, -1, 5, 4, -1, 7, 6],
      branches = [8, -1, -1, 5, -1, -1, 2, -1, -1, 11, -1, -1];
  return ganzhiStem(target) == stems[monthBranch] ||
      ganzhiBranch(target) == branches[monthBranch];
}

bool _isTianDeGuiRen(int monthBranch, int target) {
  const stems = [-1, 6, 3, -1, 8, 7, -1, 0, 9, -1, 2, 1],
      branches = [5, -1, -1, 8, -1, -1, 11, -1, -1, 2, -1, -1];
  return ganzhiStem(target) == stems[monthBranch] ||
      ganzhiBranch(target) == branches[monthBranch];
}

enum ShenShaTarget {
  year,
  month,
  day,
  hour,
  mingGong,
  shenGong,
  taiYuan,
  taiXi,
  daYun,
  flowYear,
  flowMonth,
  flowDay,
  flowHour,
}

BigInt _shenShaBit(int id) {
  if (id < 0 || id >= 66) throw RangeError.range(id, 0, 65, 'id');
  return BigInt.one << id;
}

bool hasShenSha(BigInt bits, int id) => (bits & _shenShaBit(id)) != BigInt.zero;
List<int> shenShaIds(BigInt bits) => List.unmodifiable([
  for (var i = 0; i < 66; i++)
    if (hasShenSha(bits, i)) i,
]);
List<String> shenShaNames(BigInt bits) =>
    List.unmodifiable(shenShaIds(bits).map((i) => shenShaNameTable[i]));
(BigInt, BigInt) shenShaWords(BigInt bits) {
  final mask = (BigInt.one << 64) - BigInt.one;
  return (bits & mask, (bits >> 64) & mask);
}

class NatalShenShaBitsets {
  final BigInt year, month, day, hour;
  const NatalShenShaBitsets(this.year, this.month, this.day, this.hour);
  BigInt operator [](String key) => switch (key) {
    'year' => year,
    'month' => month,
    'day' => day,
    'hour' => hour,
    _ => throw ArgumentError.value(key),
  };
}

NatalShenShaBitsets collectNatalShenSha(
  BaziPillarAnalysis chart, {
  Gender? gender,
}) => NatalShenShaBitsets(
  collectTargetShenSha(
    chart,
    chart.pillars.year,
    ShenShaTarget.year,
    gender: gender,
  ),
  collectTargetShenSha(
    chart,
    chart.pillars.month,
    ShenShaTarget.month,
    gender: gender,
  ),
  collectTargetShenSha(
    chart,
    chart.pillars.day,
    ShenShaTarget.day,
    gender: gender,
  ),
  collectTargetShenSha(
    chart,
    chart.pillars.hour,
    ShenShaTarget.hour,
    gender: gender,
  ),
);
BigInt collectTargetShenSha(
  BaziPillarAnalysis chart,
  int target,
  ShenShaTarget targetKind, {
  Gender? gender,
}) {
  final year = chart.pillars.year,
      month = chart.pillars.month,
      day = chart.pillars.day,
      hour = chart.pillars.hour;
  final targetBranch = ganzhiBranch(target);
  final targetStem = ganzhiStem(target);
  final yearStem = ganzhiStem(year);
  final dayStem = ganzhiStem(day);
  final yearBranch = ganzhiBranch(year);
  final dayBranch = ganzhiBranch(day);
  final monthBranch = ganzhiBranch(month);
  final season = ((monthBranch + 10) % 12) ~/ 3;
  var result = BigInt.zero;
  void set(int id) {
    result |= BigInt.one << id;
  }

  if (_contains(_ty, yearStem, targetBranch) ||
      _contains(_ty, dayStem, targetBranch)) {
    set(0);
  }
  if (_contains(_yiMa, yearBranch, targetBranch) ||
      _contains(_yiMa, dayBranch, targetBranch)) {
    set(1);
  }
  if (_contains(_xianChi, yearBranch, targetBranch) ||
      _contains(_xianChi, dayBranch, targetBranch)) {
    set(2);
  }
  if (_contains(_hongLuan, yearBranch, targetBranch)) set(3);
  if (_contains(_tianXi, yearBranch, targetBranch)) set(4);
  if (_contains(_yangRen, dayStem, targetBranch)) set(5);
  if (_contains(_feiRen, dayStem, targetBranch)) set(6);
  if (_contains(_fuXing, yearStem, targetBranch) ||
      _contains(_fuXing, dayStem, targetBranch)) {
    set(7);
  }
  if (_contains(_zaiSha, yearBranch, targetBranch) ||
      _contains(_zaiSha, dayBranch, targetBranch)) {
    set(8);
  }
  if (_contains(_jieSha, yearBranch, targetBranch) ||
      _contains(_jieSha, dayBranch, targetBranch)) {
    set(9);
  }
  if (_contains(_wangShen, yearBranch, targetBranch) ||
      _contains(_wangShen, dayBranch, targetBranch)) {
    set(10);
  }
  if (_kongWangContains(year, target) || _kongWangContains(day, target)) {
    set(11);
  }
  if ((_sameXun(year, target) && targetStem == (yearStem + 2) % 10) ||
      (_sameXun(day, target) && targetStem == (dayStem + 2) % 10)) {
    set(12);
  }
  if (_contains(_tianChu, yearStem, targetBranch) ||
      _contains(_tianChu, dayStem, targetBranch)) {
    set(13);
  }
  if (_contains(_deXiu, monthBranch, targetStem)) set(14);
  if (_contains(_tianYiMedicine, monthBranch, targetBranch)) set(15);
  if (_contains(_xueRen, monthBranch, targetBranch)) set(16);
  if (_contains(_yueDeHe, monthBranch, targetStem)) set(17);

  if (gender != null) {
    final forward = (gender == Gender.male) == ((yearStem & 1) == 0);
    final plus3 = (yearBranch + 3) % 12;
    final plus9 = (yearBranch + 9) % 12;
    if ((forward && targetBranch == plus3) ||
        (!forward && targetBranch == plus9)) {
      set(18);
    }
    if ((forward && targetBranch == plus9) ||
        (!forward && targetBranch == plus3)) {
      set(19);
    }
    if (targetBranch == (yearBranch + (forward ? 7 : 5)) % 12) set(20);
    final hourStem = ganzhiStem(hour);
    final hourBranch = ganzhiBranch(hour);
    final yearNayin = getNayinElement(year).index;
    if (targetKind == ShenShaTarget.hour &&
        (dayStem == 0 || dayStem == 5) &&
        ((targetStem == 9 && targetBranch == 9) ||
            (targetStem == 5 && targetBranch == 5) ||
            (targetStem == 1 && targetBranch == 1))) {
      set(25);
    }
    if ((targetKind == ShenShaTarget.day || targetKind == ShenShaTarget.hour) &&
        (((season == 0 || season == 2) &&
                (targetBranch == 2 || targetBranch == 0)) ||
            ((season == 1 || season == 3) &&
                (targetBranch == 3 ||
                    targetBranch == 7 ||
                    targetBranch == 4)) ||
            ((yearNayin == 2 || yearNayin == 1) &&
                (targetBranch == 6 || targetBranch == 3)) ||
            ((yearNayin == 0 || yearNayin == 4) &&
                (targetBranch == 9 || targetBranch == 10)) ||
            (yearNayin == 3 && (targetBranch == 4 || targetBranch == 5)))) {
      set(31);
    }
    if (targetKind == ShenShaTarget.day) {
      final stems = [yearStem, ganzhiStem(month), dayStem, hourStem];
      if ([0, 4, 6].every((stem) => stems.contains(stem))) set(33);
      if ([1, 2, 3].every((stem) => stems.contains(stem))) set(34);
      if ([8, 9, 7].every((stem) => stems.contains(stem))) set(35);
    }
    if (yearNayin != 1 && yearNayin != 2) {
      final counterpart = targetBranch == 10
          ? 11
          : targetBranch == 11
          ? 10
          : targetBranch == 4
          ? 5
          : targetBranch == 5
          ? 4
          : -1;
      final hasCounterpart = [
        yearBranch,
        monthBranch,
        dayBranch,
        hourBranch,
      ].contains(counterpart);
      if (((targetBranch == 10 || targetBranch == 11) &&
              yearNayin == 4 &&
              gender == Gender.male &&
              hasCounterpart) ||
          ((targetBranch == 4 || targetBranch == 5) &&
              (yearNayin == 0 || yearNayin == 3) &&
              gender == Gender.female &&
              hasCounterpart)) {
        set(45);
      }
    }
    if (targetKind == ShenShaTarget.day &&
        dayStem == hourStem &&
        dayBranch != hourBranch) {
      if ((dayStem == 9 && _unorderedPair(dayBranch, hourBranch, 11, 1)) ||
          (dayStem == 3 && _unorderedPair(dayBranch, hourBranch, 5, 7)) ||
          (dayStem == 5 && _unorderedPair(dayBranch, hourBranch, 7, 5)) ||
          (dayStem == 4 && _unorderedPair(dayBranch, hourBranch, 4, 6))) {
        set(48);
      }
      if ((dayStem == 0 &&
              (_unorderedPair(dayBranch, hourBranch, 8, 10) ||
                  _unorderedPair(dayBranch, hourBranch, 2, 0))) ||
          (dayStem == 1 && _unorderedPair(dayBranch, hourBranch, 7, 9)) ||
          (dayStem == 4 && _unorderedPair(dayBranch, hourBranch, 8, 6)) ||
          (dayStem == 7 && _unorderedPair(dayBranch, hourBranch, 1, 3))) {
        set(49);
      }
    }
  }

  if (_contains(_guChen, yearBranch, targetBranch)) set(21);
  if (_contains(_guaSu, yearBranch, targetBranch)) set(22);
  if (_contains(_hongYan, dayStem, targetBranch)) set(23);
  if (_contains(_jinYu, dayStem, targetBranch)) set(24);
  if (_contains(_liuXia, dayStem, targetBranch)) set(27);
  if (_contains(_sangMen, yearBranch, targetBranch)) set(28);
  if (_contains(_diaoKe, yearBranch, targetBranch)) set(29);
  if (_contains(_piMa, yearBranch, targetBranch)) set(30);
  if (_contains(_jiangXing, yearBranch, targetBranch) ||
      _contains(_jiangXing, dayBranch, targetBranch)) {
    set(36);
  }
  if (_contains(_huaGai, yearBranch, targetBranch) ||
      _contains(_huaGai, dayBranch, targetBranch)) {
    set(37);
  }
  if (_contains(_taiJi, yearStem, targetBranch) ||
      _contains(_taiJi, dayStem, targetBranch)) {
    set(52);
  }
  if (_contains(_wenChang, yearStem, targetBranch) ||
      _contains(_wenChang, dayStem, targetBranch)) {
    set(53);
  }
  if (_contains(_guoYin, yearStem, targetBranch) ||
      _contains(_guoYin, dayStem, targetBranch)) {
    set(54);
  }
  if (_contains(_yueDeGuiRen, monthBranch, targetStem)) set(56);
  if (_isTianDeHe(monthBranch, target)) set(32);
  if (_isTianDeGuiRen(monthBranch, target)) set(55);
  if (_contains(_luShen, dayStem, targetBranch)) set(57);
  if (_contains(_riGanXueTang, dayStem, targetBranch)) set(58);
  if (_contains(_riGanCiGuan, dayStem, targetBranch)) set(59);
  final yearNayin = getNayinElement(year).index;
  final targetNayin = getNayinElement(target).index;
  if (yearNayin == targetNayin && targetBranch == _nayinZhangSheng[yearNayin]) {
    set(60);
  }
  if (yearNayin == targetNayin && targetBranch == _nayinLinGuan[yearNayin]) {
    set(61);
  }
  final officialElement = _officialElement[_stemElement[dayStem]];
  if (targetBranch == _nayinZhangSheng[officialElement]) set(62);
  if (targetBranch == _nayinLinGuan[officialElement]) set(63);
  if (targetBranch == _nayinZhangSheng[_stemElement[dayStem]] &&
      targetStem == _officialStem[dayStem]) {
    set(64);
  }
  if (targetBranch == _nayinDiWang[yearNayin] &&
      (_contains(_ty, yearStem, targetBranch) ||
          _contains(_ty, dayStem, targetBranch))) {
    set(65);
  }
  final targetIndex = ganzhiIndex(target);
  if (targetIndex == _diZhuan[season]) set(50);
  if (targetIndex == _tianZhuan[season]) set(51);
  if (targetKind == ShenShaTarget.day) {
    if (targetIndex == _tianShe[season]) set(26);
    if (_hasIndex(_kuiGang, targetIndex)) set(38);
    if (_hasIndex(_shiLing, targetIndex)) set(39);
    if (_hasIndex(_baZhuan, targetIndex)) set(40);
    if (_hasIndex(_liuXiu, targetIndex)) set(41);
    if (_hasIndex(_jiuChou, targetIndex)) set(42);
    if (_hasIndex(_siFei[season], targetIndex)) set(43);
    if (_hasIndex(_shiEDaBai, targetIndex)) set(44);
    if (_hasIndex(_yinChaYangCuo, targetIndex)) set(46);
    if (_hasIndex(_guLuan, targetIndex)) set(47);
  }
  return result;
}

/// Stable IDs shared with bazi-lite and the C++ rule layer.
class ShenShaId {
  static const tianYiGuiRen = 0;
  static const yiMa = 1;
  static const xianChiTaoHua = 2;
  static const hongLuan = 3;
  static const tianXi = 4;
  static const yangRen = 5;
  static const feiRen = 6;
  static const fuXingGuiRen = 7;
  static const zaiSha = 8;
  static const jieSha = 9;
  static const wangShen = 10;
  static const kongWang = 11;
  static const tianChuGuiRenXun = 12;
  static const tianChuGuiRen = 13;
  static const deXiuGuiRen = 14;
  static const tianYiMedicine = 15;
  static const xueRen = 16;
  static const yueDeHe = 17;
  static const gouSha = 18;
  static const jiaoSha = 19;
  static const yuanChen = 20;
  static const guChen = 21;
  static const guaSu = 22;
  static const hongYanSha = 23;
  static const jinYu = 24;
  static const jinShen = 25;
  static const tianSheDay = 26;
  static const liuXia = 27;
  static const sangMen = 28;
  static const diaoKe = 29;
  static const piMa = 30;
  static const tongZi = 31;
  static const tianDeHe = 32;
  static const sanQiTian = 33;
  static const sanQiDi = 34;
  static const sanQiRen = 35;
  static const jiangXing = 36;
  static const huaGai = 37;
  static const kuiGang = 38;
  static const shiLingDay = 39;
  static const baZhuanDay = 40;
  static const liuXiuDay = 41;
  static const jiuChouDay = 42;
  static const siFeiDay = 43;
  static const shiEDaBai = 44;
  static const tianLuoDiWang = 45;
  static const yinChaYangCuo = 46;
  static const guLuanSha = 47;
  static const gongLu = 48;
  static const gongGui = 49;
  static const diZhuan = 50;
  static const tianZhuan = 51;
  static const taiJiGuiRen = 52;
  static const wenChangGuiRen = 53;
  static const guoYinGuiRen = 54;
  static const tianDeGuiRen = 55;
  static const yueDeGuiRen = 56;
  static const luShen = 57;
  static const riGanXueTang = 58;
  static const riGanCiGuan = 59;
  static const zhengXueTang = 60;
  static const zhengCiGuan = 61;
  static const guanGuiXueTang = 62;
  static const guanGuiCiGuan = 63;
  static const guanXingXueTang = 64;
  static const xueTangHuiGui = 65;
}

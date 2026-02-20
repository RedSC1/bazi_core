//天干
enum TianGan {
  jia, // 甲 (0)
  yi, // 乙 (1)
  bing, // 丙 (2)
  ding, // 丁 (3)
  wu, // 戊 (4)
  ji, // 己 (5)
  geng, // 庚 (6)
  xin, // 辛 (7)
  ren, // 壬 (8)
  gui; // 癸 (9)

  String get label {
    List<String> labels = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    return labels[index];
  }

  bool get isYang => index % 2 == 0;
  bool get isYin => !isYang;

  static TianGan fromName(String str) {
    return TianGan.values.firstWhere(
      (e) => e.name == str || e.label == str, // ✅ 支持拼音(jia) 和 中文(甲)
      orElse: () => throw ArgumentError("Invalid TianGan: $str"),
    );
  }
}

/// 地支 (12个)
enum DiZhi {
  zi, // 子 (0)
  chou, // 丑 (1)
  yin, // 寅 (2)
  mao, // 卯 (3)
  chen, // 辰 (4)
  si, // 巳 (5)
  wu, // 午 (6)
  wei, // 未 (7)
  shen, // 申 (8)
  you, // 酉 (9)
  xu, // 戌 (10)
  hai; // 亥 (11)

  String get label {
    List<String> labels = [
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
    ];
    return labels[index];
  }

  static DiZhi fromName(String str) {
    return DiZhi.values.firstWhere(
      (e) => e.name == str || e.label == str, // ✅ 支持拼音(zi) 和 中文(子)
      orElse: () => throw ArgumentError("Invalid DiZhi: $str"),
    );
  }
}

class GanZhi {
  final TianGan gan;
  final DiZhi zhi;
  final int index;

  GanZhi(this.gan, this.zhi)
    : index = (6 * gan.index - 5 * zhi.index + 60) % 60;

  //获取前进后退x个step的干支，如甲子的下一个是乙丑
  GanZhi offset(int step) {
    final newStemIndex = _cycleIndex(gan.index, step, 10);
    final newBranchIndex = _cycleIndex(zhi.index, step, 12);

    return GanZhi(TianGan.values[newStemIndex], DiZhi.values[newBranchIndex]);
  }

  //处理环形索引
  int _cycleIndex(int current, int step, int mod) {
    return ((current + step) % mod + mod) % mod;
  }

  // 重载运算符
  GanZhi operator +(int step) => offset(step);
  GanZhi operator -(int step) => offset(-step);

  List<DiZhi> getKongWang() {
    int k1 = (10 - (index ~/ 10) * 2) % 12;
    if (k1 < 0) k1 += 12;
    int k2 = (k1 + 1) % 12;

    if (gan.isYang) {
      return (k1 % 2 == 0)
          ? [DiZhi.values[k1], DiZhi.values[k2]]
          : [DiZhi.values[k2], DiZhi.values[k1]];
    }
    return (k1 % 2 != 0)
        ? [DiZhi.values[k1], DiZhi.values[k2]]
        : [DiZhi.values[k2], DiZhi.values[k1]];
  }

  @override
  String toString() => "${gan.label}${zhi.label}";
}

class BaZi {
  //节气四柱八字
  final GanZhi year;
  final GanZhi month;
  final GanZhi day;
  final GanZhi time;

  const BaZi({
    required this.year,
    required this.month,
    required this.day,
    required this.time,
  });

  @override
  String toString() => "$year $month $day $time";
}

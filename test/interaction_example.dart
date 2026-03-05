import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 2026年2月4日 19:48 (丙午年 庚寅月 戊辰日 壬戌时)
  final chart = BaziChart.createBySolarDate(
    clockTime: AstroDateTime(2026, 2, 4, 19, 48),
    gender: Gender.male,
  );

  print('--- 八字排盘 (测试用例) ---');
  print('年柱: ${chart.bazi.year}');
  print('月柱: ${chart.bazi.month}');
  print('日柱: ${chart.bazi.day}');
  print('时柱: ${chart.bazi.time}');
  print('');

  // 1. 计算原局刑冲合害
  print('=== [原局刑冲合害结果] ===');
  final originalResults = chart.getAllInteractions();
  _printResults(originalResults);

  // 2. 模拟大运和流年介入
  print('\n=== [模拟外部介入刑冲合害] ===');
  final luckBranch = InteractionNode(PillarType.decade, DiZhi.mao);
  final annualBranch = InteractionNode(PillarType.flowYear, DiZhi.wei);

  final dynamicResults = chart.getInteractionsWith(
    otherBranches: [luckBranch, annualBranch],
  );
  _printResults(dynamicResults);
}

/// 将感应类型转换为中文术语
String _interactionToChinese(BaziInteraction type) {
  switch (type) {
    case BaziInteraction.stemCombination:
      return '天干五合';
    case BaziInteraction.stemClash:
      return '天干四冲';
    case BaziInteraction.stemRestraint:
      return '天干相克';
    case BaziInteraction.branchCombination:
      return '地支六合';
    case BaziInteraction.branchClash:
      return '地支六冲';
    case BaziInteraction.branchHarm:
      return '地支六害';
    case BaziInteraction.branchDestruction:
      return '地支六破';
    case BaziInteraction.branchTriplePunishment:
      return '三刑全';
    case BaziInteraction.branchPunishment:
      return '地支相刑';
    case BaziInteraction.branchSelfPunishment:
      return '地支自刑';
    case BaziInteraction.branchTripleCombination:
      return '地支三合局';
    case BaziInteraction.branchTripleDirection:
      return '地支三会局';
    case BaziInteraction.branchHalfCombination:
      return '地支半合';
    case BaziInteraction.branchArchingCombination:
      return '地支拱合';
    case BaziInteraction.branchHiddenCombination:
      return '地支暗合';
    case BaziInteraction.branchSeverance:
      return '地支相绝';
  }
}

void _printResults(List<InteractionResult> results) {
  if (results.isEmpty) {
    print('无刑冲合害关系。');
    return;
  }
  for (var res in results) {
    final typeName = _interactionToChinese(res.type);
    final nodesStr = res.nodes
        .map((n) => '${_pillarToName(n.pillar)}(${n.value})')
        .join('、');

    String output = '[$typeName] $nodesStr';
    if (res.combinedWuXing != null) {
      output += ' -> 合化结果: ${res.combinedWuXing.toString().split('.').last}';
    }
    print(output);
  }
}

String _pillarToName(PillarType type) {
  switch (type) {
    case PillarType.year:
      return '年支';
    case PillarType.month:
      return '月支';
    case PillarType.day:
      return '日支';
    case PillarType.hour:
      return '时支';
    case PillarType.mingGong:
      return '命宫';
    case PillarType.shenGong:
      return '身宫';
    case PillarType.taiYuan:
      return '胎元';
    case PillarType.taiXi:
      return '胎息';
    case PillarType.decade:
      return '大运';
    case PillarType.flowYear:
      return '流年';
    case PillarType.flowMonth:
      return '流月';
    case PillarType.flowDay:
      return '流日';
    case PillarType.flowHour:
      return '流时';
  }
}

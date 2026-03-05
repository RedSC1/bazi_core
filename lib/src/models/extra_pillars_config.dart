/// 配置附加柱 (命宫、身宫、胎元、胎息) 是否参与各项核心计算 (如神煞、刑冲合害)
class ExtraPillarsConfig {
  /// 是否启用命宫
  final bool enableMingGong;

  /// 是否启用身宫
  final bool enableShenGong;

  /// 是否启用胎元
  final bool enableTaiYuan;

  /// 是否启用胎息
  final bool enableTaiXi;

  const ExtraPillarsConfig({
    this.enableMingGong = false,
    this.enableShenGong = false,
    this.enableTaiYuan = false,
    this.enableTaiXi = false,
  });

  /// 是否有任意附加柱被启用
  bool get hasAnyEnabled =>
      enableMingGong || enableShenGong || enableTaiYuan || enableTaiXi;
}

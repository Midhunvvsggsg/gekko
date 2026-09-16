class RiskBriefing {
  final String title;
  final String summaryText;
  final List<String> safetyTips;
  final String riskLevel; // 'Low' | 'Moderate' | 'Heightened'

  RiskBriefing({
    required this.title,
    required this.summaryText,
    required this.safetyTips,
    required this.riskLevel,
  });
}

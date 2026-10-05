// Nova is a guided product walkthrough. It does not collect questions or call AI.
class NovaContext {
  const NovaContext({
    required this.area,
    required this.label,
    this.dealId,
    this.facts = const {},
    this.lesson,
  });
  final String area, label;
  final String? dealId, lesson;
  // Kept for source compatibility. These values are never read or sent by Nova.
  final Map<String, dynamic> facts;
}

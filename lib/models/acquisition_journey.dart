import 'learning_journey.dart';

class AcquisitionJourneyStage {
  const AcquisitionJourneyStage(
    this.id,
    this.title,
    this.subtitle,
    this.phaseId,
    this.documentIds,
  );
  final String id, title, subtitle, phaseId;
  final List<String> documentIds;
  LearningPhase get phase =>
      buyerLearningJourney.firstWhere((p) => p.id == phaseId);
}

const acquisitionJourneyStages = [
  AcquisitionJourneyStage(
    'find',
    'Finding a business',
    'Source and screen opportunities',
    'buyer-search',
    ['deal-brief', 'nda-brief'],
  ),
  AcquisitionJourneyStage(
    'value',
    'Valuation',
    'Understand the evidence behind the price',
    'buyer-screen',
    ['earnings', 'working-capital'],
  ),
  AcquisitionJourneyStage(
    'offer',
    'Making an offer',
    'Explore LOIs and negotiation',
    'buyer-offer',
    ['loi-brief'],
  ),
  AcquisitionJourneyStage(
    'diligence',
    'Due diligence',
    'Investigate financial and operational risks',
    'buyer-diligence',
    ['request-list', 'risk-log', 'agreement-review'],
  ),
  AcquisitionJourneyStage(
    'close',
    'Financing and closing',
    'Prepare funding, conditions and handover',
    'buyer-close',
    ['funding', 'closing', 'transition'],
  ),
];

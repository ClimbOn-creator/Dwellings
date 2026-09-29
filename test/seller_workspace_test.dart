import 'package:dwelling_iq/models/seller_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transfer path changes the actual transaction steps', () {
    final outside = tasksFor(
      TransferPath.outsideBuyer,
    ).map((t) => t.id).toSet();
    final family = tasksFor(TransferPath.family).map((t) => t.id).toSet();
    final management = tasksFor(
      TransferPath.management,
    ).map((t) => t.id).toSet();
    final partial = tasksFor(TransferPath.partial).map((t) => t.id).toSet();
    expect(outside, contains('confidential_marketing'));
    expect(outside, isNot(contains('family_alignment')));
    expect(family, contains('family_alignment'));
    expect(family, contains('successor_training'));
    expect(family, isNot(contains('confidential_marketing')));
    expect(management, contains('management_alignment'));
    expect(partial, contains('partial_governance'));
    expect(outside, isNot(contains('partial_governance')));
  });

  test('seller calculator separates value, assets and cash at closing', () {
    const estimate = SellerValuation(
      reportedEbitda: 260000,
      verifiedAddbacks: 20000,
      ownerPayInExpenses: 80000,
      replacementSalary: 95000,
      lowMultiple: 3,
      highMultiple: 5,
      tangibleAssets: 500000,
      inventory: 180000,
      receivables: 120000,
      liabilities: 150000,
      expectedPrice: 1200000,
      vendorNote: 150000,
      fees: 45000,
      debtPayoff: 250000,
    );
    expect(estimate.maintainableEbitda, 265000);
    expect(estimate.lowEnterpriseValue, 795000);
    expect(estimate.highEnterpriseValue, 1325000);
    expect(estimate.netAssetReference, 650000);
    expect(estimate.cashAtCloseBeforeTax, 755000);
  });

  test('seller calculator rejects unsupported negative inputs', () {
    const estimate = SellerValuation(
      reportedEbitda: 260000,
      verifiedAddbacks: -20000,
      ownerPayInExpenses: 0,
      replacementSalary: 80000,
      lowMultiple: 3,
      highMultiple: 5,
      tangibleAssets: -1,
      inventory: 0,
      receivables: 0,
      liabilities: 0,
      expectedPrice: 1000000,
      vendorNote: 1100000,
      fees: 0,
      debtPayoff: 0,
    );
    expect(estimate.earningsReady, isFalse);
    expect(estimate.assetsReady, isFalse);
    expect(estimate.proceedsReady, isFalse);
  });

  test('seller draft round-trips private progress and roles', () {
    final draft = SellerWorkspaceDraft(
      businessName: 'Harbour Company',
      path: TransferPath.management,
      targetDate: DateTime(2027, 7, 1),
      handoverMonths: 6,
      completedTasks: {'goals'},
      readyDocuments: {'statements'},
      teamNames: {'Legal counsel': 'A. Counsel'},
      numbers: {'ebitda': '260,000'},
    );
    final loaded = SellerWorkspaceDraft.fromJson(draft.toJson());
    expect(loaded.path, TransferPath.management);
    expect(loaded.targetDate, DateTime(2027, 7, 1));
    expect(loaded.completedTasks, contains('goals'));
    expect(loaded.readyDocuments, contains('statements'));
    expect(loaded.teamNames['Legal counsel'], 'A. Counsel');
    expect(loaded.numbers['ebitda'], '260,000');
  });
}

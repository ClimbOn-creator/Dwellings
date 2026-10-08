import 'site_copy_text.dart';
import 'package:flutter/material.dart';
import '../services/nova_calculator_fields.dart';

class CalculatorHelpInfo {
  const CalculatorHelpInfo(this.field, this.how, this.source);
  final NovaCalculatorField field;
  final String how, source;
}

const calculatorHowTo = <String, String>{
  "businessName":
      "Use the business\u2019s name or a private reference. This is a label, not a calculated amount.",
  "businessAsk":
      "Use the seller\u2019s quoted business price. Keep property priced separately unless it is explicitly included.",
  "businessRevenue":
      "Add sales for a consistent 12-month period, before subtracting operating expenses.",
  "businessEbitda":
      "Start with net income and add back interest, income taxes, depreciation and amortization. Reconcile it with the statements.",
  "businessAddbacks":
      "Total the individual nonrecurring or owner-specific costs you can document. Exclude ongoing costs needed by the buyer.",
  "businessOwnerComp":
      "Total owner salary and benefits already deducted in reported EBITDA. Enter 0 when they are already excluded.",
  "businessSalary":
      "Estimate the annual salary and benefits required to replace the owner\u2019s actual duties.",
  "businessCapex":
      "Estimate annual spending needed to keep existing operating assets usable; separate expansion projects.",
  "multipleLow":
      "Use the lower supported enterprise-value-to-EBITDA multiple from comparable transactions.",
  "multipleHigh":
      "Use the upper supported comparable multiple. Keep it at or above the low multiple.",
  "businessDown":
      "Cash paid toward the price \u00f7 asking price \u00d7 100. Enter 25 for 25%, not 0.25.",
  "businessInterest":
      "Use the annual loan interest rate as a percentage. Enter 7 for 7%.",
  "businessYears":
      "Use the loan\u2019s amortization period in years, which can differ from its renewal term.",
  "assetAsk":
      "Use the quoted price for the assets included in this transaction.",
  "assetEquipment":
      "Add supported current market values for the included equipment and vehicles, rather than their original purchase costs.",
  "assetInventory":
      "Count usable included stock and apply its supportable sale value. Exclude obsolete or unsaleable items.",
  "assetReceivables":
      "Add transferable customer balances expected to be collected, after allowances for doubtful accounts.",
  "assetIntangibles":
      "Use supportable values for transferable rights. Confirm that licenses and contracts can actually be assigned.",
  "assetCash":
      "Total cash that the agreement says will transfer at closing. Exclude cash retained by the seller.",
  "assetLiabilities":
      "Total the debts and obligations the buyer will assume under the agreement.",
  "assetMaintenance":
      "Total supported repair or replacement costs for deferred upkeep of the included assets.",
  "assetCosts":
      "Add estimated legal, appraisal, transfer and other purchase costs without counting them twice.",
  "assetRecovery":
      "Recoverable noncash asset proceeds \u00f7 their stated noncash asset value \u00d7 100. Enter 60 for 60%.",
  "creName":
      "Use the property\u2019s name or your private reference. It identifies the scenario.",
  "creAsk":
      "Use the quoted property purchase price; keep separately priced business assets out of this amount.",
  "creRent":
      "Add annual scheduled rent for all rentable units at the assumed occupancy before vacancy loss.",
  "creOther":
      "Add annual recurring parking, storage and other property income outside base rent.",
  "creVacancy":
      "Estimated annual vacancy and credit loss \u00f7 potential gross income \u00d7 100. Enter 5 for 5%.",
  "creExpenses":
      "Add recurring annual property operating costs. Exclude loan payments, income tax and reserves entered separately.",
  "creReserve":
      "Estimate annual funding for major component replacement over time. Avoid counting the same cost in operating expenses.",
  "creCap":
      "Comparable stabilized NOI \u00f7 property value \u00d7 100. The calculator estimates value as stabilized NOI \u00f7 the cap rate in decimal form.",
  "creDown":
      "Cash down payment \u00f7 property asking price \u00d7 100. Enter 30 for 30%.",
  "creInterest":
      "Use the property loan\u2019s annual interest rate as a percentage; enter 6.5 for 6.5%.",
  "creYears":
      "Use the property loan\u2019s amortization period in years, rather than its renewal term.",
  "creHold": "Enter the number of years between purchase and the assumed sale.",
  "creGrowth":
      "Use the expected annual change in NOI as a percentage. The scenario compounds it over the hold period.",
  "creExitCap":
      "Use a supported cap rate for the assumed sale. Projected exit NOI divided by this rate gives the scenario\u2019s sale value.",
  "ebitda":
      "Start with net income and add interest, income taxes, depreciation and amortization. Reconcile it with your annual statements.",
  "addbacks":
      "Add documented nonrecurring costs that will not continue for a new owner. Enter 0 when there are none.",
  "ownerPay":
      "Total your salary and benefits already deducted in EBITDA. Enter 0 if EBITDA already excludes them.",
  "replacementSalary":
      "Estimate the annual salary and benefits required to replace your operating duties.",
  "lowMultiple":
      "Use the lower supported EBITDA multiple from comparable business sales.",
  "highMultiple":
      "Use the upper supported comparable multiple, at or above the lower multiple.",
  "assets":
      "Add supportable market values of physical assets included in the sale.",
  "inventory":
      "Count usable included inventory and apply supportable sale values, excluding obsolete stock.",
  "receivables":
      "Total transferable customer balances likely to be collected, after doubtful-account allowances.",
  "liabilities":
      "Total obligations the buyer will assume. Keep debt you repay at closing out of this amount.",
  "price":
      "Use your proposed or agreed gross sale price before fees, debt repayment and payment deferrals.",
  "vendorNote":
      "Total the part of the price payable after closing. It cannot exceed the sale price; enter 0 if none.",
  "fees":
      "Add broker, legal, valuation and other selling costs. Enter 0 where no costs apply.",
  "debtPayoff":
      "Total business debt discharged from sale proceeds at closing. Do not include liabilities assumed by the buyer.",
};
CalculatorHelpInfo calculatorHelpFor(String key, {bool seller = false}) {
  final fields = seller
      ? novaSellerCalculatorFields
      : novaBuyerCalculatorFields;
  final field = fields.firstWhere((f) => f.key == key);
  final source =
      key.toLowerCase().contains('ask') || key == 'price' || key == 'vendorNote'
      ? 'The listing, proposed terms or purchase agreement.'
      : key.toLowerCase().contains('multiple') ||
            key == 'creCap' ||
            key == 'creExitCap'
      ? 'Comparable transaction evidence and a qualified valuation adviser.'
      : key.toLowerCase().contains('interest') ||
            key.toLowerCase().contains('years') ||
            key.toLowerCase().contains('down')
      ? 'Your financing assumptions, lender quote or loan term sheet.'
      : key.startsWith('cre')
      ? 'The rent roll, leases, property operating statements and building condition records.'
      : key.startsWith('asset') ||
            {'assets', 'inventory', 'receivables', 'liabilities'}.contains(key)
      ? 'The included asset schedule, condition reports, receivable aging and transaction agreement.'
      : 'Annual financial statements, payroll records and documented transaction assumptions.';
  return CalculatorHelpInfo(field, calculatorHowTo[key]!, source);
}

class CalculatorHelpController extends ChangeNotifier {
  static final instance = CalculatorHelpController();
  CalculatorHelpInfo? info;
  void open(CalculatorHelpInfo value) {
    info = value;
    notifyListeners();
  }

  void close() {
    if (info == null) return;
    info = null;
    notifyListeners();
  }
}

class CalculatorHelpRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) =>
      CalculatorHelpController.instance.close();
  @override
  void didPop(Route route, Route? previousRoute) =>
      CalculatorHelpController.instance.close();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) =>
      CalculatorHelpController.instance.close();
}

class CalculatorHelpHost extends StatelessWidget {
  const CalculatorHelpHost({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: CalculatorHelpController.instance,
    builder: (context, _) {
      final info = CalculatorHelpController.instance.info;
      return Stack(
        children: [
          child,
          if (info != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 72,
              bottom: MediaQuery.paddingOf(context).bottom,
              right: 0,
              width: MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width - 24
                  : 350,
              child: Material(
                color: const Color(0xFFE9EDE7),
                elevation: 12,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: SiteCopyText(
                                'pebble.calculator.help.title',
                                'Calculator guide',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('calculator_help_close'),
                              onPressed:
                                  CalculatorHelpController.instance.close,
                              icon: const Icon(
                                Icons.close,
                                semanticLabel: 'Close calculator guide',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SiteCopyText(
                                'pebble.calculator.help.${info.field.key}.label',
                                info.field.label,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Color(0xFF164F3D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              _section(
                                'pebble.calculator.help.${info.field.key}.definition',
                                'What is it?',
                                info.field.help,
                              ),
                              _section(
                                'pebble.calculator.help.${info.field.key}.calculation',
                                'How to calculate it',
                                info.how,
                              ),
                              _section(
                                'pebble.calculator.help.${info.field.key}.example',
                                'Example',
                                info.field.example,
                              ),
                              _section(
                                'pebble.calculator.help.${info.field.key}.source',
                                'Where to find it',
                                info.source,
                              ),
                              const SizedBox(height: 12),
                              const SiteCopyText(
                                'pebble.calculator.help.switch',
                                'Use the info buttons to switch fields. Your figures stay as you entered them.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF536057),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
  Widget _section(String contentKey, String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteCopyText(
          'pebble.calculator.help.section.$title',
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF164F3D),
          ),
        ),
        const SizedBox(height: 7),
        SiteCopyText(
          contentKey,
          body,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF33463C),
          ),
        ),
      ],
    ),
  );
}

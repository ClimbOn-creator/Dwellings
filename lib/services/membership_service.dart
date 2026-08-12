import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

enum MemberType {
  homebuyer,
  investor,
  businessBuyer,
  realtor,
  mortgageBroker,
  lawyer,
  accountant,
  lender,
  businessBroker,
  maLawyer,
  qualityOfEarnings,
  commercialLender,
  taxAdvisor,
  insuranceAdvisor,
  humanResources,
  cybersecurity,
  industryAdvisor,
  wealthManager,
}

extension MemberTypeDetails on MemberType {
  String get databaseValue => switch (this) {
    MemberType.homebuyer => 'homebuyer',
    MemberType.investor => 'investor',
    MemberType.businessBuyer => 'business_buyer',
    MemberType.realtor => 'realtor',
    MemberType.mortgageBroker => 'mortgage_broker',
    MemberType.lawyer => 'lawyer',
    MemberType.accountant => 'accountant',
    MemberType.lender => 'lender',
    MemberType.businessBroker => 'business_broker',
    MemberType.maLawyer => 'ma_lawyer',
    MemberType.qualityOfEarnings => 'quality_of_earnings',
    MemberType.commercialLender => 'commercial_lender',
    MemberType.taxAdvisor => 'tax_advisor',
    MemberType.insuranceAdvisor => 'insurance_advisor',
    MemberType.humanResources => 'human_resources',
    MemberType.cybersecurity => 'cybersecurity',
    MemberType.industryAdvisor => 'industry_advisor',
    MemberType.wealthManager => 'wealth_manager',
  };

  String get label => switch (this) {
    MemberType.homebuyer => 'Homebuyer',
    MemberType.investor => 'Property investor',
    MemberType.businessBuyer => 'Business buyer',
    MemberType.realtor => 'Realtor',
    MemberType.mortgageBroker => 'Mortgage broker',
    MemberType.lawyer => 'Property lawyer',
    MemberType.accountant => 'Accountant',
    MemberType.lender => 'Bank or lender',
    MemberType.businessBroker => 'Business broker',
    MemberType.maLawyer => 'M&A lawyer',
    MemberType.qualityOfEarnings => 'QOE professional',
    MemberType.commercialLender => 'Commercial lender',
    MemberType.taxAdvisor => 'Tax adviser',
    MemberType.insuranceAdvisor => 'Insurance adviser',
    MemberType.humanResources => 'HR specialist',
    MemberType.cybersecurity => 'Cybersecurity consultant',
    MemberType.industryAdvisor => 'Industry adviser',
    MemberType.wealthManager => 'Wealth manager',
  };

  IconData get icon => switch (this) {
    MemberType.homebuyer => Icons.home_outlined,
    MemberType.investor => Icons.query_stats_outlined,
    MemberType.businessBuyer => Icons.storefront_outlined,
    MemberType.realtor => Icons.real_estate_agent_outlined,
    MemberType.mortgageBroker => Icons.handshake_outlined,
    MemberType.lawyer => Icons.gavel_outlined,
    MemberType.accountant => Icons.calculate_outlined,
    MemberType.lender => Icons.account_balance_outlined,
    MemberType.businessBroker => Icons.handshake_outlined,
    MemberType.maLawyer => Icons.balance_outlined,
    MemberType.qualityOfEarnings => Icons.fact_check_outlined,
    MemberType.commercialLender => Icons.account_balance_outlined,
    MemberType.taxAdvisor => Icons.receipt_long_outlined,
    MemberType.insuranceAdvisor => Icons.shield_outlined,
    MemberType.humanResources => Icons.groups_outlined,
    MemberType.cybersecurity => Icons.security_outlined,
    MemberType.industryAdvisor => Icons.insights_outlined,
    MemberType.wealthManager => Icons.savings_outlined,
  };

  bool get isProfessional =>
      this != MemberType.homebuyer &&
      this != MemberType.investor &&
      this != MemberType.businessBuyer;
}

class MembershipService {
  static Future<void> submit(Map<String, dynamic> application) async {
    if (!BackendService.configured) {
      throw StateError('Membership applications are temporarily unavailable.');
    }
    await Supabase.instance.client.from('membership_applications').insert({
      ...application,
      'user_id': BackendService.user?.id,
    });
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

enum MemberType {
  homebuyer,
  investor,
  realtor,
  mortgageBroker,
  lawyer,
  accountant,
  lender,
}

extension MemberTypeDetails on MemberType {
  String get databaseValue => switch (this) {
    MemberType.homebuyer => 'homebuyer',
    MemberType.investor => 'investor',
    MemberType.realtor => 'realtor',
    MemberType.mortgageBroker => 'mortgage_broker',
    MemberType.lawyer => 'lawyer',
    MemberType.accountant => 'accountant',
    MemberType.lender => 'lender',
  };

  String get label => switch (this) {
    MemberType.homebuyer => 'Homebuyer',
    MemberType.investor => 'Property investor',
    MemberType.realtor => 'Realtor',
    MemberType.mortgageBroker => 'Mortgage broker',
    MemberType.lawyer => 'Property lawyer',
    MemberType.accountant => 'Accountant',
    MemberType.lender => 'Bank or lender',
  };

  IconData get icon => switch (this) {
    MemberType.homebuyer => Icons.home_outlined,
    MemberType.investor => Icons.query_stats_outlined,
    MemberType.realtor => Icons.real_estate_agent_outlined,
    MemberType.mortgageBroker => Icons.handshake_outlined,
    MemberType.lawyer => Icons.gavel_outlined,
    MemberType.accountant => Icons.calculate_outlined,
    MemberType.lender => Icons.account_balance_outlined,
  };

  bool get isProfessional =>
      this != MemberType.homebuyer && this != MemberType.investor;
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

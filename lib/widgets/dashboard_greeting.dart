import 'dart:async';
import 'package:flutter/material.dart';
import 'buyer_greeting.dart';

String dashboardSalutation(DateTime time) => switch (time.hour) {
  < 5 => 'Working late',
  < 12 => 'Good morning',
  < 17 => 'Good afternoon',
  < 21 => 'Good evening',
  _ => 'Working late',
};

/// Shares the Buyer's horizontal reveal and refreshes the local time greeting.
class DashboardGreeting extends StatefulWidget {
  const DashboardGreeting({
    super.key,
    required this.summary,
    this.emoji = '👋',
  });
  final String summary, emoji;
  @override
  State<DashboardGreeting> createState() => _DashboardGreetingState();
}

class _DashboardGreetingState extends State<DashboardGreeting> {
  late final Timer _clock;
  DateTime _now = DateTime.now();
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BuyerGreeting(
    greeting: '${dashboardSalutation(_now)} ${widget.emoji}',
    summary: widget.summary,
  );
}

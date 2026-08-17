import 'package:flutter/material.dart';

import 'auth_button.dart';
import 'brand_logo.dart';

/// Shared Affinity site footer. The historical class name remains so every
/// existing screen adopts the new non-promotional footer automatically.
class MembershipFooter extends StatelessWidget {
  const MembershipFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final columns = const [
      _FooterColumn(
        title: 'THE ACQUISITION PATH',
        items: ['Blueprint', 'Buyer readiness', 'Deal screen', 'Pipeline'],
      ),
      _FooterColumn(
        title: 'PROFESSIONALS',
        items: [
          'Member Studio',
          'Expert directory',
          'Buyer leads',
          'Consulting',
        ],
      ),
      _FooterColumn(
        title: 'AFFINITY',
        items: ['Our approach', 'Privacy', 'Terms', 'Contact'],
      ),
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 24 : 42,
        48,
        compact ? 24 : 42,
        30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF030307),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FooterIdentity(),
                const SizedBox(height: 36),
                ...columns.map(
                  (column) => Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: column,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 4, child: _FooterIdentity()),
                for (final column in columns) Expanded(flex: 2, child: column),
              ],
            ),
          const SizedBox(height: 38),
          Divider(color: Colors.white.withValues(alpha: .12)),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: Text(
                  '© 2026 AFFINITY',
                  style: TextStyle(
                    color: Color(0xFF71717F),
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              AuthButton(dark: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterIdentity extends StatelessWidget {
  const _FooterIdentity();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AffinityLogo(size: 48),
      SizedBox(height: 28),
      SizedBox(
        width: 280,
        child: Text(
          'Better judgment for the business you choose next.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.08,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 18),
      for (final item in items) ...[
        Text(
          item,
          style: const TextStyle(color: Color(0xFF898995), height: 1.4),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

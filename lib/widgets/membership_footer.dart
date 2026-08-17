import 'package:flutter/material.dart';

import 'auth_button.dart';
import 'brand_logo.dart';

/// Full-width site footer. The historical class name is retained so every
/// existing screen receives the new footer without route-by-route migration.
class MembershipFooter extends StatelessWidget {
  const MembershipFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final compact = viewport < 760;
    final columns = const [
      _FooterColumn(
        title: 'ACQUISITION PATH',
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
    return UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: viewport,
        child: Container(
          color: const Color(0xFF053827),
          padding: EdgeInsets.fromLTRB(
            compact ? 26 : 64,
            compact ? 54 : 76,
            compact ? 26 : 64,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FooterIdentity(),
                    const SizedBox(height: 42),
                    ...columns.map(
                      (column) => Padding(
                        padding: const EdgeInsets.only(bottom: 30),
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
                    for (final column in columns)
                      Expanded(flex: 2, child: column),
                  ],
                ),
              const SizedBox(height: 46),
              const Divider(color: Color(0xFF526058)),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      '© 2026 AFFINITY · BUSINESS ACQUISITION, MADE NAVIGABLE',
                      style: TextStyle(
                        color: Color(0xFFAEB8B2),
                        fontSize: 9,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  AuthButton(dark: true),
                ],
              ),
            ],
          ),
        ),
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
      AffinityFooterLogo(width: 300),
      SizedBox(height: 24),
      SizedBox(
        width: 300,
        child: Text(
          'Better judgment for the business you choose next.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.08,
            fontWeight: FontWeight.w600,
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
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 20),
      for (final item in items) ...[
        Text(item, style: const TextStyle(color: Color(0xFFB6C0BA))),
        const SizedBox(height: 12),
      ],
    ],
  );
}

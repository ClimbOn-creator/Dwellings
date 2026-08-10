import 'package:flutter/material.dart';

import 'brand_logo.dart';
import 'auth_button.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({
    super.key,
    required this.onHome,
    required this.onAbout,
    required this.onTeam,
    required this.onMember,
  });

  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onTeam;
  final VoidCallback onMember;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Container(
      color: const Color(0xFF050510),
      padding: EdgeInsets.fromLTRB(
        compact ? 22 : 54,
        58,
        compact ? 22 : 54,
        30,
      ),
      child: Column(
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Identity(onTap: onHome),
                const SizedBox(height: 34),
                _FooterLinks(
                  onAbout: onAbout,
                  onTeam: onTeam,
                  onMember: onMember,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Identity(onTap: onHome)),
                _FooterLinks(
                  onAbout: onAbout,
                  onTeam: onTeam,
                  onMember: onMember,
                ),
              ],
            ),
          const SizedBox(height: 48),
          Container(height: 1, color: Colors.white.withValues(alpha: .1)),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: Text(
                  '© 2026 DWELLINGSIQ',
                  style: TextStyle(
                    color: Color(0xFF777787),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'PROPERTY INTELLIGENCE · CANADA',
                style: TextStyle(
                  color: Color(0xFF777787),
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DwellingIqLogo(size: 50),
        SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DWELLINGSIQ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'DECIDE WITH CLARITY.',
              style: TextStyle(
                color: Color(0xFF8C8C9C),
                fontSize: 8,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({
    required this.onAbout,
    required this.onTeam,
    required this.onMember,
  });
  final VoidCallback onAbout;
  final VoidCallback onTeam;
  final VoidCallback onMember;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      const AuthButton(dark: true),
      _FooterButton(label: 'ABOUT', onTap: onAbout),
      _FooterButton(label: 'TEAM', onTap: onTeam),
      _FooterButton(
        label: 'BECOME A MEMBER',
        onTap: onMember,
        highlighted: true,
      ),
    ],
  );
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: highlighted ? Colors.white : const Color(0xFFC7C7D2),
      backgroundColor: highlighted
          ? const Color(0xFF7657FF)
          : Colors.transparent,
      side: BorderSide(
        color: highlighted ? const Color(0xFF7657FF) : Colors.white24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

class LearningExampleCover extends StatelessWidget {
  const LearningExampleCover({
    super.key,
    required this.index,
    this.compact = false,
  });
  final int index;
  final bool compact;
  static const colors = [
    Color(0xFF356D75),
    Color(0xFF586DA2),
    Color(0xFFA16A47),
    Color(0xFF706A94),
  ];
  static const icons = [
    Icons.storefront_outlined,
    Icons.account_balance_outlined,
    Icons.groups_outlined,
    Icons.handshake_outlined,
  ];
  static const labels = ['ACQUISITION', 'FINANCING', 'SUCCESSION', 'TRANSFER'];
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(compact ? 10 : 14),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[index],
            Color.lerp(colors[index], Colors.black, .28)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Center(
            child: Icon(
              icons[index],
              size: compact ? 38 : 82,
              color: Colors.white.withValues(alpha: .9),
            ),
          ),
          if (!compact)
            Positioned(
              left: 22,
              bottom: 18,
              child: Text(
                labels[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

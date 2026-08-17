import 'package:flutter/material.dart';

import 'acquisition_step_bar.dart';

/// A landing-page-style editorial opening for every acquisition step.
class AcquisitionEditorialHeader extends StatelessWidget {
  const AcquisitionEditorialHeader({
    super.key,
    required this.currentStep,
    required this.onSelected,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final int currentStep;
  final ValueChanged<int> onSelected;
  final String kicker;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AcquisitionStepBar(currentStep: currentStep, onSelected: onSelected),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFCF9).withValues(alpha: .97),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 34,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final copy = Padding(
              padding: EdgeInsets.all(compact ? 24 : 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF171717),
                      fontSize: compact ? 38 : 54,
                      height: .98,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2.7,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 590),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF625E58),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            );
            final number = Container(
              width: compact ? double.infinity : 190,
              height: compact ? 108 : null,
              color: accent,
              padding: const EdgeInsets.all(22),
              alignment: compact ? Alignment.centerLeft : Alignment.bottomLeft,
              child: Text(
                '0${currentStep + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 66,
                  height: .9,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -4,
                ),
              ),
            );
            return compact
                ? Column(children: [number, copy])
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: copy),
                        number,
                      ],
                    ),
                  );
          },
        ),
      ),
    ],
  );
}

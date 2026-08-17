import 'package:flutter/material.dart';

class AcquisitionStepBar extends StatelessWidget {
  const AcquisitionStepBar({
    super.key,
    required this.currentStep,
    required this.onSelected,
  });

  final int currentStep;
  final ValueChanged<int> onSelected;

  static const _steps = ['Blueprint', 'Readiness', 'Deal screen', 'Pipeline'];

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F6F1).withValues(alpha: .96),
      border: const Border(
        top: BorderSide(color: Color(0xFF244E43), width: 2),
        bottom: BorderSide(color: Color(0xFFD6D1CA)),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP ${currentStep + 1} OF ${_steps.length} · ${_steps[currentStep].toUpperCase()}',
          style: const TextStyle(
            color: Color(0xFF5F5B56),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 11),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 700;
            final steps = Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (var index = 0; index < _steps.length; index++)
                  InkWell(
                    onTap: () => onSelected(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: index == currentStep
                                ? const Color(0xFF244E43)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        '${index + 1}. ${_steps[index]}',
                        style: TextStyle(
                          color: index == currentStep
                              ? const Color(0xFF244E43)
                              : const Color(0xFF5F5B56),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
            final controls = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentStep > 0)
                  TextButton.icon(
                    onPressed: () => onSelected(currentStep - 1),
                    icon: const Icon(Icons.arrow_back, size: 17),
                    label: const Text('Previous'),
                  ),
                if (currentStep < _steps.length - 1)
                  FilledButton.icon(
                    onPressed: () => onSelected(currentStep + 1),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF252525),
                      foregroundColor: Colors.white,
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 17),
                    label: const Text('Next step'),
                  ),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [steps, const SizedBox(height: 10), controls],
              );
            }
            return Row(
              children: [
                Expanded(child: steps),
                const SizedBox(width: 12),
                controls,
              ],
            );
          },
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'home_brand_button.dart';
import 'site_copy_text.dart';

/// Keeps the current dashboard identifiable even when the toolbar is narrow.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.label,
    required this.contentKey,
  });
  final String label, contentKey;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final name = SiteCopyText(
        contentKey,
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );
      if (box.maxWidth < 240 || MediaQuery.sizeOf(context).width < 1100) {
        return InkWell(
          onTap: () => HomeBrandButton.open(context),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width < 700 ? 56 : 130,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: name,
            ),
          ),
        );
      }
      return Row(
        children: [
          const HomeBrandButton(size: 48, dark: false),
          const SizedBox(width: 18),
          Flexible(child: name),
        ],
      );
    },
  );
}

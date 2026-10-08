import '../services/nova_training_controller.dart';
import 'calculator_help_sidebar.dart';
import 'package:flutter/material.dart';

import '../screens/acquisition_support_page.dart';
import 'brand_logo.dart';
import '../services/app_tunnel.dart';

class HomeBrandButton extends StatelessWidget {
  const HomeBrandButton({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.dark = true,
  });

  final double size;
  final bool showWordmark;
  final bool dark;

  static void open(BuildContext context) {
    NovaTrainingController.instance.pause();
    CalculatorHelpController.instance.close();
    AppTunnelController.select(AppTunnel.landing);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AcquisitionSupportPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Affinity home',
      child: InkWell(
        onTap: () => open(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AffinityLogo(
            size: size,
            showWordmark: showWordmark,
            dark: dark,
          ),
        ),
      ),
    );
  }
}

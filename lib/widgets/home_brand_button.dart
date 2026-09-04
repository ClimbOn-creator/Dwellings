import 'package:flutter/material.dart';

import '../screens/acquisition_support_page.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import 'brand_logo.dart';
import 'profile_photo.dart';

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

  static void open(BuildContext context) =>
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AcquisitionSupportPage()),
        (_) => false,
      );

  @override
  Widget build(BuildContext context) {
    final signedIn = BackendService.user != null;
    return Semantics(
      button: true,
      label: signedIn ? 'Your profile photo, Affinity home' : 'Affinity home',
      child: InkWell(
        onTap: () => open(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: signedIn
              ? FutureBuilder<AccountProfile?>(
                  future: AccountService.loadProfile(),
                  builder: (context, snapshot) => ProfilePhoto(
                    size: size,
                    photoUrl: snapshot.data?.photoUrl ?? '',
                    borderRadius: BorderRadius.circular(size * .3),
                  ),
                )
              : AffinityLogo(
                  size: size,
                  showWordmark: showWordmark,
                  dark: dark,
                ),
        ),
      ),
    );
  }
}

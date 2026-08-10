import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth_page.dart';
import '../screens/profile_page.dart';
import '../services/backend_service.dart';

class AuthButton extends StatefulWidget {
  const AuthButton({super.key, this.dark = true, this.compact = false});
  final bool dark;
  final bool compact;

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = BackendService.authChanges?.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _open() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BackendService.user == null ? const AuthPage() : const ProfilePage(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final signedIn = BackendService.user != null;
    final foreground = widget.dark ? Colors.white : const Color(0xFF050510);
    return TextButton.icon(
      onPressed: _open,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 14,
          vertical: 12,
        ),
      ),
      icon: Icon(
        signedIn ? Icons.account_circle_outlined : Icons.person_outline,
        size: 18,
      ),
      label: widget.compact
          ? const SizedBox.shrink()
          : Text(
              signedIn ? 'PROFILE' : 'SIGN IN',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
    );
  }
}

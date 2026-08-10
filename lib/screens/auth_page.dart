import 'package:flutter/material.dart';

import '../services/backend_service.dart';
import '../widgets/brand_logo.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await BackendService.signInWithGoogle();
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = 'Google sign-in is not available yet. $error',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _emailLink() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await BackendService.sendMagicLink(email);
      if (mounted) {
        setState(
          () => _message = 'Check your email for your secure sign-in link.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not send the link. $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await BackendService.signOut();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = BackendService.user;
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          Positioned(
            right: -180,
            top: -220,
            child: Container(
              width: 620,
              height: 620,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_purple.withValues(alpha: .36), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const DwellingIqLogo(size: 48),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                      Text(
                        user == null
                            ? 'Your property decisions, saved.'
                            : 'You’re signed in.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          height: .98,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -2.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        user == null
                            ? 'Sign in only when you want to save analyses, manage applications or return to your work on another device.'
                            : user.email ??
                                  'Your DwellingsIQ account is active.',
                        style: const TextStyle(
                          color: Color(0xFFAAAAB8),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _paper,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: user == null
                            ? _signInForm()
                            : _accountPanel(user.email ?? 'Account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signInForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: _loading || !BackendService.googleAuthEnabled
            ? null
            : _google,
        icon: const Text(
          'G',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        label: Text(
          BackendService.googleAuthEnabled
              ? 'Continue with Google'
              : 'Google sign-in · setup required',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          side: const BorderSide(color: Color(0xFFD9D9E1)),
          padding: const EdgeInsets.symmetric(vertical: 19),
        ),
      ),
      if (!BackendService.googleAuthEnabled) ...[
        const SizedBox(height: 10),
        const Text(
          'Email sign-in works now. Google will switch on after its OAuth credentials are connected.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF777785), fontSize: 11, height: 1.4),
        ),
      ],
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('or', style: TextStyle(color: Color(0xFF777785))),
            ),
            Expanded(child: Divider()),
          ],
        ),
      ),
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email address'),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _loading ? null : _emailLink,
        style: FilledButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 19),
        ),
        child: Text(_loading ? 'Please wait…' : 'Email me a secure link'),
      ),
      if (_message != null) ...[
        const SizedBox(height: 18),
        Text(
          _message!,
          style: const TextStyle(
            color: Color(0xFF5B21B6),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
      const SizedBox(height: 20),
      const Text(
        'Sign-in is optional. You can use the analysis model without creating an account.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF777785), fontSize: 11, height: 1.5),
      ),
    ],
  );

  Widget _accountPanel(String email) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.check_circle, color: _purple, size: 42),
      const SizedBox(height: 16),
      Text(
        email,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 24),
      OutlinedButton(onPressed: _signOut, child: const Text('Sign out')),
    ],
  );
}

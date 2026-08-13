import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/topo_background.dart';
import '../widgets/app_navigation_menu.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onAuthenticated});

  final VoidCallback? onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _jobTitle = TextEditingController();
  final _company = TextEditingController();
  AccountRole _role = AccountRole.user;
  String _employmentType = 'company';
  bool _creating = false;
  bool _loading = false;
  bool _obscure = true;
  String? _message;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _username,
      _email,
      _password,
      _confirmPassword,
      _jobTitle,
      _company,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await BackendService.signInWithGoogle();
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Google sign-in could not start. $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (_creating) {
        if (_password.text != _confirmPassword.text) {
          throw const FormatException('Passwords do not match.');
        }
        final response = await AccountService.signUp(
          fullName: _fullName.text,
          username: _username.text,
          email: _email.text,
          password: _password.text,
          role: _role,
          jobTitle: _role == AccountRole.user ? null : _jobTitle.text,
          companyName: _role == AccountRole.user ? null : _company.text,
          employmentType: _role == AccountRole.user ? null : _employmentType,
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(
            () => _message =
                'Account created. Confirm your email, then sign in with your password.',
          );
        } else {
          _finishAuthentication();
        }
      } else {
        await AccountService.signIn(_email.text, _password.text);
        if (mounted) _finishAuthentication();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error
              .toString()
              .replaceFirst('AuthException(message: ', '')
              .replaceFirst(', statusCode: 400, code: null)', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  void _finishAuthentication() {
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B0B16),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF171722), Color(0xFF090914)],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: TopoLinesPainter(opacity: .11)),
          ),
        ),
        Positioned(
          right: -180,
          top: -220,
          child: Container(
            width: 620,
            height: 620,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_purple.withValues(alpha: .2), Colors.transparent],
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const HomeBrandButton(size: 48),
                        const Spacer(),
                        const AppNavigationMenu(),
                      ],
                    ),
                    const SizedBox(height: 64),
                    Text(
                      _creating
                          ? 'Create your DwellingsIQ account.'
                          : 'Welcome back.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        height: .98,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -2.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _creating
                          ? 'One account works for buyers, investors and every professional on the property team.'
                          : 'Sign in to restore your calculator, saved analyses and selected team.',
                      style: const TextStyle(
                        color: Color(0xFFAAAAB8),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Sign in'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Create account'),
                                ),
                              ],
                              selected: {_creating},
                              onSelectionChanged: (value) => setState(() {
                                _creating = value.first;
                                _message = null;
                              }),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed:
                                  _loading || !BackendService.googleAuthEnabled
                                  ? null
                                  : _google,
                              icon: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              label: Text(
                                BackendService.googleAuthEnabled
                                    ? 'Continue with Google'
                                    : 'Google sign-in · setup required',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _ink,
                                side: const BorderSide(
                                  color: Color(0xFFD9D9E1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 22),
                              child: Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: Color(0xFF777785),
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                            ),
                            if (_creating) ...[
                              TextFormField(
                                controller: _fullName,
                                validator: _required,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _username,
                                validator: (value) =>
                                    RegExp(
                                      r'^[A-Za-z0-9_]{3,24}$',
                                    ).hasMatch(value?.trim() ?? '')
                                    ? null
                                    : 'Use 3–24 letters, numbers or underscores',
                                decoration: const InputDecoration(
                                  labelText: 'Private username',
                                  helperText:
                                      'Used as your unique account identifier; not shown on public profiles.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<AccountRole>(
                                initialValue: _role,
                                decoration: const InputDecoration(
                                  labelText: 'I am a…',
                                ),
                                items: AccountRole.values
                                    .map(
                                      (role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(role.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _role = value ?? _role),
                              ),
                              if (_role != AccountRole.user) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _jobTitle,
                                  validator: _required,
                                  decoration: const InputDecoration(
                                    labelText: 'Job title or specialty',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _company,
                                  validator: _required,
                                  decoration: const InputDecoration(
                                    labelText: 'Company, firm or practice',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _employmentType,
                                  decoration: const InputDecoration(
                                    labelText: 'Work arrangement',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'company',
                                      child: Text('Part of a company or firm'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'self_employed',
                                      child: Text('Self-employed'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'own_practice',
                                      child: Text('Own practice or company'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _employmentType =
                                        value ?? _employmentType,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  value != null && value.contains('@')
                                  ? null
                                  : 'Enter a valid email',
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              validator: (value) => (value?.length ?? 0) >= 8
                                  ? null
                                  : 'Use at least 8 characters',
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            if (_creating) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPassword,
                                obscureText: _obscure,
                                validator: _required,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 19,
                                ),
                              ),
                              child: Text(
                                _loading
                                    ? 'Please wait…'
                                    : _creating
                                    ? 'Create account'
                                    : 'Sign in',
                              ),
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _message!,
                                style: const TextStyle(
                                  color: Color(0xFF5B21B6),
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

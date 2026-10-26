import '../widgets/nova_target.dart';
import '../widgets/site_text.dart';
import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/backend_service.dart';

import '../widgets/pact_auth_surface.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onAuthenticated, this.compact = false});

  final VoidCallback? onAuthenticated;
  final bool compact;

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
  int _step = 0;
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
    if (_creating && _step < 2) {
      setState(() => _step++);
      return;
    }
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
          setState(() {
            _creating = false;
            _step = 0;
            _message =
                'Account created. Confirm your email, then sign in with your password.';
          });
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

  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    String? Function(String?)? validator,
    bool password = false,
    TextInputType? keyboard,
    Iterable<String>? hints,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      validator: validator ?? _required,
      obscureText: password && _obscure,
      keyboardType: keyboard,
      autofillHints: hints,
      textInputAction: !_creating && password
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: !_creating && password
          ? (_) {
              if (!_loading) _submit();
            }
          : null,
      decoration: InputDecoration(
        label: SiteText(label, contentKey: key, literal: true),
        suffixIcon: password
            ? IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PactAuthSurface(
    compact: widget.compact,
    title: SiteText(
      contentKey: 'copy.auth_page.m1',
      literal: false,
      _creating ? 'Create your Pact account.' : 'Welcome back.',
      style: const TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        height: 1.1,
      ),
    ),
    subtitle: SiteText(
      contentKey: 'copy.auth_page.m2',
      literal: false,
      _creating
          ? 'One account works for buyers, investors and every professional on the property team.'
          : 'Sign in to restore your calculator, saved analyses and selected team.',
      style: const TextStyle(
        color: Color(0xFF777584),
        fontSize: 14,
        height: 1.6,
      ),
    ),
    child: AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_creating) ...[
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? const Color(0xFF6255DC)
                                : const Color(0xFFEDEBF3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_step + 1} of 3 · ${['A little about you', 'Your sign-in details', 'Your professional identity'][_step]}',
                style: const TextStyle(color: Color(0xFF777584), fontSize: 12),
              ),
              const SizedBox(height: 22),
            ],
            if (!_creating &&
                (widget.compact || BackendService.googleAuthEnabled)) ...[
              OutlinedButton.icon(
                onPressed: _loading ? null : _google,
                icon: const Text(
                  'G',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                label: const SiteText(
                  'Continue with Google',
                  contentKey: 'copy.auth_page.m5',
                  literal: false,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SiteText(
                        'or',
                        contentKey: 'copy.auth_page.m6',
                        literal: true,
                        style: TextStyle(
                          color: Color(0xFF9A97A4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
            ],
            if (_creating && _step == 0) ...[
              _field(
                _fullName,
                'Full name',
                'copy.auth_page.field1',
                hints: [AutofillHints.name],
              ),
              _field(
                _username,
                'Private username',
                'copy.auth_page.field2',
                validator: (v) =>
                    RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Use 3–24 letters, numbers or underscores',
              ),
            ],
            if (!_creating || _step == 1) ...[
              NovaTarget(
                id: 'auth.form',
                child: _field(
                  _email,
                  'Email address',
                  'copy.auth_page.field7',
                  keyboard: TextInputType.emailAddress,
                  hints: [AutofillHints.email],
                  validator: (v) =>
                      RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid email',
                ),
              ),
              _field(
                _password,
                'Password',
                'copy.auth_page.mfield1',
                password: true,
                hints: [
                  _creating
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                validator: (v) =>
                    (_creating
                        ? (v?.length ?? 0) >= 8
                        : (v?.isNotEmpty ?? false))
                    ? null
                    : _creating
                    ? 'Use at least 8 characters'
                    : 'Enter your password',
              ),
              if (_creating)
                _field(
                  _confirmPassword,
                  'Confirm password',
                  'copy.auth_page.field8',
                  password: true,
                  validator: (v) =>
                      v == _password.text ? null : 'Passwords do not match',
                ),
            ],
            if (_creating && _step == 2) ...[
              DropdownButtonFormField<AccountRole>(
                initialValue: _role,
                isExpanded: true,
                decoration: const InputDecoration(
                  label: SiteText(
                    'I am a…',
                    contentKey: 'copy.auth_page.field3',
                    literal: true,
                  ),
                ),
                items: AccountRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: SiteText(
                          role.label,
                          contentKey: 'copy.auth_page.m7',
                          literal: false,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _role = value ?? _role),
              ),
              const SizedBox(height: 14),
              if (_role != AccountRole.user) ...[
                _field(
                  _jobTitle,
                  'Job title or specialty',
                  'copy.auth_page.field4',
                ),
                _field(
                  _company,
                  'Company, firm or practice',
                  'copy.auth_page.field5',
                ),
                DropdownButtonFormField<String>(
                  initialValue: _employmentType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    label: SiteText(
                      'Work arrangement',
                      contentKey: 'copy.auth_page.field6',
                      literal: true,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'company',
                      child: SiteText(
                        'Part of a company or firm',
                        contentKey: 'copy.auth_page.m8',
                        literal: true,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'self_employed',
                      child: SiteText(
                        'Self-employed',
                        contentKey: 'copy.auth_page.m9',
                        literal: true,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'own_practice',
                      child: SiteText(
                        'Own practice or company',
                        contentKey: 'copy.auth_page.m10',
                        literal: true,
                      ),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (value) => setState(
                          () => _employmentType = value ?? _employmentType,
                        ),
                ),
                const SizedBox(height: 14),
              ],
            ],
            if (_message != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Semantics(
                  liveRegion: true,
                  child: SiteText(
                    _message!,
                    contentKey: 'copy.auth_page.m12',
                    literal: false,
                    style: const TextStyle(
                      color: Color(0xFF6255DC),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : _creating && _step < 2
                  ? const Text('Continue')
                  : SiteText(
                      _creating ? 'Create account' : 'Sign in',
                      contentKey: 'copy.auth_page.m11',
                      literal: false,
                    ),
            ),
            if (_creating && _step > 0)
              TextButton(
                onPressed: _loading ? null : () => setState(() => _step--),
                child: const Text('Back'),
              ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _creating ? 'Already with Pact?' : 'New to Pact?',
                  style: const TextStyle(
                    color: Color(0xFF777584),
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                          _creating = !_creating;
                          _step = 0;
                          _message = null;
                        }),
                  child: SiteText(
                    _creating ? 'Sign in' : 'Create account',
                    contentKey: _creating
                        ? 'copy.auth_page.m3'
                        : 'copy.auth_page.m4',
                    literal: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

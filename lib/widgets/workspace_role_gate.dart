import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/workspace_role_service.dart';

class WorkspaceRoleScope extends InheritedWidget {
  const WorkspaceRoleScope({
    super.key,
    required this.role,
    required super.child,
  });
  final WorkspaceRole role;
  static WorkspaceRole? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkspaceRoleScope>()?.role;
  @override
  bool updateShouldNotify(WorkspaceRoleScope oldWidget) =>
      role != oldWidget.role;
}

class WorkspaceChoice extends StatefulWidget {
  const WorkspaceChoice({super.key, required this.onChoose, this.error});
  final Future<void> Function(WorkspaceRole) onChoose;
  final String? error;
  @override
  State<WorkspaceChoice> createState() => _WorkspaceChoiceState();
}

class _WorkspaceChoiceState extends State<WorkspaceChoice> {
  WorkspaceRole? _selected;
  bool _saving = false;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose your workspace',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose Buyer, Seller or Member. This choice is permanent for your account and applies on both phone and desktop.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (final role in WorkspaceRole.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _selected = role),
                    child: Text(
                      '${_selected == role ? '✓ ' : ''}${role.label}',
                    ),
                  ),
                ),
              ),
            if (widget.error != null)
              Text(widget.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving || _selected == null
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await widget.onChoose(_selected!);
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Saving…' : 'Confirm workspace'),
            ),
            TextButton(
              onPressed: _saving ? null : BackendService.signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Covers every desktop sign-in method, including restored and OAuth sessions.
class WorkspaceRoleGate extends StatefulWidget {
  const WorkspaceRoleGate({super.key, required this.child, this.service});
  final Widget child;
  final WorkspaceRoleService? service;
  @override
  State<WorkspaceRoleGate> createState() => _WorkspaceRoleGateState();
}

class _WorkspaceRoleGateState extends State<WorkspaceRoleGate> {
  late final _service = widget.service ?? WorkspaceRoleService();
  StreamSubscription<dynamic>? _auth;
  String? _userId;
  WorkspaceRole? _role;
  String? _error;
  bool _loading = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _auth = BackendService.authChanges?.listen((_) {
      if (_userId != BackendService.user?.id)
        unawaited(Future<void>.delayed(Duration.zero, _load));
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _userId = BackendService.user?.id;
    setState(() {
      _role = null;
      _error = null;
      _loading = true;
    });
    try {
      final role = _userId == null
          ? null
          : await _service.load().timeout(const Duration(seconds: 12));
      if (!mounted || generation != _generation) return;
      setState(() {
        _role = role;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = 'Could not recognize your account.';
        _loading = false;
      });
    }
  }

  Future<void> _choose(WorkspaceRole role) async {
    final generation = _generation;
    try {
      final saved = await _service
          .choose(role)
          .timeout(const Duration(seconds: 12));
      if (mounted &&
          generation == _generation &&
          _userId == BackendService.user?.id) {
        setState(() {
          _role = saved;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = 'Could not save your workspace. Please try again.',
        );
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return widget.child;
    if (_role != null) {
      return WorkspaceRoleScope(role: _role!, child: widget.child);
    }
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error == 'Could not recognize your account.'
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                  TextButton(
                    onPressed: BackendService.signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            )
          : WorkspaceChoice(onChoose: _choose, error: _error),
    );
  }
}

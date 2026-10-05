import 'package:flutter/material.dart';
import '../services/nova_training_controller.dart';
import '../services/nova_walkthrough.dart';
import 'nova_character.dart';

class NovaTrainingStatus extends StatefulWidget {
  const NovaTrainingStatus({super.key, this.controller});
  final NovaTrainingController? controller;
  @override
  State<NovaTrainingStatus> createState() => _NovaTrainingStatusState();
}

class _NovaTrainingStatusState extends State<NovaTrainingStatus> {
  late NovaTrainingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NovaTrainingController.instance;
    if (!_controller.service.loaded && !_controller.hosted)
      _controller.service.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller.service,
    builder: (context, _) {
      final service = _controller.service;
      final progress = service.progress;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NovaCharacter(
                    size: 62,
                    mood: progress.completed
                        ? NovaMood.celebrating
                        : NovaMood.welcome,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pebble app training',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          !service.loaded
                              ? 'Loading training progress…'
                              : progress.completed
                              ? 'Training complete'
                              : 'Training not finished',
                          style: const TextStyle(color: Color(0xFF596D60)),
                        ),
                        if (progress.completed)
                          Text(
                            service.profileSaved
                                ? 'Saved to your profile'
                                : service.signedIn
                                ? 'Saved on this device · profile sync pending'
                                : 'Saved on this device',
                            style: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  TextButton.icon(
                    onPressed: () => _controller.start(role: progress.role),
                    icon: const Icon(Icons.replay_rounded, size: 17),
                    label: const Text('Replay app training'),
                  ),
                  if (progress.pendingSync)
                    TextButton(
                      onPressed: () => service.save(
                        role: progress.role,
                        step: progress.step,
                        finish: progress.completed,
                      ),
                      child: const Text('Retry profile sync'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import '../services/spot_mistake_lessons.dart';
import '../widgets/app_navigation_menu.dart';

class SpotMistakePage extends StatefulWidget {
  const SpotMistakePage({super.key});
  @override
  State<SpotMistakePage> createState() => _SpotMistakePageState();
}

class _SpotMistakePageState extends State<SpotMistakePage> {
  int _index = 0, _score = 0;
  int? _selected;
  bool _complete = false, _review = false;
  final List<int> _missed = [];
  List<int> get _rounds =>
      _review ? _missed : List.generate(mistakeLessons.length, (i) => i);
  void _answer(int value) {
    if (_selected != null) return;
    final actual = _rounds[_index];
    setState(() {
      _selected = value;
      if (value == mistakeLessons[actual].answer) {
        _score++;
      } else if (!_review) {
        _missed.add(actual);
      }
    });
  }

  void _next() => setState(() {
    if (_index + 1 == _rounds.length) {
      _complete = true;
    } else {
      _index++;
      _selected = null;
    }
  });
  void _restart({bool review = false}) => setState(() {
    _index = 0;
    _score = 0;
    _selected = null;
    _complete = false;
    _review = review;
    if (!review) _missed.clear();
  });
  @override
  Widget build(BuildContext context) {
    final lesson = mistakeLessons[_rounds[_index]];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Spot the mistake'),
        actions: const [AppNavigationMenu(dark: false)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'A sharper eye for a better deal.',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Read the fictional buyer scenario. Pick the mistaken statement, then learn what to check before making a real decision.',
                ),
                const SizedBox(height: 28),
                if (_complete) ...[
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Color(0xFF526DFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _review ? 'Review complete' : 'Round complete',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$_score of ${_rounds.length} spotted',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your next move: bring these checks into your deal review. Ask for evidence, test the cash flow and plan the handover.',
                  ),
                  const SizedBox(height: 20),
                  if (_missed.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => _restart(review: true),
                      child: const Text('Practice missed scenarios'),
                    ),
                  FilledButton(
                    onPressed: () => _restart(),
                    child: const Text('Play again'),
                  ),
                ] else ...[
                  Text(
                    '${_review ? 'Practice' : 'Scenario'} ${_index + 1} of ${_rounds.length} · ${lesson.topic} · Score $_score',
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _index / _rounds.length),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lesson.scenario,
                            style: const TextStyle(fontSize: 17, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Which statement is the mistake?',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < lesson.claims.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(18),
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: _selected == null ? () => _answer(i) : null,
                        child: Row(
                          children: [
                            Icon(
                              _selected != null && i == lesson.answer
                                  ? Icons.check_circle
                                  : _selected == i
                                  ? Icons.cancel_outlined
                                  : Icons.radio_button_unchecked,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lesson.claims[i],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_selected != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Card(
                        color: const Color(0xFFE8ECFF),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selected == lesson.answer
                                    ? 'You spotted it!'
                                    : 'Here is the mistake to watch for',
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Mistaken statement: ${lesson.claims[lesson.answer]}',
                              ),
                              const SizedBox(height: 12),
                              Text(
                                lesson.explanation,
                                style: const TextStyle(height: 1.5),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Better move: ${lesson.action}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _next,
                      child: Text(
                        _index + 1 == _rounds.length
                            ? 'See results'
                            : 'Next scenario',
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                const Text(
                  'Practice scenarios teach review habits. Check the facts and terms of your own transaction with your advisers.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5C6074)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/deal_quiz.dart';
import '../services/backend_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import 'acquisition_support_page.dart';
import 'auth_page.dart';
import 'member_deal_marketplace_page.dart';

const _green = Color(0xFF086B4C);
const _ink = Color(0xFF203435);
const _muted = Color(0xFF607172);

/// Every route into the quiz requires an authenticated account.
class DealComparisonPage extends StatefulWidget {
  const DealComparisonPage({super.key});
  @override
  State<DealComparisonPage> createState() => _QuizAccessState();
}

class _QuizAccessState extends State<DealComparisonPage> {
  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: BackendService.authChanges,
    builder: (context, _) => BackendService.user == null
        ? AuthPage(
            onAuthenticated: () {
              if (mounted) setState(() {});
            },
          )
        : BusinessComparisonQuiz(key: ValueKey(BackendService.user!.id)),
  );
}

/// Quiz surface, mounted by DealComparisonPage after authentication.
class BusinessComparisonQuiz extends StatefulWidget {
  const BusinessComparisonQuiz({super.key});

  @override
  State<BusinessComparisonQuiz> createState() => _DealComparisonPageState();
}

class _DealComparisonPageState extends State<BusinessComparisonQuiz>
    with SingleTickerProviderStateMixin {
  AcquisitionFoundation? _foundation;
  final Map<String, dynamic> _answers = {};
  final List<QuizChoice> _choices = [];
  QuizBusiness _left = quizBusinesses[0];
  QuizBusiness _right = quizBusinesses[1];
  late final AnimationController _motion;
  bool _entering = false;
  bool? _motionOverride;
  bool get _fullMotion =>
      _motionOverride ?? !MediaQuery.of(context).disableAnimations;
  int get _step => _choices.length;
  int? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _savedToAccount = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      animationBehavior: AnimationBehavior.preserve,
    );
    _load();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final foundation = await AcquisitionFoundation.load();
      if (!mounted) return;
      setState(() {
        _foundation = foundation;
        final stored = foundation.blueprint['comparisonProfile'];
        if (stored is Map) _answers.addAll(Map<String, dynamic>.from(stored));
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Your saved preferences could not be loaded. Please retry.';
        });
    }
  }

  Future<void> _choose(int index) async {
    if (_selected != null || _saving) return;
    final winner = index == 0 ? _left : _right;
    final choice = QuizChoice(_left, _right, winner);
    setState(() {
      _selected = index;
      _entering = false;
    });
    _motion.value = 0;
    {
      try {
        await _motion.animateTo(.6).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    _choices.add(choice);
    if (_step < quizBusinesses.length - 1) {
      setState(() {
        final challenger = quizBusinesses[_step + 1];
        if (index == 0) {
          _right = challenger;
        } else {
          _left = challenger;
        }
        _entering = true;
      });
      {
        try {
          await _motion.forward().orCancel;
        } on TickerCanceled {
          return;
        }
      }
    } else {
      _answers
        ..clear()
        ..addAll(inferQuizProfile(_choices).toJson());
    }
    if (!mounted) return;
    setState(() {
      _selected = null;
      _entering = false;
    });
    if (_step == quizBusinesses.length - 1) await _save();
  }

  void _back() {
    if (_selected != null || _choices.isEmpty) return;
    setState(() {
      final previous = _choices.removeLast();
      _left = previous.left;
      _right = previous.right;
      _motion.value = 0;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (BackendService.user == null)
        throw StateError('Sign in to save your quiz.');
      final foundation = _foundation ?? await AcquisitionFoundation.load();
      foundation.blueprint['comparisonProfile'] = inferQuizProfile(
        _choices,
      ).toJson();
      foundation.blueprint['comparisonQuiz'] = {
        'version': 2,
        'source': 'inferred_business_choices',
        'choices': _choices.map((choice) => choice.toJson()).toList(),
        'winner': _choices.last.winner.id,
      };
      await foundation.save();
      final signedIn = BackendService.user != null;
      if (signedIn) await foundation.saveForAccount('deal_comparison');
      if (mounted)
        setState(() {
          _foundation = foundation;
          _savedToAccount = signedIn;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error =
              'Your choices are still here. Saving failed; please try again.';
        });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE7F0FF),
    appBar: AppBar(
      toolbarHeight: 76,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 50, dark: false),
      actions: const [AppNavigationMenu(dark: false), SizedBox(width: 12)],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _green))
        : _foundation == null && _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDDEBFF),
                  Color(0xFFEAE0FF),
                  Color(0xFFD4F3EC),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                padding: EdgeInsets.all(viewport.maxWidth < 600 ? 16 : 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 1380,
                      minHeight: (viewport.maxHeight - 56).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: _step == quizBusinesses.length - 1
                        ? _complete()
                        : _quiz(),
                  ),
                ),
              ),
            ),
          ),
  );

  Widget _quiz() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'QUIZ',
                style: TextStyle(
                  color: _green,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            ActionChip(
              avatar: Icon(
                _fullMotion ? Icons.animation : Icons.blur_on,
                size: 18,
              ),
              label: Text(_fullMotion ? 'Full motion' : 'Gentle motion'),
              onPressed: _selected == null
                  ? () => setState(() => _motionOverride = !_fullMotion)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '${_step + 1} / 8',
              style: const TextStyle(
                color: _muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            8,
            (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: i <= _step
                      ? const Color(0xFF6953D9)
                      : const Color(0xFFC5CEE5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Which business would you rather own?',
          style: const TextStyle(
            color: _ink,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Compare the whole business. Your favourite stays; a new challenger takes the other spot.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        ClipRect(
          child: LayoutBuilder(
            builder: (context, box) {
              Widget document(int index) {
                final business = index == 0 ? _left : _right;
                return AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) {
                    final winner = _selected == index;
                    final loser = _selected != null && !winner;
                    final t = _motion.value;
                    final shrink = Curves.easeInCubic.transform(
                      ((t - .22) / .38).clamp(0.0, 1.0),
                    );
                    final arrival = Curves.easeOutCubic.transform(
                      ((t - .6) / .4).clamp(0.0, 1.0),
                    );
                    final pulse = (t / .6).clamp(0.0, 1.0);
                    return Transform.translate(
                      key: ValueKey('slide-${business.id}'),
                      offset: Offset(
                        _fullMotion && loser && _entering
                            ? MediaQuery.sizeOf(context).width * (1 - arrival)
                            : 0,
                        0,
                      ),
                      child: Transform.scale(
                        key: ValueKey('scale-${business.id}'),
                        scale: _fullMotion && loser && !_entering
                            ? 1 - .99 * shrink
                            : 1,
                        child: Opacity(
                          opacity: loser
                              ? (_entering && !_fullMotion
                                    ? arrival
                                    : !_entering
                                    ? 1 - shrink
                                    : 1)
                              : 1,
                          child: Stack(
                            children: [
                              _BusinessDocument(
                                key: ValueKey(business.id),
                                letter: business.id,
                                accent: index == 0
                                    ? const Color(0xFF245DD8)
                                    : const Color(0xFF7A42CE),
                                option: business,
                                selected: winner && !_entering,
                                enabled: _selected == null,
                                onChoose: () => _choose(index),
                              ),
                              if (winner && !_entering)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: 1 - pulse,
                                      child: Transform.scale(
                                        scale: _fullMotion
                                            ? 1 + .04 * pulse
                                            : 1,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _green,
                                              width: 4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _green.withValues(
                                                  alpha: .25 * (1 - pulse),
                                                ),
                                                blurRadius: 24 * pulse,
                                                spreadRadius: 6 * pulse,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              const versus = Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
              if (box.maxWidth < 700) {
                return Column(children: [document(0), versus, document(1)]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: document(0)),
                  versus,
                  Expanded(child: document(1)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_step > 0)
              TextButton.icon(
                onPressed: _selected == null ? _back : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous comparison'),
              ),
            const Expanded(
              child: Text(
                'Illustrative businesses · CAD · Figures are examples, not live listings.',
                textAlign: TextAlign.end,
                style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _complete() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_circle_outline, color: _green, size: 44),
      const SizedBox(height: 18),
      const Text(
        'Your preferences, learned from your choices.',
        style: TextStyle(
          color: _ink,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _saving
            ? 'Saving your choices…'
            : _savedToAccount
            ? 'Saved to your account for personalized scores on the bulletin board.'
            : 'Saved on this device. Sign in to keep these preferences across devices.',
        style: const TextStyle(color: _muted, fontSize: 16),
      ),
      const SizedBox(height: 24),
      const Text(
        'These are inferred preferences from the businesses you chose, not fixed requirements.',
        style: TextStyle(color: _muted, fontSize: 16),
      ),
      const SizedBox(height: 12),
      for (final trait in quizTraitLabels.entries)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            trait.value,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          subtitle: Text(
            '${_answers[trait.key] ?? ''}',
            style: const TextStyle(color: _ink, fontSize: 18),
          ),
        ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 20),
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_error != null) {
                      await _save();
                      return;
                    }
                    if (!_savedToAccount) {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AuthPage(),
                        ),
                      );
                      if (!mounted || BackendService.user == null) return;
                      await _save();
                      if (!mounted || _error != null) return;
                    }
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BusinessSaleBulletinPage(),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: Text(
              _error != null
                  ? 'Retry saving'
                  : _savedToAccount
                  ? 'Find matching businesses'
                  : 'Sign in & save to my account',
            ),
          ),
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _choices.clear();
                    _answers.clear();
                    _left = quizBusinesses[0];
                    _right = quizBusinesses[1];
                    _savedToAccount = false;
                    _selected = null;
                    _error = null;
                  }),
            child: const Text('Retake the quiz'),
          ),
        ],
      ),
    ],
  );
}

class _BusinessDocument extends StatelessWidget {
  const _BusinessDocument({
    super.key,
    required this.letter,
    required this.accent,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onChoose,
  });
  final String letter;
  final Color accent;
  final QuizBusiness option;
  final bool selected;
  final bool enabled;
  final VoidCallback onChoose;

  String money(double value) =>
      NumberFormat.currency(symbol: r'$', decimalDigits: 0).format(value);

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onChoose : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Duration(
            milliseconds: MediaQuery.of(context).disableAnimations ? 0 : 220,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF97EDBB)
                : Color.lerp(Colors.white, accent, .045),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _green : accent.withValues(alpha: .5),
              width: selected ? 4 : 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C203435),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected ? Icons.check_circle : Icons.description_outlined,
                    color: _green,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'BUSINESS $letter',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Text(
                    'ILLUSTRATIVE',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: .25)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                option.name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Commercial maintenance services',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9AE),
                  border: Border(
                    left: BorderSide(color: Color(0xFFCB861A), width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUSINESS STRENGTH',
                      style: const TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.strength,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _row('Acquisition price', money(option.equity)),
              _row('Buying outcome', option.goal),
              _row('Holding period', option.horizon),
              _row('Your operating role', option.role),
              _row('Weekly involvement', option.time),
              _row('Operating risk', option.risk),
              const SizedBox(height: 20),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.6),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                },
                children: [
                  _financialRow(
                    'Operating breakdown',
                    'Monthly',
                    'Yearly',
                    header: true,
                  ),
                  _financialRow(
                    'Revenue',
                    money(option.revenue / 12),
                    money(option.revenue),
                  ),
                  _financialRow(
                    'Operating expenses',
                    money(option.expenses / 12),
                    money(option.expenses),
                    shaded: true,
                  ),
                  _financialRow(
                    'Owner / manager pay',
                    money(option.salary / 12),
                    money(option.salary),
                  ),
                  _financialRow(
                    'Cash remaining',
                    money(option.cash / 12),
                    money(option.cash),
                    total: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row(
                'Annual equity return',
                '${(option.cash / option.equity * 100).round()}%',
              ),
              const Text(
                'Illustrative all-cash purchase; before tax and financing.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: enabled ? onChoose : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: selected ? _green : accent,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(
                    selected
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    selected ? 'Selected' : 'I would choose business $letter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  TableRow _financialRow(
    String label,
    String monthly,
    String yearly, {
    bool header = false,
    bool total = false,
    bool shaded = false,
  }) => TableRow(
    decoration: BoxDecoration(
      color: header
          ? accent
          : total
          ? const Color(0xFFE4F2EB)
          : shaded
          ? const Color(0xFFF2F5F5)
          : Colors.white,
    ),
    children: [label, monthly, yearly]
        .asMap()
        .entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              entry.value,
              textAlign: entry.key == 0 ? TextAlign.start : TextAlign.end,
              style: TextStyle(
                color: header ? Colors.white : _ink,
                fontSize: 13,
                fontWeight: header || total ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        )
        .toList(),
  );
}

import 'package:flutter/material.dart';
import '../services/nova_training_controller.dart';
import '../services/nova_walkthrough.dart';
import 'calculator_help_sidebar.dart';
import 'nova_character.dart';
import 'site_copy_text.dart';

/// An interactive introduction to the existing page and calculator guide.
class PikaIntroduction extends StatefulWidget {
  const PikaIntroduction({super.key});
  @override
  State<PikaIntroduction> createState() => _PikaIntroductionState();
}

class _PikaIntroductionState extends State<PikaIntroduction> {
  int _question = 0;
  static const _lime = Color(0xFFC0CF8B);
  static const _muted = Color(0xFFB6C4BC);
  static const _questions = [
    (
      'Where do I start?',
      'Choose Buyer if you are looking for a business, Seller if you are planning a transfer, or Learning if you want to build your understanding first. I can show you around each workspace.',
    ),
    (
      'How do I compare deals?',
      'Start with the deal comparison quiz in Learning. Review why each choice appealed to you, then save opportunities in your private Buyer pipeline as you find them.',
    ),
    (
      'Can you explain the numbers?',
      'Open Deal screen in the Buyer dashboard. Choose business, assets or commercial property, then use the information buttons beside the inputs for definitions, calculations and examples.',
    ),
  ];
  Widget _copy(
    String id,
    String text, {
    double size = 16,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
  }) => SiteCopyText(
    'home.pika.$id',
    text,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: size >= 40 ? -1.6 : 0,
    ),
  );
  void _meetPika() {
    CalculatorHelpController.instance.close();
    NovaTrainingController.instance.restoreDock();
    NovaTrainingController.instance.startPage(
      NovaTrainingController.instance.currentPage,
    );
  }

  Widget _words(bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _copy(
              'eyebrow',
              'A LITTLE GUIDANCE. A CLEARER PATH.',
              size: 11,
              color: _lime,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 30),
      _copy(
        'title',
        'Meet Pika.',
        size: wide ? 62 : 44,
        weight: FontWeight.w600,
        height: 1.05,
      ),
      const SizedBox(height: 10),
      _copy(
        'heading',
        'Clarity, one step\nat a time.',
        size: wide ? 50 : 38,
        color: _lime,
        weight: FontWeight.w500,
        height: 1.12,
      ),
      const SizedBox(height: 28),
      _copy(
        'intro',
        'Buying, selling or just finding your feet? Pika helps you get comfortable with Pact and understand your next step.',
        color: _muted,
        size: 17,
      ),
      const SizedBox(height: 26),
      for (final (id, text) in const [
        ('walkthroughs', 'Walkthroughs that stay with the page'),
        ('explanations', 'Plain-language explanations for the numbers'),
        ('pace', 'Guidance you can pause and revisit'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(Icons.check_rounded, color: _lime, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _copy('benefit.$id', text, color: _muted, size: 15),
              ),
            ],
          ),
        ),
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('meet-pika'),
        onPressed: _meetPika,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF164F3D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          shape: const StadiumBorder(),
        ),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded, size: 19),
        label: _copy('action', 'Meet Pika', size: 15, weight: FontWeight.w600),
      ),
    ],
  );
  Widget _preview() => Container(
    key: const Key('pika-preview'),
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: const Color(0xFF1D2C27),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF3F5148)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const NovaCharacter(size: 48, mood: NovaMood.curious),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _copy(
                    'preview.name',
                    'Pika',
                    size: 20,
                    weight: FontWeight.w700,
                  ),
                  _copy(
                    'preview.status',
                    'Your Pact guide',
                    color: _lime,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _copy(
          'preview.prompt',
          'What would you like a hand with?',
          size: 13,
          color: _muted,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _questions.length; i++)
              OutlinedButton(
                key: ValueKey('pika-question-$i'),
                onPressed: () => setState(() => _question = i),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _question == i ? _lime : Colors.white,
                  side: BorderSide(
                    color: _question == i ? _lime : const Color(0xFF52635A),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: _copy(
                  'question.$i',
                  _questions[i].$1,
                  size: 12,
                  color: _question == i ? _lime : Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF34423C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _copy(
              'question.$_question',
              _questions[_question].$1,
              size: 15,
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          alignment: Alignment.topLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Container(
              key: ValueKey(_question),
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF304C3E),
                borderRadius: BorderRadius.circular(22),
              ),
              child: _copy(
                'answer.$_question',
                _questions[_question].$2,
                size: 15,
                color: const Color(0xFFE3ECE4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        TextButton.icon(
          key: const Key('pika-preview-tour'),
          onPressed: _meetPika,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: _lime),
          iconAlignment: IconAlignment.end,
          label: _copy(
            'preview.action',
            'Show me around',
            color: _lime,
            size: 14,
            weight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width < 700 ? 18 : 48,
      vertical: 56,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1376),
        child: Container(
          key: const Key('pika-introduction'),
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 700 ? 26 : 64,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF101A18),
            borderRadius: BorderRadius.circular(36),
          ),
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 950
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _words(true)),
                      const SizedBox(width: 64),
                      Expanded(child: _preview()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _words(false),
                      const SizedBox(height: 42),
                      _preview(),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

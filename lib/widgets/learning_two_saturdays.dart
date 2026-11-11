import 'package:flutter/material.dart';

import '../models/learning_lesson_content.dart';
import 'learning_activity_ui.dart';
import 'site_copy_text.dart';

class LearningTwoSaturdays extends StatefulWidget {
  const LearningTwoSaturdays({super.key});
  @override
  State<LearningTwoSaturdays> createState() => _LearningTwoSaturdaysState();
}

class _LearningTwoSaturdaysState extends State<LearningTwoSaturdays> {
  String? _role;
  int _moment = 0;
  final _choices = <int>[];
  bool _result = false;
  final _storyKey = GlobalKey();

  void _chooseRole(String role) {
    setState(() {
      _role = role;
      _moment = 0;
      _choices.clear();
      _result = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStory());
  }

  void _showStory() {
    final target = _storyKey.currentContext;
    if (!mounted || target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: .05,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
    );
  }

  void _choose(int choice) {
    if (_role == null || _result || _choices.length > _moment) return;
    setState(() => _choices.add(choice));
  }

  void _advance() {
    if (_result || _choices.length <= _moment) return;
    setState(() {
      if (_moment == 2) {
        _result = true;
      } else {
        _moment++;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStory());
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, bounds) {
          final width = bounds.maxWidth >= 720
              ? (bounds.maxWidth - 20) / 2
              : bounds.maxWidth;
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final role in ['operator', 'investor'])
                SizedBox(width: width, child: _roleCard(role)),
            ],
          );
        },
      ),
      if (_role != null)
        Padding(
          key: _storyKey,
          padding: const EdgeInsets.only(top: 28),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 280),
            child: _result ? _ownerResult() : _momentCard(),
          ),
        ),
    ],
  );

  Widget _roleCard(String role) => Container(
    decoration: BoxDecoration(
      color: role == 'operator' ? activityCream : const Color(0xFFE7EEF1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _role == role ? activityForest : Colors.transparent,
        width: 2,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SaturdayScene(
          investor: role == 'investor',
          moment: _role == role ? _moment : 0,
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              creativeCopy(
                'discover.$role.caption',
                style: const TextStyle(fontSize: 12, color: activityForest),
              ),
              const SizedBox(height: 8),
              SiteCopyText(
                'learning.lesson.discover.$role.title',
                learningLessonCopy['learning.lesson.discover.$role.title']!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: activityInk,
                ),
              ),
              const SizedBox(height: 12),
              SiteCopyText(
                'learning.lesson.discover.$role.body',
                learningLessonCopy['learning.lesson.discover.$role.body']!,
                style: activityBody,
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: ValueKey('saturday-pick-$role'),
                style: FilledButton.styleFrom(
                  backgroundColor: activityForest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                ),
                onPressed: () => _chooseRole(role),
                child: creativeCopy(
                  'discover.$role.pick',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _momentCard() {
    final revealed = _choices.length > _moment;
    return Container(
      key: ValueKey('saturday-moment-$_moment'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDDCD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: activityRust, size: 20),
              const SizedBox(width: 10),
              Text(
                const ['09:00', '12:00', '18:00'][_moment],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: activityRust,
                ),
              ),
              const Spacer(),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    i <= _moment ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: activityForest,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          creativeCopy(
            'discover.$_role.day',
            style: const TextStyle(fontSize: 14, color: activityForest),
          ),
          const SizedBox(height: 10),
          creativeCopy(
            'discover.$_role.scene.$_moment',
            style: const TextStyle(
              fontSize: 23,
              height: 1.4,
              color: activityInk,
            ),
          ),
          const SizedBox(height: 24),
          for (var choice = 0; choice < 2; choice++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                key: ValueKey('saturday-choice-$choice'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(18),
                  foregroundColor: activityForest,
                  backgroundColor: revealed && _choices[_moment] == choice
                      ? activitySage
                      : Colors.white,
                ),
                onPressed: revealed ? null : () => _choose(choice),
                child: creativeCopy('discover.choice.$_moment.$choice'),
              ),
            ),
          if (revealed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: activitySage,
                borderRadius: BorderRadius.circular(12),
              ),
              child: creativeCopy(
                'discover.outcome.$_moment.${_choices[_moment]}',
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey('saturday-continue'),
                style: FilledButton.styleFrom(backgroundColor: activityForest),
                onPressed: _advance,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: creativeCopy(
                  _moment == 2
                      ? 'discover.resultButton'
                      : 'discover.nextMoment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ownerResult() {
    final independent = _choices.where((choice) => choice == 1).length >= 2;
    final type = independent ? 'investor' : 'operator';
    return Container(
      key: const ValueKey('saturday-result'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: activityForest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            color: Color(0xFFE8CE8C),
            size: 42,
          ),
          const SizedBox(height: 22),
          creativeCopy(
            'discover.result.$type',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          creativeCopy(
            'discover.result.${type}Body',
            style: activityBody.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          creativeCopy(
            'discover.result.note',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFFD1DDCF),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const ValueKey('saturday-restart'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.all(18),
              ),
              onPressed: () =>
                  _chooseRole(_role == 'operator' ? 'investor' : 'operator'),
              child: creativeCopy(
                'discover.restart',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaturdayScene extends StatelessWidget {
  const _SaturdayScene({required this.investor, required this.moment});
  final bool investor;
  final int moment;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2.15,
    child: LayoutBuilder(
      builder: (context, bounds) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SaturdayPainter(investor, moment)),
          ),
          if (!investor)
            Positioned(
              left: bounds.maxWidth * 419 / 600,
              top: bounds.maxHeight * 45 / 280,
              width: bounds.maxWidth * 140 / 600,
              height: bounds.maxHeight * 54 / 280,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: creativeCopy(
                    'discover.shopSign',
                    style: TextStyle(
                      fontSize: bounds.maxWidth * 13 / 600,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: bounds.maxWidth * (investor ? .4 : .66),
            bottom: bounds.maxHeight * .1,
            child: AlexAvatar(size: bounds.maxHeight * .52, phase: moment / 3),
          ),
        ],
      ),
    ),
  );
}

class _SaturdayPainter extends CustomPainter {
  const _SaturdayPainter(this.investor, this.moment);
  final bool investor;
  final int moment;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 600, size.height / 280);
    final paint = Paint();
    c.drawRect(
      const Rect.fromLTWH(0, 0, 600, 280),
      paint
        ..color = investor ? const Color(0xFFD9E5E7) : const Color(0xFFE9DDC4),
    );
    c.drawRect(
      const Rect.fromLTWH(0, 221, 600, 59),
      paint
        ..color = investor ? const Color(0xFFB8C8BD) : const Color(0xFFC2BDA8),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 25, 170, 125),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xFFFAF9ED),
    );
    c.drawRect(
      const Rect.fromLTWH(48, 33, 154, 109),
      paint
        ..color = moment == 2
            ? const Color(0xFFDAB49D)
            : const Color(0xFFA9CED2),
    );
    c.drawCircle(
      Offset(82 + moment * 46, 62 + moment * 13),
      18,
      paint..color = const Color(0xFFF6D38B),
    );
    c.drawRect(
      const Rect.fromLTWH(122, 28, 5, 119),
      paint..color = const Color(0xFFFAF9ED),
    );
    if (investor) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(330, 174, 200, 58),
          const Radius.circular(12),
        ),
        paint..color = const Color(0xFF849B83),
      );
      c.drawRect(
        const Rect.fromLTWH(340, 216, 12, 32),
        paint..color = activityForest,
      );
      c.drawRect(
        const Rect.fromLTWH(508, 216, 12, 32),
        paint..color = activityForest,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(74, 200, 145, 12),
          const Radius.circular(4),
        ),
        paint..color = const Color(0xFF9B7E61),
      );
      c.drawRect(const Rect.fromLTWH(88, 210, 9, 47), paint);
      c.drawRect(const Rect.fromLTWH(197, 210, 9, 47), paint);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(112, 158, 68, 42),
          const Radius.circular(4),
        ),
        paint..color = const Color(0xFF455E65),
      );
      c.drawRect(
        const Rect.fromLTWH(119, 165, 54, 28),
        paint..color = const Color(0xFFBDD2D1),
      );
      c.drawRect(
        const Rect.fromLTWH(510, 86, 8, 87),
        paint..color = const Color(0xFF8C785D),
      );
      c.drawOval(
        const Rect.fromLTWH(480, 65, 62, 43),
        paint..color = activityForest,
      );
    } else {
      for (var i = 0; i < 3; i++) {
        final x = 38 + i * 116.0;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 161, 104, 94),
            const Radius.circular(7),
          ),
          paint..color = const Color(0xFFF8F6EA),
        );
        c.drawCircle(
          Offset(x + 52, 213),
          31,
          paint..color = const Color(0xFF809696),
        );
        c.drawCircle(
          Offset(x + 52, 213),
          23,
          paint..color = const Color(0xFFAFC6C3),
        );
        c.drawCircle(Offset(x + 81, 175), 4, paint..color = activityForest);
      }
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(419, 45, 140, 54),
          const Radius.circular(7),
        ),
        paint..color = activityForest,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_SaturdayPainter oldDelegate) =>
      oldDelegate.investor != investor || oldDelegate.moment != moment;
}

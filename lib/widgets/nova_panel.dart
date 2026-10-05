import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/backend_service.dart';
import '../services/nova_service.dart';
import '../services/nova_learning.dart';
import 'site_copy_text.dart';

class NovaPanel extends StatefulWidget {
  const NovaPanel({
    super.key,
    required this.context,
    this.contextProvider,
    this.tourRole,
    this.onTourNavigate,
    this.initiallyOpen = false,
    this.answerLoader,
  });
  final NovaContext context;
  final NovaContext Function()? contextProvider;
  final String? tourRole;
  final void Function(String)? onTourNavigate;
  final bool initiallyOpen;
  final Future<NovaAnswer> Function(
    NovaContext,
    String,
    List<Map<String, String>>,
    String,
  )?
  answerLoader;
  @override
  State<NovaPanel> createState() => _NovaPanelState();
}

class _NovaPanelState extends State<NovaPanel> {
  static const _forest = Color(0xFF144F40), _muted = Color(0xFF6E7E92);
  final _input = TextEditingController(), _evidence = TextEditingController();
  final List<Map<String, String>> _history = [];
  final List<NovaAnswer> _answers = [];
  StreamSubscription<AuthState>? _auth;
  late bool _open;
  bool _busy = false, _showEvidence = false, _shareContext = false;
  String? _error;
  String _tab = 'ask', _lessonId = 'blueprint';
  int _tourIndex = 0, _generation = 0;
  String? _user;
  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
    _lessonId =
        widget.context.lesson ??
        switch (widget.context.area) {
          'seller' => 'seller',
          'member' => 'member',
          'financials' || 'valuation' => 'valuation',
          _ => 'blueprint',
        };
    _user = BackendService.user?.id;
    _restoreTour();
    _auth = BackendService.authChanges?.listen((_) {
      final next = BackendService.user?.id;
      if (next == _user) return;
      _user = next;
      _generation++;
      if (mounted)
        setState(() {
          _history.clear();
          _answers.clear();
          _input.clear();
          _evidence.clear();
          _error = null;
          _busy = false;
          _tourIndex = 0;
          _open = false;
          _shareContext = false;
        });
      _restoreTour();
    });
  }

  String get _tourKey =>
      'nova.tour.v1.${_user ?? "guest"}.${widget.tourRole ?? "buyer"}';
  Future<void> _restoreTour() async {
    final key = _tourKey;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || key != _tourKey) return;
    final steps = novaTour(widget.tourRole ?? 'buyer');
    setState(
      () => _tourIndex = (prefs.getInt(key) ?? 0).clamp(0, steps.length - 1),
    );
  }

  @override
  void didUpdateWidget(NovaPanel old) {
    super.didUpdateWidget(old);
    if (old.context.scope != widget.context.scope) {
      _generation++;
      _history.clear();
      _answers.clear();
      _error = null;
      _busy = false;
      _input.clear();
      _evidence.clear();
      _shareContext = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    _input.dispose();
    _evidence.dispose();
    super.dispose();
  }

  Future<void> _ask([String? prompt]) async {
    final question = (prompt ?? _input.text).trim();
    if (question.isEmpty || _busy) return;
    if (!_shareContext) {
      setState(() {
        _error =
            'Choose whether to share this workspace context with OpenAI before asking for a live answer.';
        _input.text = question;
      });
      return;
    }
    final generation = _generation;
    final current = widget.contextProvider?.call() ?? widget.context;
    final lesson = novaLessons.firstWhere(
      (l) => l.id == _lessonId,
      orElse: () => novaLessons.first,
    );
    final context = _tab == 'learn'
        ? NovaContext(
            area: 'learning',
            label: current.label,
            dealId: current.dealId,
            facts: current.facts,
            lesson: lesson.id,
          )
        : current;
    setState(() {
      _busy = true;
      _error = null;
      _input.text = question;
    });
    try {
      final answer = widget.answerLoader != null
          ? await widget.answerLoader!(
              context,
              question,
              List.of(_history),
              _evidence.text,
            )
          : await NovaService.ask(
              context,
              question,
              List.of(_history),
              evidence: _evidence.text,
              consentToShare: _shareContext,
            );
      if (!mounted || generation != _generation) return;
      setState(() {
        _history.addAll([
          {'role': 'user', 'content': question},
          {'role': 'assistant', 'content': answer.text},
        ]);
        _answers.add(answer);
        _input.clear();
      });
    } catch (error) {
      if (mounted && generation == _generation)
        setState(() => _error = error.toString());
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7E2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(narrow ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: Color(0xFFE9F4EE),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _forest,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SiteCopyText(
                        'nova.panel.name',
                        'Nova',
                        style: TextStyle(
                          color: _forest,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.context.dealId != null
                            ? 'Working with ${widget.context.label}'
                            : 'Your Affinity guide',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.tourRole != null)
                  IconButton(
                    tooltip: 'Nova walkthrough',
                    onPressed: () => setState(() {
                      _open = true;
                      _tab = 'tour';
                    }),
                    icon: const Icon(Icons.explore_outlined, color: _forest),
                  ),
                TextButton(
                  onPressed: () => setState(() => _open = !_open),
                  child: Text(
                    _open ? 'Close' : 'Ask Nova',
                    style: const TextStyle(color: _forest),
                  ),
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _tabButton('ask', 'Ask Nova'),
                  if (widget.tourRole != null)
                    _tabButton('tour', 'Show me around'),
                  _tabButton('learn', 'Learn with Nova'),
                ],
              ),
              const Divider(height: 26),
              if (_tab == 'tour')
                _tour()
              else ...[
                if (_tab == 'learn') _lesson(),
                if (_tab == 'ask') ...[
                  const SiteCopyText(
                    'nova.panel.prompt',
                    'What would you like to understand?',
                    style: TextStyle(
                      color: Color(0xFF192B3B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final prompt in widget.context.suggestions)
                        ActionChip(
                          label: Text(
                            prompt,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: _busy ? null : () => _ask(prompt),
                        ),
                    ],
                  ),
                ],
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 390),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _answers.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _history[i * 2]['content']!,
                              style: const TextStyle(
                                color: _forest,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              _answers[i].text,
                              style: const TextStyle(
                                color: Color(0xFF243448),
                                height: 1.6,
                              ),
                            ),
                            if (_answers[i].sources.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Context used: ${_answers[i].sources.join(" · ")}',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _history.clear();
                            _answers.clear();
                          }),
                    child: const Text('Clear conversation'),
                  ),
                ],
                Material(
                  color: Colors.white,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Share context with OpenAI',
                      style: TextStyle(
                        color: Color(0xFF243448),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      widget.context.dealId != null
                          ? 'When you send: this deal’s permitted financial figures, tasks, owner notes, file names, your excerpt and this conversation.'
                          : 'When you send: current page figures, saved goals provided to Nova, your excerpt and this conversation.',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    value: _shareContext,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _shareContext = value ?? false;
                            _error = null;
                          }),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showEvidence = !_showEvidence),
                  icon: const Icon(Icons.note_add_outlined, size: 16),
                  label: Text(
                    _showEvidence
                        ? 'Hide supporting information'
                        : 'Add figures or a statement excerpt',
                  ),
                ),
                if (_showEvidence)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _evidence,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 10000,
                      style: const TextStyle(color: Color(0xFF243448)),
                      decoration: const InputDecoration(
                        labelText:
                            'Supporting information for this conversation',
                        hintText:
                            'Include periods, currency and source. Example: EBITDA 2024: 260,000; 2025: 220,000.',
                        helperText:
                            'Nova sees saved data and pasted text, not the contents of uploaded files.',
                        helperMaxLines: 3,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  style: const TextStyle(color: Color(0xFF243448)),
                  decoration: InputDecoration(
                    hintText: _tab == 'learn'
                        ? 'Ask a question or answer the learning check…'
                        : 'Ask about this workspace…',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Send to Nova',
                      onPressed: _busy ? null : () => _ask(),
                      icon: const Icon(
                        Icons.arrow_upward_rounded,
                        color: _forest,
                      ),
                    ),
                  ),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Nova is reviewing your context…',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFA33C25)),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Live answers use your current context and conversation. Confirm important decisions with your advisers.',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String id, String title) => ChoiceChip(
    label: Text(title),
    selected: _tab == id,
    onSelected: _busy ? null : (_) => setState(() => _tab = id),
  );
  Widget _tour() {
    final steps = novaTour(widget.tourRole!);
    final (title, copy, destination) = steps[_tourIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR ${widget.tourRole!.toUpperCase()} WORKSPACE · ${_tourIndex + 1} OF ${steps.length}',
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            color: _forest,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          copy,
          style: const TextStyle(color: Color(0xFF243448), height: 1.6),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            if (widget.onTourNavigate != null)
              OutlinedButton.icon(
                onPressed: () => widget.onTourNavigate!(destination),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text('Open $title'),
              ),
            TextButton(
              onPressed: _tourIndex == 0
                  ? null
                  : () => _setTour(_tourIndex - 1),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () {
                if (_tourIndex == steps.length - 1) {
                  setState(() => _tab = 'learn');
                } else {
                  _setTour(_tourIndex + 1);
                }
              },
              child: Text(
                _tourIndex == steps.length - 1 ? 'Start learning' : 'Next',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _setTour(int index) {
    setState(() => _tourIndex = index);
    final key = _tourKey;
    SharedPreferences.getInstance().then((p) => p.setInt(key, index));
  }

  Widget _lesson() {
    final lessons = novaLessons;
    final lesson = lessons.firstWhere(
      (l) => l.id == _lessonId,
      orElse: () => lessons.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: lesson.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Choose a lesson',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final l in lessons)
              DropdownMenuItem(
                value: l.id,
                child: Text(l.title, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _busy ? null : (id) => setState(() => _lessonId = id!),
        ),
        const SizedBox(height: 16),
        Text(
          lesson.explanation,
          style: const TextStyle(color: Color(0xFF243448), height: 1.6),
        ),
        const SizedBox(height: 12),
        Text(
          'Worked example\n${lesson.example}',
          style: const TextStyle(color: _forest, height: 1.6),
        ),
        const SizedBox(height: 12),
        Text(
          'Learning check\n${lesson.check}',
          style: const TextStyle(
            color: Color(0xFF243448),
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Explain another way'),
              onPressed: _busy
                  ? null
                  : () => _ask(
                      'Explain ${lesson.title} another way, using my context.',
                    ),
            ),
            ActionChip(
              label: const Text('Check my understanding'),
              onPressed: _busy
                  ? null
                  : () => _ask(
                      'Ask me one question to check my understanding of ${lesson.title}, then wait for my answer.',
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

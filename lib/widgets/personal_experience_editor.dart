import 'package:flutter/material.dart';
import 'site_text.dart';
import '../services/marketplace_service.dart';

class PersonalExperienceEditor extends StatefulWidget {
  const PersonalExperienceEditor({
    super.key,
    required this.provider,
    required this.onSaved,
  });
  final MarketplaceProvider provider;
  final VoidCallback onSaved;
  @override
  State<PersonalExperienceEditor> createState() =>
      _PersonalExperienceEditorState();
}

class _PersonalExperienceEditorState extends State<PersonalExperienceEditor> {
  late final _text = TextEditingController(
    text: widget.provider.personalExperience,
  );
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (MarketplaceService.experienceWordCount(_text.text) > 200) {
      setState(() => _error = 'Keep your write-up to 200 words.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await MarketplaceService.savePersonalExperience(
        widget.provider.id,
        _text.text,
      );
      if (!mounted) return;
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Personal experience saved to your public member profile.',
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not save your write-up. Your text is still here; please try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SiteText(
        'Personal experience',
        contentKey: 'copy.personal_experience_editor.heading',
        literal: true,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const SiteText(
        contentKey: 'copy.personal_experience_editor.description',
        literal: true,
        'Tell buyers and sellers about your experience, the work you have done, and how you approach a deal. This appears on your public member profile.',
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('member_personal_experience'),
        controller: _text,
        minLines: 5,
        maxLines: 9,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hint: const SiteText(
            'Describe your background and the experience you bring to a deal.',
            contentKey: 'copy.personal_experience_editor.hint',
            literal: true,
          ),
          counterText:
              '${MarketplaceService.experienceWordCount(_text.text)} / 200 words',
          errorText: _error,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.save_outlined),
        label: _saving
            ? const Text('Saving…')
            : const SiteText(
                'Save personal experience',
                contentKey: 'copy.personal_experience_editor.save',
                literal: true,
              ),
      ),
    ],
  );
}

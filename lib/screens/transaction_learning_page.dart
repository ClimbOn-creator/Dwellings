import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/transaction_learning.dart';
import '../services/site_content_service.dart';
import '../models/platform_side.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/app_navigation_menu.dart';
import 'deal_rooms_page.dart';

class TransactionLearningPage extends StatelessWidget {
  const TransactionLearningPage({super.key});
  Future<void> _document(
    BuildContext context,
    TransactionLesson lesson,
    bool example,
  ) async {
    final key = 'transaction.${lesson.id}.${example ? 'example' : 'template'}';
    final fallback = lesson.document(filled: example);
    String currentText() => SiteContentService.text(key, fallback);
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          '${example ? "Worked example" : "Blank template"} · ${lesson.title}',
        ),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: SelectionArea(
              child: SiteCopyText(
                key,
                fallback,
                style: const TextStyle(height: 1.6),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const SiteCopyText('transaction.action.close', 'Close'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: currentText()));
              if (dialog.mounted)
                ScaffoldMessenger.of(dialog).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
            },
            child: const SiteCopyText('transaction.action.copy', 'Copy'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await FilePicker.platform.saveFile(
                  dialogTitle: 'Save learning document',
                  fileName:
                      '${lesson.id}-${example ? "example" : "template"}.md',
                  bytes: Uint8List.fromList(utf8.encode(currentText())),
                );
              } catch (_) {
                if (dialog.mounted)
                  ScaffoldMessenger.of(dialog).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not download. Use Copy to keep the document.',
                      ),
                    ),
                  );
              }
            },
            icon: const Icon(Icons.download),
            label: const SiteCopyText(
              'transaction.action.download',
              'Download .md',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F2FA),
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const HomeBrandButton(size: 48, dark: false),
      actions: const [AppNavigationMenu(dark: false)],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteCopyText(
                'transaction.library.kicker',
                'LEARN · PREPARE · APPLY',
                style: TextStyle(
                  color: Color(0xFF5544A0),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const SiteCopyText(
                'transaction.library.title',
                'Transaction Room',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 16),
              const SiteCopyText(
                'transaction.library.intro',
                'Understand the steps, practise with examples, then apply what you learn to your own deal. A Transaction Room brings the deal facts, evidence requests, advisers, tasks and documents into one place.',
                style: TextStyle(fontSize: 18, height: 1.5),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DealRoomsPage(
                          initialSide: PlatformSide.business,
                          startIntake: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const SiteCopyText(
                      'transaction.library.start',
                      'Apply this to a deal from any source',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DealRoomsPage(
                          initialSide: PlatformSide.business,
                        ),
                      ),
                    ),
                    child: const SiteCopyText(
                      'transaction.library.saved',
                      'Open my buyer dashboard',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SiteCopyText(
                'transaction.library.how',
                '1. Read the purpose.  2. Inspect the fictional worked example.  3. Download or copy the blank template.  4. Record the facts, gaps and adviser questions in your private deal. Use its task plan and document vault to track real work.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 14),
              const SiteCopyText(
                'transaction.library.scope',
                'These are typical preparation documents, not a universal list of legal requirements. Your country, deal structure, lender and advisers determine what is required. Agreement examples are preparation briefs—not contracts to sign. Template downloads are editable Markdown files; they do not automatically update your private deal.',
              ),
              const SizedBox(height: 30),
              for (final stage
                  in transactionLessons.map((e) => e.stage).toSet()) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: SiteCopyText(
                    'transaction.stage.${stage.split(" · ").first}',
                    stage,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final lesson in transactionLessons.where(
                  (e) => e.stage == stage,
                ))
                  Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SiteCopyText(
                            'transaction.${lesson.id}.title',
                            lesson.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SiteCopyText(
                            'transaction.${lesson.id}.purpose',
                            lesson.purpose,
                            style: const TextStyle(
                              color: Color(0xFF50505F),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _document(context, lesson, true),
                                child: const SiteCopyText(
                                  'transaction.action.example',
                                  'View worked example',
                                ),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    _document(context, lesson, false),
                                child: const SiteCopyText(
                                  'transaction.action.template',
                                  'Open blank template',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 26),
              const Text(
                'Further learning · local requirements still need professional confirmation',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.bdc.ca/en/articles-tools/start-buy-business/buy-business/buying-business-conducting-due-diligence',
                  ),
                ),
                child: const Text('BDC · Due diligence when buying a business'),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.sba.gov/counseling/plan-your-business/#buy-an-existing-business-or-franchise',
                  ),
                ),
                child: const Text('SBA · Buying an existing business'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

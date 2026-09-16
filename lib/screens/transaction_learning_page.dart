import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/transaction_learning.dart';
import '../models/platform_side.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/app_navigation_menu.dart';
import 'deal_rooms_page.dart';

class TransactionLearningPage extends StatelessWidget {
  const TransactionLearningPage({super.key});
  Future<void> _download(
    BuildContext context,
    TransactionLesson lesson,
    bool example,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await rootBundle.load(lesson.assetPath(filled: example));
      await FilePicker.platform.saveFile(
        dialogTitle:
            'Save ${example ? "completed example" : "editable template"}',
        fileName: lesson.fileName(filled: example),
        bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not download the ${lesson.fileTypeLabel} file. Please try again.',
          ),
        ),
      );
    }
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
                '1. Read the purpose.  2. Download the completed fictional example.  3. Download the blank Word or Excel template.  4. Replace the placeholders, attach evidence and record open adviser questions in your private deal.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 14),
              const SiteCopyText(
                'transaction.library.scope',
                'Every item includes an editable blank file and a completed fictional example. Word files cover briefs and review checklists; Excel files cover registers, financial schedules and operating plans. These are preparation documents, not contracts, legal advice, tax advice, lender approval or verified transaction evidence.',
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${lesson.fileTypeLabel} · .${lesson.fileExtension}',
                              style: const TextStyle(
                                color: Color(0xFF5544A0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _download(context, lesson, true),
                                child: const SiteCopyText(
                                  'transaction.action.example',
                                  'Download completed example',
                                ),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    _download(context, lesson, false),
                                child: const SiteCopyText(
                                  'transaction.action.template',
                                  'Download editable template',
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

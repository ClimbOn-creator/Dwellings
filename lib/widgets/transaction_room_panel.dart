import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/transaction_learning.dart';
import '../services/site_content_service.dart';
import 'site_copy_text.dart';
import 'site_image.dart';

const learningViolet = Color(0xFF6255DC);
const learningInk = Color(0xFF242536);
const learningMuted = Color(0xFF797B8B);

Widget learningCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(24),
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: const Color(0xFFEAE7F5)),
  ),
  child: child,
);

Future<void> downloadTransactionDocument(
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

class TransactionRoomPanel extends StatefulWidget {
  const TransactionRoomPanel({super.key, this.initialDocumentId});
  final String? initialDocumentId;
  @override
  State<TransactionRoomPanel> createState() => _TransactionRoomPanelState();
}

class _TransactionRoomPanelState extends State<TransactionRoomPanel> {
  late String selected;
  String query = '';
  @override
  void initState() {
    super.initState();
    selected = transactionLessons.any((l) => l.id == widget.initialDocumentId)
        ? widget.initialDocumentId!
        : transactionLessons.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = transactionLessons.firstWhere((l) => l.id == selected);
    final matches = transactionLessons
        .where(
          (l) => '${l.title} ${l.stage} ${l.purpose}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SiteCopyText(
          'transaction.library.kicker',
          'YOUR DOCUMENT WORKSPACE',
          style: TextStyle(
            color: learningViolet,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        const SiteCopyText(
          'transaction.library.title',
          'Transaction Room',
          style: TextStyle(
            color: learningInk,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        const SiteCopyText(
          'transaction.library.intro',
          'Understand each document, see how it works, and take the next step with confidence.',
          style: TextStyle(color: learningMuted, fontSize: 16, height: 1.5),
        ),
        ValueListenableBuilder<int>(
          valueListenable: SiteContentService.revision,
          builder: (context, value, child) =>
              SiteContentService.published('image.transaction.hero') == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SiteImage(
                      contentKey: 'image.transaction.hero',
                      original: Image.asset(
                        'assets/images/affinity-deal-screen.jpg',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 22),
        learningCard(
          child: const Wrap(
            spacing: 28,
            runSpacing: 14,
            children: [
              _RoomFact(Icons.description_outlined, '11 document guides'),
              _RoomFact(Icons.edit_document, '11 editable templates'),
              _RoomFact(Icons.auto_stories_outlined, '11 worked examples'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SiteCopyText(
          'transaction.orientation.title',
          'Use the right document at the right moment.',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: learningInk,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Explore the guide, inspect the fictional example, then download a blank file for your own preparation.',
          style: TextStyle(color: learningMuted, height: 1.5),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('room-document-search'),
          onChanged: (value) => setState(() => query = value.trim()),
          decoration: InputDecoration(
            hintText: 'Find a document, stage or topic',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) {
            final navigation = learningCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'DOCUMENT LIBRARY',
                      style: TextStyle(
                        color: learningMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No matching documents. Try another search.'),
                    ),
                  for (final item in matches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: selected == item.id
                            ? const Color(0xFFEEEAFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          key: ValueKey('room-select-${item.id}'),
                          leading: Icon(
                            item.fileExtension == 'docx'
                                ? Icons.description_outlined
                                : Icons.table_chart_outlined,
                            color: learningViolet,
                          ),
                          title: SiteCopyText(
                            'transaction.${item.id}.title',
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: learningInk,
                            ),
                          ),
                          subtitle: Text(
                            '${item.stage}\n${item.fileTypeLabel} · .${item.fileExtension}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: learningMuted,
                            ),
                          ),
                          selected: selected == item.id,
                          onTap: () => setState(() => selected = item.id),
                        ),
                      ),
                    ),
                ],
              ),
            );
            if (box.maxWidth >= 850)
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 290, child: navigation),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TransactionDocumentGuide(
                      key: ValueKey(selected),
                      lesson: lesson,
                    ),
                  ),
                ],
              );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                learningCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose a document',
                        style: TextStyle(color: learningMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      if (matches.isEmpty)
                        const Text('No matching documents. Try another search.')
                      else
                        DropdownButton<String>(
                          key: const Key('room-document-picker'),
                          isExpanded: true,
                          value: matches.any((l) => l.id == selected)
                              ? selected
                              : null,
                          hint: const Text('Select a matching document'),
                          items: [
                            for (final l in matches)
                              DropdownMenuItem(
                                value: l.id,
                                child: SiteCopyText(
                                  'transaction.${l.id}.title',
                                  l.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => selected = value);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TransactionDocumentGuide(
                  key: ValueKey(selected),
                  lesson: lesson,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        learningCard(
          child: const SiteCopyText(
            'transaction.library.scope',
            'These editable tools help you organize facts, requests, calculations and adviser questions. They are not contracts, legal or tax advice, lender approval, a valuation, or verified transaction evidence. Confirm deal-specific decisions with qualified legal, accounting, tax and financing professionals.',
            style: TextStyle(color: learningMuted, height: 1.5),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _RoomFact extends StatelessWidget {
  const _RoomFact(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: learningViolet, size: 22),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(
            color: learningInk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class TransactionDocumentGuide extends StatelessWidget {
  const TransactionDocumentGuide({super.key, required this.lesson});
  final TransactionLesson lesson;
  Widget block(String title, String field, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: learningViolet,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SiteCopyText(
          'transaction.${lesson.id}.$field',
          value,
          style: const TextStyle(color: learningInk, height: 1.55),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => learningCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteCopyText(
          'transaction.stage.${lesson.stage.split(" · ").first}',
          lesson.stage.toUpperCase(),
          style: const TextStyle(
            color: learningViolet,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SiteCopyText(
          'transaction.${lesson.id}.title',
          lesson.title,
          style: const TextStyle(
            color: learningInk,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${lesson.fileTypeLabel.toUpperCase()} · .${lesson.fileExtension}',
          style: const TextStyle(color: learningMuted, fontSize: 12),
        ),
        const SizedBox(height: 22),
        block('WHAT IT IS', 'purpose', lesson.purpose),
        block('WHEN TO USE IT', 'when', lesson.whenToUse),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  downloadTransactionDocument(context, lesson, false),
              icon: const Icon(Icons.download_rounded),
              style: FilledButton.styleFrom(
                backgroundColor: learningViolet,
                foregroundColor: Colors.white,
              ),
              label: const SiteCopyText(
                'transaction.action.template',
                'DOWNLOAD EDITABLE TEMPLATE',
                style: TextStyle(fontSize: 11),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  downloadTransactionDocument(context, lesson, true),
              icon: const Icon(Icons.download_outlined),
              label: const SiteCopyText(
                'transaction.action.example',
                'DOWNLOAD WORKED EXAMPLE',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Fictional worked example',
          style: TextStyle(
            color: learningInk,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        SiteImage(
          contentKey: 'image.transaction.${lesson.id}.preview',
          original: Image.asset(
            lesson.previewAsset,
            height: 310,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          lesson.example,
          style: const TextStyle(color: learningMuted, height: 1.55),
        ),
        const SizedBox(height: 24),
        block('WHAT THE BUYER COMPLETES', 'complete', lesson.whatToComplete),
        block('WHO SHOULD REVIEW IT', 'review', lesson.reviewedBy),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EFFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: block('KEEP IN MIND', 'watchout', lesson.buyerWatchOut),
        ),
      ],
    ),
  );
}

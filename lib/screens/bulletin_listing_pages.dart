import '../widgets/site_image.dart';
import '../widgets/site_copy_text.dart';
import '../services/site_content_service.dart';
import '../widgets/site_inline_editor.dart';
import '../widgets/site_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/backend_service.dart';
import '../services/business_sale_bulletin_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import 'auth_page.dart';

const _blue = Color(0xFF154B47);
const _violet = Color(0xFF245663);
const _ink = Color(0xFF233445);
const _muted = Color(0xFF607080);
const _gradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFD9E8E3), Color(0xFFF2F0E9), Color(0xFFDAE5F0)],
);

class BulletinListingEditor extends StatefulWidget {
  const BulletinListingEditor({super.key, this.initial});
  final BusinessSaleBulletin? initial;
  @override
  State<BulletinListingEditor> createState() => _BulletinListingEditorState();
}

class _BulletinListingEditorState extends State<BulletinListingEditor> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  final List<String> _photos = [];
  bool _busy = false;
  bool _preview = false;
  String? _error;
  static const _labels = {
    'title': 'Business / listing title',
    'industry': 'Industry',
    'region': 'City, province & country',
    'asking_price_band': 'Asking price (CAD) or range',
    'revenue': 'Annual sales revenue (CAD)',
    'cash_flow': 'Annual cash flow (CAD)',
    'summary': 'Business description',
    'highlights': 'Investment highlights',
    'real_estate': 'Real estate (lease, owned, or not included)',
    'location_details': 'Property & location details',
    'reason_for_selling': 'Reason for selling',
    'source_label': 'Seller / broker name',
    'source_url': 'Original listing URL',
    'contact_url': 'Seller contact page URL',
    'listing_type': 'Listing type (business, franchise, etc.)',
  };

  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    final values = <String, dynamic>{
      ...?(b?.details),
      'title': b?.title,
      'industry': b?.industry,
      'region': b?.region,
      'asking_price_band': b?.askingPriceBand,
      'summary': b?.summary,
      'source_label': b?.sourceLabel,
      'source_url': b?.sourceUrl,
    };
    for (final key in _labels.keys) {
      _fields[key] = TextEditingController(text: '${values[key] ?? ''}');
    }
    _photos.addAll(b?.photos ?? []);
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _payload => {
    for (final key in [
      'title',
      'industry',
      'region',
      'asking_price_band',
      'summary',
      'source_label',
      'source_url',
    ])
      key: _fields[key]!.text.trim(),
    if (widget.initial?.updatedAt != null)
      'expected_updated_at': widget.initial!.updatedAt!.toIso8601String(),
    'details': {
      for (final key in [
        'revenue',
        'cash_flow',
        'highlights',
        'real_estate',
        'location_details',
        'reason_for_selling',
        'contact_url',
        'listing_type',
      ])
        key: _fields[key]!.text.trim(),
      'photos': _photos,
    },
  };

  Future<void> _upload() async {
    if (_busy) return;
    final files = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (files == null || !mounted) return;
    if (_photos.length + files.files.length > 8) {
      setState(() => _error = 'Choose at most eight photos in total.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      for (final file in files.files) {
        if (file.bytes == null) throw StateError('Could not read ${file.name}');
        final url = await BusinessSaleBulletinService.uploadPhoto(
          file.bytes!,
          file.extension ?? '',
        );
        if (!mounted) return;
        setState(() => _photos.add(url));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!_preview && !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await BusinessSaleBulletinService.saveListing(
        _payload,
        id: widget.initial?.id,
      );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save this listing. Your edits are still here. $e',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String key, {int lines = 1}) => TextFormField(
    controller: _fields[key],
    maxLines: lines,
    enabled: !_busy,
    maxLength: key == 'title'
        ? 180
        : key == 'summary'
        ? 2000
        : 3000,
    decoration: InputDecoration(
      label: siteInputCopy(
        _labels[key],
        contentKey: 'copy.bulletin_listing_pages.field.dynamic1',
      ),
      filled: true,
      fillColor: const Color(0xFFF7F9FF),
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: (raw) {
      final value = raw?.trim() ?? '';
      if (key == 'title' && value.length < 3) {
        return 'Enter a title of at least three characters';
      }
      if (key == 'summary' && value.length < 20) {
        return 'Describe the business in at least 20 characters';
      }
      if (key.endsWith('_url') &&
          value.isNotEmpty &&
          !BusinessSaleBulletin.validWebUrl(value)) {
        return 'Use a complete http or https URL';
      }
      return null;
    },
  );
  Widget _section(
    String title,
    IconData icon,
    List<String> keys, {
    bool long = false,
  }) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _violet),
            const SizedBox(width: 10),
            Expanded(
              child: SiteText(
                contentKey: 'copy.bulletin_listing_pages.m1',
                literal: false,
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: keys
                .map(
                  (key) => SizedBox(
                    width: long || box.maxWidth < 620
                        ? box.maxWidth
                        : (box.maxWidth - 16) / 2,
                    child: _field(key, lines: long ? 4 : 1),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: SiteText(
        contentKey: 'copy.bulletin_listing_pages.m2',
        literal: false,
        widget.initial == null ? 'Add a business' : 'Update business',
      ),
      backgroundColor: Colors.white,
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: SizedBox.expand(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.bulletin_listing_pages.m3',
                    literal: false,
                    widget.initial == null
                        ? 'Give your business a proper introduction.'
                        : 'Keep buyers up to date.',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SiteText(
                    contentKey: 'copy.bulletin_listing_pages.m4',
                    literal: false,
                    widget.initial == null
                        ? 'Build a listing with photos, financials and the details buyers need.'
                        : 'Changes notify only the users and members who saved this listing.',
                    style: const TextStyle(fontSize: 16, color: _muted),
                  ),
                  const SizedBox(height: 24),
                  if (_preview)
                    BulletinListingBody(
                      bulletin: BusinessSaleBulletin.fromJson({
                        'id': 'preview',
                        ..._payload,
                      }),
                    )
                  else
                    Form(
                      key: _form,
                      child: Column(
                        children: [
                          _section(
                            'Business overview',
                            Icons.storefront_outlined,
                            ['title', 'industry', 'region', 'listing_type'],
                          ),
                          _section('The numbers', Icons.payments_outlined, [
                            'asking_price_band',
                            'revenue',
                            'cash_flow',
                          ]),
                          _Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SiteText(
                                  contentKey: 'copy.bulletin_listing_pages.1',
                                  literal: true,
                                  'Business photos',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const SiteText(
                                  contentKey: 'copy.bulletin_listing_pages.2',
                                  literal: true,
                                  'Up to 8 JPG, PNG or WebP images, 8 MB each. Uploaded photos are public; use images you have permission to share.',
                                  style: TextStyle(color: _muted),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (var i = 0; i < _photos.length; i++)
                                      SizedBox(
                                        width: 150,
                                        child: Column(
                                          children: [
                                            BulletinPhoto(
                                              url: _photos[i],
                                              height: 110,
                                            ),
                                            TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () => setState(
                                                      () => _photos.removeAt(i),
                                                    ),
                                              child: const SiteText(
                                                contentKey:
                                                    'copy.bulletin_listing_pages.3',
                                                literal: true,
                                                'Remove from listing',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: _busy ? null : _upload,
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: const SiteText(
                                    contentKey: 'copy.bulletin_listing_pages.4',
                                    literal: true,
                                    'Add photos',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _section(
                            'The opportunity',
                            Icons.description_outlined,
                            ['summary', 'highlights'],
                            long: true,
                          ),
                          _section(
                            'Property information',
                            Icons.location_on_outlined,
                            ['real_estate'],
                          ),
                          _section(
                            'Location & business operation',
                            Icons.business_outlined,
                            ['location_details', 'reason_for_selling'],
                            long: true,
                          ),
                          _section(
                            'Seller & source',
                            Icons.contact_page_outlined,
                            ['source_label', 'source_url', 'contact_url'],
                          ),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: SiteText(
                        contentKey: 'copy.bulletin_listing_pages.m5',
                        literal: false,
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                        ),
                        icon: Icon(
                          _busy ? Icons.hourglass_top : Icons.check_rounded,
                        ),
                        label: SiteText(
                          contentKey: 'copy.bulletin_listing_pages.m6',
                          literal: false,
                          _busy
                              ? 'Saving…'
                              : widget.initial == null
                              ? 'Publish business'
                              : 'Save update',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                if (!_preview &&
                                    !_form.currentState!.validate()) {
                                  return;
                                }
                                setState(() => _preview = !_preview);
                              },
                        child: SiteText(
                          contentKey: 'copy.bulletin_listing_pages.m7',
                          literal: false,
                          _preview ? 'Back to editor' : 'Preview listing',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class BusinessListingDetailPage extends StatefulWidget {
  const BusinessListingDetailPage({super.key, required this.bulletinId});
  final String bulletinId;
  @override
  State<BusinessListingDetailPage> createState() =>
      _BusinessListingDetailPageState();
}

class _BusinessListingDetailPageState extends State<BusinessListingDetailPage> {
  late Future<BusinessSaleBulletin?> _listing;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() =>
      _listing = BusinessSaleBulletinService.loadOne(widget.bulletinId);
  Future<void> _toggle(BusinessSaleBulletin b) async {
    if (_saving) return;
    if (!b.isExample && BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted) return;
      setState(_refresh);
      return;
    }
    setState(() => _saving = true);
    try {
      await BusinessSaleBulletinService.setSaved(b.id, !b.isSaved);
      if (mounted) setState(_refresh);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              templateValues: {'value1': '${e}'},
              contentKey: 'copy.bulletin_listing_pages.m8',
              literal: false,
              "Could not change saved status: {{value1}}",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const HomeBrandButton(size: 48, dark: false),
      actions: const [AppNavigationMenu(dark: false)],
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: SizedBox.expand(
        child: FutureBuilder<BusinessSaleBulletin?>(
          future: _listing,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SiteText(
                      contentKey: 'copy.bulletin_listing_pages.5',
                      literal: true,
                      'This listing is unavailable.',
                    ),
                    TextButton(
                      onPressed: () => setState(_refresh),
                      child: const SiteText(
                        contentKey: 'copy.bulletin_listing_pages.6',
                        literal: true,
                        'Retry',
                      ),
                    ),
                  ],
                ),
              );
            }
            final b = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Column(
                    children: [
                      BulletinListingBody(
                        bulletin: b,
                        onChanged: () => setState(_refresh),
                      ),
                      _Panel(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _saving ? null : () => _toggle(b),
                              icon: Icon(
                                b.isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                              label: SiteText(
                                contentKey: 'copy.bulletin_listing_pages.m9',
                                literal: false,
                                b.isExample
                                    ? (b.isSaved
                                          ? 'Saved example'
                                          : 'Save example')
                                    : b.isSaved
                                    ? 'Saved · stop following'
                                    : 'Save & follow updates',
                              ),
                            ),
                            if (BusinessSaleBulletin.validWebUrl(
                              b.detail('contact_url').isEmpty
                                  ? b.sourceUrl
                                  : b.detail('contact_url'),
                            ))
                              FilledButton(
                                onPressed: () async {
                                  final url = b.detail('contact_url').isEmpty
                                      ? b.sourceUrl
                                      : b.detail('contact_url');
                                  final opened = await launchUrl(
                                    Uri.parse(url),
                                  );
                                  if (!opened && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: SiteText(
                                          contentKey:
                                              'copy.bulletin_listing_pages.m10',
                                          literal: true,
                                          'Could not open the seller page.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFBD7011),
                                ),
                                child: const SiteText(
                                  contentKey: 'copy.bulletin_listing_pages.7',
                                  literal: true,
                                  'Contact seller',
                                ),
                              ),
                            if (b.canEdit)
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final id = await Navigator.of(context)
                                      .push<String>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BulletinListingEditor(initial: b),
                                        ),
                                      );
                                  if (id != null && mounted) setState(_refresh);
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const SiteText(
                                  contentKey: 'copy.bulletin_listing_pages.8',
                                  literal: true,
                                  'Edit listing',
                                ),
                              ),
                            TextButton.icon(
                              onPressed: () async {
                                final url = Uri.base.replace(
                                  queryParameters: {
                                    'module': 'bulletin-board',
                                    'bulletin': b.id,
                                  },
                                  fragment: '',
                                );
                                await Clipboard.setData(
                                  ClipboardData(text: url.toString()),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: SiteText(
                                        contentKey:
                                            'copy.bulletin_listing_pages.m11',
                                        literal: true,
                                        'Listing link copied.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.link),
                              label: const SiteText(
                                contentKey: 'copy.bulletin_listing_pages.9',
                                literal: true,
                                'Copy link',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class BulletinListingBody extends StatelessWidget {
  const BulletinListingBody({
    super.key,
    required this.bulletin,
    this.onChanged,
  });
  final VoidCallback? onChanged;
  final BusinessSaleBulletin bulletin;
  @override
  Widget build(BuildContext context) {
    final b = bulletin;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (b.isExample) ...[
          const _Panel(
            child: SiteCopyText(
              'marketplace.examples.detail_notice',
              'FICTIONAL EXAMPLE · Illustrative figures in CAD. This business is not for sale and has no seller to contact.',
              style: TextStyle(fontSize: 15, color: _blue, height: 1.5),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SiteImage(
              contentKey: 'image.marketplace.${b.id}',
              original: Image.asset(
                b.exampleAsset,
                height: 320,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: SiteText(
                      contentKey: 'copy.bulletin_listing_pages.m12',
                      literal: false,
                      b.industry,
                    ),
                  ),
                  Chip(
                    backgroundColor: const Color(0xFFE9DDFF),
                    label: SiteText(
                      contentKey: 'copy.bulletin_listing_pages.m13',
                      literal: false,
                      b.detail('listing_type').isEmpty
                          ? 'Business for sale'
                          : b.detail('listing_type'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SiteText(
                contentKey: 'copy.bulletin_listing_pages.m14',
                literal: false,
                b.title,
                style: const TextStyle(
                  fontSize: 32,
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SiteText(
                contentKey: 'copy.bulletin_listing_pages.m15',
                literal: false,
                b.region,
                style: const TextStyle(fontSize: 18, color: _muted),
              ),
              const SizedBox(height: 24),
              ListingNumbers(bulletin: b),
              const SizedBox(height: 18),
              SiteText(
                templateValues: {
                  'value1':
                      '${DateFormat.yMMMd().add_jm().format((b.updatedAt ?? b.postedAt).toLocal())}',
                },
                contentKey: 'copy.bulletin_listing_pages.m16',
                literal: false,
                "Updated {{value1}}",
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        if (b.photos.isNotEmpty)
          _Panel(
            child: LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: b.photos
                    .map(
                      (url) => SizedBox(
                        width: box.maxWidth < 650
                            ? box.maxWidth
                            : (box.maxWidth - 24) / 3,
                        child: BulletinPhoto(url: url, height: 210),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        _textSection('About the business', b.summary),
        if (b.detail('highlights').isNotEmpty)
          _textSection('Investment highlights', b.detail('highlights')),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteText(
                contentKey: 'copy.bulletin_listing_pages.10',
                literal: true,
                'Property information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 18),
              _detailRow('Real estate', b.detail('real_estate')),
              _detailRow('Location', b.detail('location_details')),
            ],
          ),
        ),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteText(
                contentKey: 'copy.bulletin_listing_pages.11',
                literal: true,
                'Business operation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _violet,
                ),
              ),
              const SizedBox(height: 18),
              _detailRow('Reason for selling', b.detail('reason_for_selling')),
              _detailRow('Seller / broker', b.sourceLabel),
            ],
          ),
        ),
      ],
    );
    if (!b.canEdit || onChanged == null) return content;
    return SiteRecordEditTarget(
      child: content,
      onEdit: () async {
        final id = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => BulletinListingEditor(initial: b)),
        );
        if (id != null) onChanged?.call();
      },
    );
  }

  Widget _textSection(String title, String text) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(
          contentKey: 'copy.bulletin_listing_pages.m17',
          literal: false,
          title,
          style: const TextStyle(
            fontSize: 24,
            color: _blue,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: SiteContentService.editing,
          builder: (context, editing, _) => IgnorePointer(
            ignoring: editing && onChanged != null,
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 16, height: 1.65, color: _ink),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _detailRow(String key, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SiteText(
            contentKey: 'copy.bulletin_listing_pages.m18',
            literal: false,
            key,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: SiteText(
            contentKey: 'copy.bulletin_listing_pages.m19',
            literal: false,
            value.isEmpty ? 'Not disclosed' : value,
            style: const TextStyle(fontSize: 16, color: _muted, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class BulletinMarketplaceCard extends StatelessWidget {
  const BulletinMarketplaceCard({
    super.key,
    required this.bulletin,
    required this.onOpen,
    this.dealScore,
    this.onSave,
    this.onEdit,
    this.onConvert,
  });
  final BusinessSaleBulletin bulletin;
  final int? dealScore;
  final VoidCallback? onSave, onEdit, onConvert;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onOpen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: bulletin.isExample
                ? SiteImage(
                    contentKey: 'image.marketplace.${bulletin.id}',
                    original: Image.asset(
                      bulletin.exampleAsset,
                      height: 255,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : BulletinPhoto(
                    url: bulletin.photos.isEmpty ? '' : bulletin.photos.first,
                    height: 255,
                  ),
          ),
        ),
        const SizedBox(height: 20),
        if (bulletin.isExample)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SiteCopyText(
              'marketplace.examples.badge',
              'FICTIONAL EXAMPLE · CAD',
              style: TextStyle(
                color: _blue,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            Chip(
              backgroundColor: const Color(0xFFE0ECE5),
              label: SiteText(
                contentKey: 'copy.bulletin_listing_pages.m20',
                literal: false,
                bulletin.industry,
              ),
            ),
            if (!bulletin.isExample &&
                DateTime.now().difference(bulletin.postedAt).inDays < 7)
              const Chip(
                backgroundColor: Color(0xFFFFD9E8),
                label: SiteText(
                  contentKey: 'copy.bulletin_listing_pages.m21',
                  literal: true,
                  'NEW',
                ),
              ),
            if (dealScore != null)
              Chip(
                backgroundColor: const Color(0xFFC8F0DD),
                label: SiteText(
                  templateValues: {'value1': '${dealScore}'},
                  contentKey: 'copy.bulletin_listing_pages.m22',
                  literal: false,
                  "Your deal score · {{value1}}/100",
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onOpen,
          child: SiteText(
            contentKey: 'copy.bulletin_listing_pages.m23',
            literal: false,
            bulletin.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _blue,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SiteText(
          contentKey: 'copy.bulletin_listing_pages.m24',
          literal: false,
          bulletin.region,
          style: const TextStyle(fontSize: 17, color: _muted),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, box) {
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListingNumbers(bulletin: bulletin),
                const SizedBox(height: 14),
                SiteText(
                  contentKey: 'copy.bulletin_listing_pages.m25',
                  literal: false,
                  bulletin.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: _ink,
                  ),
                ),
              ],
            );
            return info;
          },
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(backgroundColor: _blue),
              child: const SiteText(
                contentKey: 'copy.bulletin_listing_pages.12',
                literal: true,
                'More details',
              ),
            ),
            OutlinedButton.icon(
              onPressed: onSave,
              icon: Icon(
                bulletin.isSaved ? Icons.bookmark : Icons.bookmark_border,
              ),
              label: SiteText(
                contentKey: 'copy.bulletin_listing_pages.m26',
                literal: false,
                bulletin.isExample
                    ? (bulletin.isSaved ? 'Saved example' : 'Save example')
                    : bulletin.isSaved
                    ? 'Saved · following updates'
                    : 'Save business',
              ),
            ),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const SiteText(
                  contentKey: 'copy.bulletin_listing_pages.13',
                  literal: true,
                  'Edit listing',
                ),
              ),
            if (onConvert != null)
              TextButton.icon(
                onPressed: onConvert,
                icon: const Icon(Icons.content_copy),
                label: const SiteText(
                  contentKey: 'copy.bulletin_listing_pages.14',
                  literal: true,
                  'Make anonymous deal',
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class ListingNumbers extends StatelessWidget {
  const ListingNumbers({super.key, required this.bulletin});
  final BusinessSaleBulletin bulletin;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          [
                (
                  'Asking price',
                  bulletin.askingPriceBand,
                  const Color(0xFFE2EBE5),
                ),
                (
                  'Annual revenue',
                  bulletin.detail('revenue'),
                  const Color(0xFFE4EBF0),
                ),
                (
                  'Annual cash flow',
                  bulletin.detail('cash_flow'),
                  const Color(0xFFF1EBDD),
                ),
              ]
              .map(
                (v) => Container(
                  width: box.maxWidth < 480
                      ? box.maxWidth
                      : (box.maxWidth - 20) / 3,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: v.$3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SiteText(
                        contentKey: 'copy.bulletin_listing_pages.m27',
                        literal: false,
                        v.$1,
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                      const SizedBox(height: 6),
                      SiteText(
                        contentKey: 'copy.bulletin_listing_pages.m28',
                        literal: false,
                        v.$2.isEmpty ? 'Not disclosed' : v.$2,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    ),
  );
}

class BulletinPhoto extends StatelessWidget {
  const BulletinPhoto({super.key, required this.url, required this.height});
  final String url;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: url.isEmpty
          ? _placeholder()
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            ),
    ),
  );
  Widget _placeholder() => Container(
    decoration: const BoxDecoration(gradient: _gradient),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 42, color: _violet),
          SizedBox(height: 8),
          SiteText(
            contentKey: 'copy.bulletin_listing_pages.m29',
            literal: true,
            'Photo not provided',
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFD4DFD9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10245DD8),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

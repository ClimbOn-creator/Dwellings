import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/backend_service.dart';
import '../services/buyer_resources.dart';
import '../widgets/app_navigation_menu.dart';
import 'auth_page.dart';

const _resourceBlue = Color(0xFF007DA8);
const _resourceInk = Color(0xFF14374B);

Future<void> _officialLink(BuildContext context, String url) async {
  try {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw StateError('Could not open link');
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText('Open the official resource: $url')),
      );
    }
  }
}

/// Shared by the directory and the profile pushed from it, so save state stays
/// synchronized while navigating. Auth changes clear another user's selections.
class ResourceSelection extends ChangeNotifier {
  ResourceSelection() {
    _auth = BackendService.authChanges?.listen((_) => load());
    load();
  }
  Set<String> providers = {}, programs = {};
  bool loading = true;
  String? busy, error, _userId;
  int _generation = 0;
  bool _disposed = false;
  StreamSubscription<dynamic>? _auth;
  Future<void> load() async {
    final generation = ++_generation;
    final id = BackendService.user?.id;
    if (id != _userId) {
      providers = {};
      programs = {};
    }
    _userId = id;
    loading = true;
    error = null;
    if (!_disposed) notifyListeners();
    try {
      final result = await BuyerResourceTeam.loadSelection();
      if (_disposed || generation != _generation) return;
      providers = result.$1;
      programs = result.$2;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        error = 'Saved resources could not load. Please retry.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggle(
    BuildContext context,
    String id, {
    bool program = false,
  }) async {
    if (busy != null || loading || error != null) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (_disposed || !context.mounted) return;
      await load();
      if (BackendService.user == null || error != null) return;
    }
    final userId = BackendService.user?.id;
    final selected = program ? programs : providers;
    final saved = !selected.contains(id);
    busy = id;
    notifyListeners();
    try {
      if (program) {
        await BuyerResourceTeam.setProgramSaved(id, saved);
      } else {
        await BuyerResourceTeam.setSaved(id, saved);
      }
      if (_disposed || BackendService.user?.id != userId) return;
      // Update only after the backend confirms the write. Failed writes never
      // show a success check or trigger the success swirl.
      final target = program ? programs : providers;
      if (saved) {
        target.add(id);
      } else {
        target.remove(id);
      }
      notifyListeners();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this change. Please try again.'),
          ),
        );
      }
    } finally {
      if (!_disposed) {
        busy = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _auth?.cancel();
    super.dispose();
  }
}

class BuyerResourcesPage extends StatelessWidget {
  const BuyerResourcesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FBFD),
    appBar: AppBar(
      title: const Text('Resources'),
      actions: const [AppNavigationMenu(dark: false)],
    ),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(child: SizedBox(width: 1240, child: BuyerResourcesPanel())),
    ),
  );
}

class BuyerResourcesPanel extends StatefulWidget {
  const BuyerResourcesPanel({super.key, this.teamOnly = false});
  final bool teamOnly;
  @override
  State<BuyerResourcesPanel> createState() => _BuyerResourcesPanelState();
}

class _BuyerResourcesPanelState extends State<BuyerResourcesPanel> {
  late final ResourceSelection selection = ResourceSelection();
  String _query = '', _kind = 'All', _region = 'All regions';
  @override
  void initState() {
    super.initState();
    selection;
  }

  @override
  void dispose() {
    selection.dispose();
    super.dispose();
  }

  Future<void> _profile(BuyerResource resource) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResourceProviderPage(resource: resource, selection: selection),
      ),
    );
    if (mounted) await selection.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: selection,
    builder: (context, _) {
      final visible = buyerResources
          .where(
            (r) =>
                (!widget.teamOnly || selection.providers.contains(r.id)) &&
                r.matches(_query) &&
                (_kind == 'All' || r.kind == _kind) &&
                (_region == 'All regions' || r.region == _region),
          )
          .toList();
      final savedPrograms = resourcePrograms
          .where((p) => selection.programs.contains(p.id))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.teamOnly
                ? 'Your saved resources'
                : 'Good support. Greater possibilities.',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _resourceInk,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.teamOnly
                ? 'Your organizations and individual programs, together in one place.'
                : 'Find the people and programs behind your next business. Explore a provider, discover a grant, and keep your favourites close.',
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 20),
          if (!widget.teamOnly) ...[
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                labelText: 'Search resources',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in [
                  'All',
                  'Grants & contributions',
                  'Community support',
                  'Loans',
                  'Funding directory',
                ])
                  ChoiceChip(
                    label: Text(kind),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _region,
              isExpanded: true,
              items: [
                for (final region in [
                  'All regions',
                  'Canada',
                  'British Columbia',
                ])
                  DropdownMenuItem(
                    value: region,
                    child: Text(
                      region == 'Canada' ? 'Canada-wide programs' : region,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _region = v!),
            ),
            const SizedBox(height: 6),
            const Text(
              'Click a name to explore. Tap + to save to your profile and My Team.',
              style: TextStyle(color: Color(0xFF536775)),
            ),
          ],
          if (selection.loading) const LinearProgressIndicator(),
          if (selection.error != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(selection.error!),
                TextButton(
                  onPressed: selection.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          const SizedBox(height: 20),
          if (visible.isEmpty && !selection.loading && selection.error == null)
            Text(
              widget.teamOnly
                  ? 'No organizations saved yet. Explore Resources to add one.'
                  : 'No matching resources. Try another search or category.',
            ),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 1120
                  ? 4
                  : box.maxWidth >= 820
                  ? 3
                  : box.maxWidth >= 550
                  ? 2
                  : 1;
              final width = (box.maxWidth - (columns - 1) * 24) / columns;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  for (final r in visible)
                    SizedBox(
                      width: width,
                      child: ResourceProviderCard(
                        key: ValueKey(r.id),
                        resource: r,
                        saved: selection.providers.contains(r.id),
                        busy: selection.busy == r.id,
                        onOpen: () => _profile(r),
                        onSave:
                            selection.busy != null ||
                                selection.loading ||
                                selection.error != null
                            ? null
                            : () => selection.toggle(context, r.id),
                      ),
                    ),
                ],
              );
            },
          ),
          if (widget.teamOnly) ...[
            const SizedBox(height: 30),
            const Text(
              'Saved grants & programs',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: _resourceInk,
              ),
            ),
            const SizedBox(height: 12),
            if (savedPrograms.isEmpty && !selection.loading)
              const Text(
                'Save a specific grant or program from a provider’s profile.',
              ),
            for (final p in savedPrograms)
              ResourceProgramTile(program: p, selection: selection),
            TextButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BuyerResourcesPage(),
                    ),
                  )
                  .then((_) {
                    if (mounted) selection.load();
                  }),
              icon: const Icon(Icons.search),
              label: const Text('Explore all resources'),
            ),
          ] else ...[
            const SizedBox(height: 30),
            const Text(
              'Sources reviewed September 20, 2026. This is a curated directory; use the official funding finders for a broader search. Saving does not apply for funding or contact an organization.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF536775),
                height: 1.6,
              ),
            ),
          ],
        ],
      );
    },
  );
}

class ResourceLogo extends StatelessWidget {
  const ResourceLogo({super.key, required this.resource, this.size = 108});
  final BuyerResource resource;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        resource.displayName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: _resourceInk,
        ),
      ),
    );
    return Semantics(
      label: '${resource.displayName} logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: resource.id == 'community-futures'
              ? const Color(0xFF163D50)
              : Colors.white,
          border: Border.all(color: const Color(0xFFD7E6ED), width: 5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C123344),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: resource.logoAsset.endsWith('.svg')
            ? SvgPicture.asset(
                resource.logoAsset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => fallback,
              )
            : Image.asset(
                resource.logoAsset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class ResourceProviderCard extends StatelessWidget {
  const ResourceProviderCard({
    super.key,
    required this.resource,
    required this.saved,
    required this.busy,
    required this.onOpen,
    this.onSave,
  });
  final BuyerResource resource;
  final bool saved, busy;
  final VoidCallback onOpen;
  final Future<void> Function()? onSave;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topCenter,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 54),
        child: IntrinsicHeight(
          child: Container(
            constraints: const BoxConstraints(minHeight: 430),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 18),
            decoration: const BoxDecoration(
              color: _resourceBlue,
              boxShadow: [
                BoxShadow(
                  color: Color(0x30122A38),
                  blurRadius: 12,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  resource.kind.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    resource.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  resource.summary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 16),
                const Spacer(),
                Text(
                  resource.region,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 18),
                ResourceSaveButton(
                  saved: saved,
                  busy: busy,
                  onPressed: onSave,
                  name: resource.displayName,
                  onBlue: true,
                ),
              ],
            ),
          ),
        ),
      ),
      ResourceLogo(resource: resource),
    ],
  );
}

/// A confirmation flourish, never a substitute for the actual save result.
class ResourceSaveButton extends StatefulWidget {
  const ResourceSaveButton({
    super.key,
    required this.saved,
    required this.busy,
    required this.name,
    this.onPressed,
    this.onBlue = false,
  });
  final bool saved, busy, onBlue;
  final String name;
  final Future<void> Function()? onPressed;
  @override
  State<ResourceSaveButton> createState() => _ResourceSaveButtonState();
}

class _ResourceSaveButtonState extends State<ResourceSaveButton>
    with SingleTickerProviderStateMixin {
  late final _swirl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  @override
  void didUpdateWidget(covariant ResourceSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.saved &&
        widget.saved &&
        !MediaQuery.disableAnimationsOf(context)) {
      _swirl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swirl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.onBlue ? Colors.white : _resourceBlue;
    final label = widget.busy
        ? 'Saving…'
        : widget.saved
        ? 'Saved · remove'
        : 'Add to profile';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _swirl,
          builder: (context, _) => CustomPaint(
            painter: _SaveSwirl(_swirl.value, color),
            child: Transform.rotate(
              angle: Curves.easeOutCubic.transform(_swirl.value) * math.pi * 2,
              child: Transform.scale(
                scale: 1 + math.sin(_swirl.value * math.pi) * .18,
                child: SizedBox.square(
                  dimension: 56,
                  child: IconButton.outlined(
                    tooltip:
                        '${widget.saved ? 'Remove' : 'Save'} ${widget.name} ${widget.saved ? 'from' : 'to'} profile',
                    onPressed: widget.onPressed,
                    style: IconButton.styleFrom(
                      foregroundColor: color,
                      disabledForegroundColor: color.withValues(alpha: .55),
                      side: BorderSide(
                        color: color.withValues(alpha: .8),
                        width: 1.5,
                      ),
                    ),
                    icon: widget.busy
                        ? SizedBox.square(
                            dimension: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        : Icon(
                            widget.saved
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 28,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveSwirl extends CustomPainter {
  _SaveSwirl(this.progress, this.color);
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color.withValues(alpha: math.sin(math.pi * progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final radius = size.width / 2 + 4 + progress * 12 + i * 3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        progress * math.pi * 3 + i * math.pi * 2 / 3,
        math.pi * .55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SaveSwirl oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class ResourceProviderPage extends StatefulWidget {
  const ResourceProviderPage({
    super.key,
    required this.resource,
    required this.selection,
  });
  final BuyerResource resource;
  final ResourceSelection selection;
  @override
  State<ResourceProviderPage> createState() => _ResourceProviderPageState();
}

class _ResourceProviderPageState extends State<ResourceProviderPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.selection,
    builder: (context, _) {
      final r = widget.resource;
      final selection = widget.selection;
      final programs = r.programs.where((p) => p.matches(query)).toList();
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBFD),
        appBar: AppBar(
          title: const Text('Provider profile'),
          actions: const [AppNavigationMenu(dark: false)],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResourceLogo(resource: r, size: 120),
                  const SizedBox(height: 22),
                  Text(
                    r.displayName,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: _resourceInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${r.kind} · ${r.region}'),
                  const SizedBox(height: 16),
                  Text(
                    r.summary,
                    style: const TextStyle(fontSize: 18, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  Text(r.eligibility, style: const TextStyle(height: 1.6)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ResourceSaveButton(
                        saved: selection.providers.contains(r.id),
                        busy: selection.busy == r.id,
                        name: r.displayName,
                        onPressed:
                            selection.busy != null ||
                                selection.loading ||
                                selection.error != null
                            ? null
                            : () => selection.toggle(context, r.id),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _officialLink(context, r.url),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Official website'),
                      ),
                    ],
                  ),
                  if (selection.error != null)
                    TextButton(
                      onPressed: selection.load,
                      child: Text('${selection.error} Retry'),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    r.kind == 'Funding directory'
                        ? 'Explore grants & programs'
                        : 'Grants, programs & useful links',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: _resourceInk,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Search for a specific program or scroll the links below. Save individual programs to your profile without needing to save the provider.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      labelText: 'Search grants and programs',
                      hintText: 'Try training, wages or export',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (programs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No matching programs. Try another search or browse the official website.',
                      ),
                    ),
                  for (final p in programs)
                    ResourceProgramTile(program: p, selection: selection),
                  const SizedBox(height: 20),
                  const Text(
                    'Check current intake, eligibility and permitted costs on the official website. Saving is a bookmark, not an application or funding approval. Directory profile compiled by Affinity; no endorsement implied.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Color(0xFF536775),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ResourceProgramTile extends StatelessWidget {
  const ResourceProgramTile({
    super.key,
    required this.program,
    required this.selection,
  });
  final ResourceProgram program;
  final ResourceSelection selection;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${program.kind} · ${program.provider.displayName}',
              style: const TextStyle(
                color: _resourceBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              program.name,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(program.summary, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 10),
            Text(
              program.eligibility,
              style: const TextStyle(height: 1.5, color: Color(0xFF536775)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ResourceSaveButton(
                  key: ValueKey('save-${program.id}'),
                  saved: selection.programs.contains(program.id),
                  busy: selection.busy == program.id,
                  name: program.name,
                  onPressed:
                      selection.busy != null ||
                          selection.loading ||
                          selection.error != null
                      ? null
                      : () => selection.toggle(
                          context,
                          program.id,
                          program: true,
                        ),
                ),
                TextButton.icon(
                  onPressed: () => _officialLink(context, program.url),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Program details & application'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

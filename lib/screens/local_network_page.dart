import 'package:flutter/material.dart';

import '../services/marketplace_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/auth_button.dart';
import '../widgets/site_footer.dart';
import 'home_screen.dart';
import 'marketing_pages.dart';

const _ink = brandInk;
const _navy = Color(0xFF09091B);
const _paper = Color(0xFFF5F5F7);
const _purple = brandPurple;
const _lilac = brandLilac;
const _muted = Color(0xFFA5A5B5);

class LocalNetworkPage extends StatefulWidget {
  const LocalNetworkPage({super.key, this.initialCity});
  final MarketplaceCity? initialCity;

  @override
  State<LocalNetworkPage> createState() => _LocalNetworkPageState();
}

class _LocalNetworkPageState extends State<LocalNetworkPage> {
  late MarketplaceCity _city;
  ProviderCategory _category = ProviderCategory.realtor;
  late Future<MarketplaceDirectory> _directory;

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity ?? MarketplaceService.cities.first;
    _directory = MarketplaceService.load(_city);
  }

  void _changeCity(MarketplaceCity city) {
    setState(() {
      _city = city;
      _directory = MarketplaceService.load(city);
    });
  }

  void _openModel() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UnderwritingScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _NetworkHero(
            city: _city,
            onCity: _changeCity,
            onModel: _openModel,
          ),
        ),
        SliverToBoxAdapter(
          child: _DirectorySection(
            directory: _directory,
            city: _city,
            category: _category,
            onCategory: (value) => setState(() => _category = value),
          ),
        ),
        const SliverToBoxAdapter(child: _MarketplaceTrust()),
        SliverToBoxAdapter(
          child: SiteFooter(
            onHome: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            onAbout: () => openMarketingPage(
              context,
              MarketingDestination.about,
              replace: true,
            ),
            onTeam: () => openMarketingPage(
              context,
              MarketingDestination.team,
              replace: true,
            ),
            onMember: () => openMarketingPage(
              context,
              MarketingDestination.membership,
              replace: true,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NetworkHero extends StatelessWidget {
  const _NetworkHero({
    required this.city,
    required this.onCity,
    required this.onModel,
  });
  final MarketplaceCity city;
  final ValueChanged<MarketplaceCity> onCity;
  final VoidCallback onModel;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 850;
    return Container(
      height: desktop ? 680 : 790,
      color: _ink,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: desktop
                ? MediaQuery.sizeOf(context).width * .48
                : MediaQuery.sizeOf(context).width,
            child: Image.asset(
              'assets/images/hero-city.jpg',
              fit: BoxFit.cover,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: desktop
                    ? const [_ink, Color(0xF2050510), Color(0x4A050510)]
                    : const [_ink, Color(0xE9050510), Color(0xA0050510)],
                stops: desktop ? const [0, .58, 1] : const [0, .7, 1],
              ),
            ),
          ),
          Positioned(
            right: -120,
            top: -180,
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_purple.withValues(alpha: .3), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              desktop ? 54 : 22,
              24,
              desktop ? 54 : 22,
              54,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NetworkNav(onModel: onModel),
                const Spacer(),
                const Text(
                  'YOUR LOCAL PROPERTY TEAM',
                  style: TextStyle(
                    color: _lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'The right people.\nIn the right city.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: desktop ? 72 : 52,
                    height: .93,
                    fontWeight: FontWeight.w600,
                    letterSpacing: desktop ? -3.6 : -2.4,
                  ),
                ),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 560,
                  child: Text(
                    'Find local realtors, mortgage brokers, property lawyers and lenders around the market you are analyzing.',
                    style: TextStyle(
                      color: Color(0xFFC5C5D0),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _CitySelector(city: city, onChanged: onCity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkNav extends StatelessWidget {
  const _NetworkNav({required this.onModel});
  final VoidCallback onModel;
  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(34),
      border: Border.all(color: Colors.white.withValues(alpha: .11)),
    ),
    child: Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: const DwellingIqLogo(size: 44),
        ),
        const Spacer(),
        if (MediaQuery.sizeOf(context).width > 620)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'LOCAL NETWORK',
              style: TextStyle(
                color: _lilac,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        AuthButton(
          dark: true,
          compact: MediaQuery.sizeOf(context).width <= 720,
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: onModel,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
          ),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_outward, size: 16),
          label: Text(
            MediaQuery.sizeOf(context).width > 520 ? 'OPEN THE MODEL' : 'MODEL',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CitySelector extends StatelessWidget {
  const _CitySelector({required this.city, required this.onChanged});
  final MarketplaceCity city;
  final ValueChanged<MarketplaceCity> onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _showCanadianCityDialog(context, city, onChanged),
    child: Container(
      width: 390,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: _purple, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEARCH ANYWHERE IN CANADA',
                  style: TextStyle(
                    color: Color(0xFF7A7A87),
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  city.label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.search, color: _ink, size: 19),
        ],
      ),
    ),
  );
}

Future<void> _showCanadianCityDialog(
  BuildContext context,
  MarketplaceCity current,
  ValueChanged<MarketplaceCity> onChanged,
) async {
  final cityController = TextEditingController(text: current.city);
  var provinceCode = current.countryCode == 'CA' ? current.region : 'BC';
  final result = await showDialog<MarketplaceCity>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        title: const Text('Where in Canada are you looking?'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter any city, town, municipality or community.',
                style: TextStyle(color: Color(0xFF666674), fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: cityController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'City or municipality',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: provinceCode,
                decoration: const InputDecoration(
                  labelText: 'Province or territory',
                ),
                items: MarketplaceService.provinces
                    .map(
                      (province) => DropdownMenuItem(
                        value: province.code,
                        child: Text('${province.name} (${province.code})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => value == null
                    ? null
                    : setModalState(() => provinceCode = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final city = cityController.text.trim();
              if (city.isEmpty) return;
              Navigator.pop(
                dialogContext,
                MarketplaceService.customCity(city, provinceCode),
              );
            },
            child: const Text('Find professionals'),
          ),
        ],
      ),
    ),
  );
  cityController.dispose();
  if (result != null) onChanged(result);
}

class _DirectorySection extends StatelessWidget {
  const _DirectorySection({
    required this.directory,
    required this.city,
    required this.category,
    required this.onCategory,
  });
  final Future<MarketplaceDirectory> directory;
  final MarketplaceCity city;
  final ProviderCategory category;
  final ValueChanged<ProviderCategory> onCategory;

  @override
  Widget build(BuildContext context) => Container(
    color: _paper,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${city.city.toUpperCase()} NETWORK',
              style: const TextStyle(
                color: _purple,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Build your property team.',
              style: TextStyle(
                color: _ink,
                fontSize: 52,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -2.4,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Up to five providers per category. Sponsored placements are always disclosed.',
              style: TextStyle(color: Color(0xFF666674), fontSize: 14),
            ),
            const SizedBox(height: 36),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ProviderCategory.values
                    .map(
                      (value) => _CategoryTab(
                        value: value,
                        active: value == category,
                        onTap: () => onCategory(value),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),
            FutureBuilder<MarketplaceDirectory>(
              future: directory,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(color: _purple),
                    ),
                  );
                }
                final result = snapshot.data!;
                final providers = result.forCategory(category);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.isDemo) const _DemoBanner(),
                    if (!result.isDemo && providers.isEmpty)
                      _EmptyDirectory(city: city, category: category),
                    ...List.generate(
                      providers.length,
                      (index) => _ProviderRow(
                        rank: index + 1,
                        provider: providers[index],
                        city: city,
                        isDemo: result.isDemo,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyDirectory extends StatelessWidget {
  const _EmptyDirectory({required this.city, required this.category});
  final MarketplaceCity city;
  final ProviderCategory category;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 46),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE1E1E8)),
    ),
    child: Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFF0EEF9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_search_outlined, color: _purple),
        ),
        const SizedBox(height: 18),
        Text(
          'No verified ${category.label.toLowerCase()} in ${city.city} yet.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'The live directory is connected. Providers will appear here after onboarding and credential verification.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF666674), fontSize: 13, height: 1.5),
        ),
      ],
    ),
  );
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.value,
    required this.active,
    required this.onTap,
  });
  final ProviderCategory value;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: active ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? _ink : const Color(0xFFE0E0E7)),
        ),
        child: Text(
          value.label.toUpperCase(),
          style: TextStyle(
            color: active ? Colors.white : _ink,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      ),
    ),
  );
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEDE9FE),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Icon(Icons.science_outlined, color: _purple, size: 19),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'DEMO DIRECTORY · Connect Supabase and onboard verified providers to replace these example listings.',
            style: TextStyle(
              color: Color(0xFF4C348F),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProviderRow extends StatefulWidget {
  const _ProviderRow({
    required this.rank,
    required this.provider,
    required this.city,
    required this.isDemo,
  });
  final int rank;
  final MarketplaceProvider provider;
  final MarketplaceCity city;
  final bool isDemo;
  @override
  State<_ProviderRow> createState() => _ProviderRowState();
}

class _ProviderRowState extends State<_ProviderRow> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hovered ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: hovered ? _ink : const Color(0xFFE1E1E8)),
          boxShadow: [
            if (hovered)
              BoxShadow(
                color: _purple.withValues(alpha: .13),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        color: hovered ? Colors.white : _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                    if (provider.sponsored)
                      const _Badge(label: 'SPONSORED', color: _purple),
                    if (provider.verified)
                      const _Badge(label: 'VERIFIED', color: Color(0xFF16825D)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  provider.company,
                  style: TextStyle(
                    color: hovered ? _muted : const Color(0xFF60606D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  provider.specialty,
                  style: TextStyle(
                    color: hovered
                        ? const Color(0xFFD0D0DB)
                        : const Color(0xFF777783),
                    fontSize: 12,
                  ),
                ),
              ],
            );
            final signals = Wrap(
              spacing: 18,
              runSpacing: 9,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Signal(
                  icon: Icons.star_rounded,
                  text:
                      '${provider.reviewScore.toStringAsFixed(1)} (${provider.reviewCount})',
                  dark: hovered,
                ),
                _Signal(
                  icon: Icons.history,
                  text: '${provider.experience} yrs',
                  dark: hovered,
                ),
                if (provider.rateLabel != null)
                  _Signal(
                    icon: Icons.percent,
                    text: provider.rateLabel!,
                    dark: hovered,
                  ),
              ],
            );
            final button = FilledButton(
              onPressed: () => _showConnectionDialog(
                context,
                provider,
                widget.city,
                widget.isDemo,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: hovered ? Colors.white : _ink,
                foregroundColor: hovered ? _ink : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
              ),
              child: const Text(
                'CONNECT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            );
            return narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Rank(value: widget.rank, dark: hovered),
                          const SizedBox(width: 16),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 18),
                      signals,
                      const SizedBox(height: 18),
                      SizedBox(width: double.infinity, child: button),
                    ],
                  )
                : Row(
                    children: [
                      _Rank(value: widget.rank, dark: hovered),
                      const SizedBox(width: 20),
                      Expanded(flex: 5, child: details),
                      Expanded(flex: 3, child: signals),
                      const SizedBox(width: 18),
                      button,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  const _Rank({required this.value, required this.dark});
  final int value;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: dark ? Colors.white10 : const Color(0xFFF0EEF9),
      borderRadius: BorderRadius.circular(15),
    ),
    alignment: Alignment.center,
    child: Text(
      '$value',
      style: TextStyle(
        color: dark ? _lilac : _purple,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 7,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
    ),
  );
}

class _Signal extends StatelessWidget {
  const _Signal({required this.icon, required this.text, required this.dark});
  final IconData icon;
  final String text;
  final bool dark;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: dark ? _lilac : _purple),
      const SizedBox(width: 5),
      Text(
        text,
        style: TextStyle(
          color: dark ? Colors.white70 : const Color(0xFF555562),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

Future<void> _showConnectionDialog(
  BuildContext context,
  MarketplaceProvider provider,
  MarketplaceCity city,
  bool isDemo,
) async {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  var consent = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        title: Text('Connect with ${provider.name}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDemo)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'This is an example listing. The request will be demonstrated but not sent.',
                      style: TextStyle(
                        color: _purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: consent,
                  onChanged: (value) =>
                      setModalState(() => consent = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I consent to this provider contacting me about my property request.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed:
                !consent ||
                    name.text.trim().isEmpty ||
                    email.text.trim().isEmpty
                ? null
                : () async {
                    await MarketplaceService.requestConnection(
                      provider: provider,
                      city: city,
                      name: name.text.trim(),
                      email: email.text.trim(),
                      phone: phone.text.trim(),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isDemo
                              ? 'Demo connection complete. No request was sent.'
                              : 'Request sent. The provider can now contact you.',
                        ),
                      ),
                    );
                  },
            child: const Text('Send request'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  email.dispose();
  phone.dispose();
}

class _MarketplaceTrust extends StatelessWidget {
  const _MarketplaceTrust();
  @override
  Widget build(BuildContext context) => Container(
    color: _navy,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: Column(
          children: [
            const Text(
              'TRUST BEFORE PLACEMENT',
              style: TextStyle(
                color: _lilac,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Paid visibility. Clear disclosure.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -2.2,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 720,
              child: Text(
                'Providers may pay for placement, but sponsorship does not change verification status, professional credentials, rate accuracy or user reviews. Mortgage pricing is qualification-dependent and must display its effective date when live rate data is available.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14, height: 1.65),
              ),
            ),
            const SizedBox(height: 42),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: const [
                _TrustPill(Icons.campaign_outlined, 'Sponsored labels'),
                _TrustPill(
                  Icons.verified_user_outlined,
                  'Credential verification',
                ),
                _TrustPill(Icons.update, 'Rate timestamps'),
                _TrustPill(Icons.lock_outline, 'Consent-based leads'),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _TrustPill extends StatelessWidget {
  const _TrustPill(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _lilac, size: 17),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

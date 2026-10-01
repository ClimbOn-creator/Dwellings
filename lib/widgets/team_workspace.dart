import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/account_service.dart';
import '../services/marketplace_service.dart';
import '../screens/auth_page.dart';
import '../screens/member_profile_page.dart';
import '../screens/buyer_resources_page.dart';
import 'dashboard_ui.dart';
import 'team_member_portrait.dart';
import 'profile_photo.dart';
import '../models/platform_side.dart';

class TeamWorkspace extends StatefulWidget {
  const TeamWorkspace({
    super.key,
    this.seller = false,
    this.loadTeamProviders,
    this.onChanged,
  });
  final bool seller;
  final Future<(List<MarketplaceProvider>, Set<String>)> Function()?
  loadTeamProviders;
  final VoidCallback? onChanged;
  @override
  State<TeamWorkspace> createState() => _TeamWorkspaceState();
}

class _TeamWorkspaceState extends State<TeamWorkspace> {
  MarketplaceCity _teamCity = MarketplaceService.cities.first;
  String _teamQuery = '';
  BuyerTeamProfession? _teamProfession;
  String? _teamBusyId;
  Future<(List<MarketplaceProvider>, Set<String>)>? _teamData;
  @override
  Widget build(BuildContext context) => _buyerTeamPage();
  Future<(List<MarketplaceProvider>, Set<String>)> _loadTeamPageData() async {
    if (widget.loadTeamProviders != null) return widget.loadTeamProviders!();
    if (BackendService.user == null) {
      return (const <MarketplaceProvider>[], <String>{});
    }
    final values = await Future.wait([
      MarketplaceService.load(_teamCity, side: PlatformSide.business),
      AccountService.loadTeam(),
    ]);
    final directory = values[0] as MarketplaceDirectory;
    final team = values[1] as List<MarketplaceProvider>;
    final providers = directory.providers.toList();
    for (final provider in team) {
      if (!providers.any((item) => item.id == provider.id)) {
        providers.add(provider);
      }
    }
    return (providers, team.map((provider) => provider.id).toSet());
  }

  Widget _buyerTeamPage() {
    if (BackendService.user == null && widget.loadTeamProviders == null) {
      return LayoutBuilder(
        builder: (context, bounds) => SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: bounds.maxHeight > 52 ? bounds.maxHeight - 52 : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'My team',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DashboardUi.panel(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.group_outlined,
                            color: DashboardUi.blue,
                            size: 38,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.seller
                                ? 'Sign in to build your transfer team'
                                : 'Sign in to build your acquisition team',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Your advisers stay connected to your account and can be added to active transactions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: DashboardUi.muted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AuthPage(),
                                ),
                              );
                              if (mounted && BackendService.user != null) {
                                setState(() => _teamData = _loadTeamPageData());
                                widget.onChanged?.call();
                              }
                            },
                            child: const Text('Sign in'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    _teamData ??= _loadTeamPageData();
    return FutureBuilder<(List<MarketplaceProvider>, Set<String>)>(
      future: _teamData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _teamData = _loadTeamPageData()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry My Team'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final providers = snapshot.data!.$1;
        final selected = snapshot.data!.$2;
        final query = _teamQuery.trim().toLowerCase();
        final visible = providers.where((provider) {
          if (_teamProfession != null &&
              provider.category.teamProfession != _teamProfession)
            return false;
          final text = [
            provider.name,
            provider.company,
            provider.specialty,
            provider.category.teamProfession.label,
            provider.jobTitle,
            ...provider.specialties,
            ...provider.serviceMarkets,
            ...provider.locations,
          ].join(' ').toLowerCase();
          return query.isEmpty ||
              query.split(RegExp(r'\s+')).every(text.contains);
        }).toList();
        final myTeam = providers
            .where((provider) => selected.contains(provider.id))
            .toList();
        final available = visible
            .where((provider) => !selected.contains(provider.id))
            .toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 56),
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = box.maxWidth < 720;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'My team',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (myTeam.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 24,
                          runSpacing: 32,
                          children: [
                            for (final provider in myTeam)
                              SizedBox(
                                width: compact ? (box.maxWidth - 24) / 2 : 160,
                                child: _teamProviderCard(
                                  provider,
                                  selected: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Your team is empty. Find members below to get started.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  DashboardUi.panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardUi.sectionTitle(
                          'Find professionals',
                          subtitle: widget.seller
                              ? 'Search business sale and succession advisers and add them directly to your team.'
                              : 'Search business acquisition advisers and add them directly to your team.',
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Choose the roles your deal needs. One member per profession.',
                          style: TextStyle(color: DashboardUi.muted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All professions'),
                              selected: _teamProfession == null,
                              onSelected: (_) => setState(() {
                                _teamProfession = null;
                                _teamQuery = '';
                              }),
                            ),
                            for (final profession in BuyerTeamProfession.values)
                              ChoiceChip(
                                avatar: Icon(
                                  myTeam.any(
                                        (p) =>
                                            p.category.teamProfession ==
                                            profession,
                                      )
                                      ? Icons.check_circle_outline
                                      : Icons.add_circle_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  myTeam.any(
                                        (p) =>
                                            p.category.teamProfession ==
                                            profession,
                                      )
                                      ? '${profession.label} added'
                                      : profession.prompt,
                                ),
                                selected: _teamProfession == profession,
                                onSelected: (_) => setState(() {
                                  _teamProfession = profession;
                                  _teamQuery = '';
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (compact) ...[
                          _teamCityDropdown(),
                          const SizedBox(height: 10),
                          _teamSearchField(),
                        ] else
                          Row(
                            children: [
                              SizedBox(width: 250, child: _teamCityDropdown()),
                              const SizedBox(width: 10),
                              Expanded(child: _teamSearchField()),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (available.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                'No additional professionals match this search.',
                                style: TextStyle(color: DashboardUi.muted),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              for (final provider in available)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _teamSearchResult(
                                    provider,
                                    occupied: myTeam.any(
                                      (p) =>
                                          p.category.teamProfession ==
                                          provider.category.teamProfession,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  const BuyerResourcesPanel(teamOnly: true),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _teamCityDropdown() => DropdownButtonFormField<MarketplaceCity>(
    initialValue: _teamCity,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Search near',
      prefixIcon: Icon(Icons.location_on_outlined),
    ),
    items: [
      for (final city in MarketplaceService.citiesAlphabetically)
        DropdownMenuItem(value: city, child: Text(city.label)),
    ],
    onChanged: (city) {
      if (city == null) return;
      setState(() {
        _teamCity = city;
        _teamData = _loadTeamPageData();
      });
    },
  );

  Widget _teamSearchField() => TextField(
    key: ValueKey(_teamProfession),
    onChanged: (value) => setState(() => _teamQuery = value),
    decoration: const InputDecoration(
      labelText: 'Search professionals',
      hintText: 'Name, company, or specialty',
      prefixIcon: Icon(Icons.search),
    ),
  );

  Widget _teamSearchResult(
    MarketplaceProvider provider, {
    required bool occupied,
  }) => DashboardUi.panel(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfilePhoto(
          size: 44,
          photoUrl: provider.photoUrl,
          exampleIndex: provider.photoIndex,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.category.teamProfession.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: DashboardUi.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => _openTeamProfile(provider),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  provider.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                [
                  provider.company,
                  provider.jobTitle,
                ].where((v) => v.trim().isNotEmpty).join(' · '),
                style: const TextStyle(color: DashboardUi.muted, fontSize: 12),
              ),
              if (occupied)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Profession filled — remove your current member to switch.',
                    style: TextStyle(fontSize: 12, color: DashboardUi.muted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (_teamBusyId == provider.id)
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton.filledTonal(
            tooltip: occupied
                ? 'Profession already filled'
                : 'Add ${provider.name} to My Team',
            onPressed: occupied || _teamBusyId != null
                ? null
                : () => _toggleTeamPageProvider(provider, false),
            icon: const Icon(Icons.add),
          ),
      ],
    ),
  );

  Widget _teamProviderCard(
    MarketplaceProvider provider, {
    required bool selected,
  }) => TeamMemberPortrait(
    key: ValueKey('team-${selected ? 'saved' : 'available'}-${provider.id}'),
    provider: provider,
    selected: selected,
    busy: _teamBusyId == provider.id,
    onProfile: () => _openTeamProfile(provider),
    onToggle: _teamBusyId == null
        ? () => _toggleTeamPageProvider(provider, selected)
        : null,
  );

  Future<void> _openTeamProfile(MarketplaceProvider provider) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfilePage(provider: provider),
      ),
    );
    if (mounted) {
      setState(() => _teamData = _loadTeamPageData());
      widget.onChanged?.call();
    }
  }

  Future<void> _toggleTeamPageProvider(
    MarketplaceProvider provider,
    bool selected,
  ) async {
    setState(() => _teamBusyId = provider.id);
    try {
      if (selected) {
        await MarketplaceService.removeFromTeam(provider.id);
      } else {
        await MarketplaceService.addToTeam(provider);
      }
      if (mounted) {
        setState(() {
          _teamData = _loadTeamPageData();
          widget.onChanged?.call();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update your team: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _teamBusyId = null);
    }
  }
}

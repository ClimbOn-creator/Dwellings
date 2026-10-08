import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../models/platform_side.dart';
import '../services/deal_room_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/site_copy_text.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';

/// The main navigation's room entrypoint, separate from the buyer dashboard.
class TransactionRoomsPage extends StatefulWidget {
  const TransactionRoomsPage({super.key, this.loadRooms});
  final Future<List<DealRoom>> Function()? loadRooms;
  @override
  State<TransactionRoomsPage> createState() => _TransactionRoomsPageState();
}

class _TransactionRoomsPageState extends State<TransactionRoomsPage> {
  late Future<List<DealRoom>> _rooms;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _rooms = (widget.loadRooms ?? DealRoomService.loadRooms)();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FBFD),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 82,
      backgroundColor: const Color(0xFFF7F8F4),
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 66, dark: false),
      actions: const [
        AppNavigationMenu(guidePage: 'transaction-rooms', dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: FutureBuilder<List<DealRoom>>(
      future: _rooms,
      builder: (context, snapshot) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SiteCopyText(
                  'transaction.rooms.title',
                  'Transaction rooms',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const SiteCopyText(
                  'transaction.rooms.intro',
                  'Choose a deal to work on its documents, financials, team and transaction plan.',
                ),
                const SizedBox(height: 28),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError) ...[
                  const SiteCopyText(
                    'transaction.rooms.error',
                    'Could not load your transaction rooms. Please try again.',
                  ),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const SiteCopyText(
                      'transaction.rooms.retry',
                      'Try again',
                    ),
                  ),
                ] else if (snapshot.data!.isEmpty) ...[
                  const SiteCopyText(
                    'transaction.rooms.empty',
                    'Your deal rooms will appear here',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (BackendService.user == null && widget.loadRooms == null)
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AuthPage(
                            onAuthenticated: () {
                              Navigator.of(context).pop();
                              if (mounted) setState(_reload);
                            },
                          ),
                        ),
                      ),
                      child: const SiteCopyText(
                        'transaction.rooms.signin',
                        'Sign in to see your transaction rooms',
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DealRoomsPage(
                            initialSide: PlatformSide.business,
                          ),
                        ),
                      ),
                      child: const SiteCopyText(
                        'transaction.rooms.start',
                        'Open buyer dashboard',
                      ),
                    ),
                ] else
                  for (final room in snapshot.data!)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: const Icon(
                          Icons.folder_open_outlined,
                          color: Color(0xFF164F3D),
                        ),
                        title: Text(room.title),
                        subtitle: Text(room.currentStage.replaceAll('_', ' ')),
                        trailing: const Icon(Icons.arrow_forward_rounded),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DealRoomPage(room: room),
                            ),
                          );
                          if (mounted) setState(_reload);
                        },
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

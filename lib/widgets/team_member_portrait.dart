import 'package:flutter/material.dart';
import '../services/marketplace_service.dart';
import 'profile_photo.dart';

/// The photo manages membership; the name opens the professional's profile.
class TeamMemberPortrait extends StatefulWidget {
  const TeamMemberPortrait({
    super.key,
    required this.provider,
    required this.selected,
    required this.busy,
    required this.onProfile,
    this.onToggle,
  });
  final MarketplaceProvider provider;
  final bool selected, busy;
  final VoidCallback onProfile;
  final VoidCallback? onToggle;
  @override
  State<TeamMemberPortrait> createState() => _TeamMemberPortraitState();
}

class _TeamMemberPortraitState extends State<TeamMemberPortrait> {
  bool _hover = false, _focus = false;
  @override
  Widget build(BuildContext context) {
    final label = widget.selected ? 'Remove from My Team' : 'Add to My Team';
    final showAction = _hover || _focus || widget.busy;
    final provider = widget.provider;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          child: Semantics(
            label: '$label: ${provider.name}',
            button: true,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onHover: (value) => setState(() => _hover = value),
                onFocusChange: (value) => setState(() => _focus = value),
                onTap: widget.onToggle,
                child: SizedBox.square(
                  dimension: 108,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProfilePhoto(
                        size: 108,
                        photoUrl: provider.photoUrl,
                        exampleIndex: provider.photoIndex,
                      ),
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: showAction ? 1 : 0,
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 160),
                          child: Container(
                            color: const Color(0xDC173747),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(10),
                            child: widget.busy
                                ? const SizedBox.square(
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.selected
                                            ? Icons.remove_rounded
                                            : Icons.add_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        textScaler: TextScaler.noScaling,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.onProfile,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF173747),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: const Size(44, 44),
          ),
          child: Text(
            provider.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          provider.jobTitle.trim().isEmpty
              ? provider.specialty
              : provider.jobTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF71808C),
            height: 1.5,
          ),
        ),
        if (MediaQuery.sizeOf(context).width < 800)
          TextButton(
            onPressed: widget.onToggle,
            child: Text(
              widget.busy ? 'Saving…' : label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

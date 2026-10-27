import 'package:flutter/material.dart';
import 'profile_photo.dart';
import 'pact_professional_profile.dart';

class PactDesktopProfileHeader extends StatelessWidget {
  const PactDesktopProfileHeader({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.coverUrl,
    required this.headline,
    required this.company,
    required this.actions,
    this.onAvatar,
    this.onCover,
    this.verified = false,
    this.nameWidget,
    this.headlineWidget,
    this.exampleIndex,
  });
  factory PactDesktopProfileHeader.fromProfileHeader(
    PactProfessionalHeader p,
  ) => PactDesktopProfileHeader(
    name: p.name,
    photoUrl: p.photoUrl,
    coverUrl: p.coverUrl,
    headline: p.headline,
    company: p.company,
    actions: p.actions,
    onAvatar: p.onAvatar,
    onCover: p.onCover,
    verified: p.verified,
    nameWidget: p.nameWidget,
    headlineWidget: p.headlineWidget,
    exampleIndex: p.exampleIndex,
  );
  final String name, photoUrl, coverUrl, headline, company;
  final List<Widget> actions;
  final VoidCallback? onAvatar, onCover;
  final bool verified;
  final Widget? nameWidget, headlineWidget;
  final int? exampleIndex;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              coverUrl.isEmpty
                  ? Image.asset(
                      'assets/images/pact-river.jpg',
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/pact-river.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x5521293D)],
                  ),
                ),
              ),
              if (onCover != null)
                Positioned(
                  right: 18,
                  top: 18,
                  child: IconButton.filledTonal(
                    tooltip: 'Change cover photo',
                    onPressed: onCover,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final inline = c.maxWidth >= 1000;
            return Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: GestureDetector(
                          onTap: onAvatar,
                          child: Tooltip(
                            message: onAvatar == null
                                ? 'Profile photo'
                                : 'Change profile photo',
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ProfilePhoto(
                                size: 118,
                                photoUrl: photoUrl,
                                exampleIndex: exampleIndex,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child:
                                        nameWidget ??
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -.8,
                                          ),
                                        ),
                                  ),
                                  if (verified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Icon(
                                        Icons.verified_outlined,
                                        color: Color(0xFF6255DC),
                                        size: 21,
                                      ),
                                    ),
                                ],
                              ),
                              if (headline.isNotEmpty || company.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child:
                                      headlineWidget ??
                                      Text(
                                        [headline, company]
                                            .where((v) => v.isNotEmpty)
                                            .join(' · '),
                                        style: const TextStyle(
                                          color: Color(0xFF777584),
                                          height: 1.5,
                                        ),
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (inline && actions.isNotEmpty) ...[
                        const SizedBox(width: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: actions,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!inline && actions.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}

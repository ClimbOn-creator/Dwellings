import 'package:flutter/material.dart';
import 'site_image.dart';

/// One visual language, with more breathing room on desktop.
class PactAuthSurface extends StatelessWidget {
  const PactAuthSurface({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.compact = false,
  });
  final Widget title, subtitle, child;
  final bool compact;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6255DC),
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF6F5FA),
        labelStyle: const TextStyle(color: Color(0xFF777584), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDEBF3)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6255DC),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: const Color(0xFF292737),
          side: const BorderSide(color: Color(0xFFE4E1EC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;
          final topInset = MediaQuery.paddingOf(context).top;
          final heroHeight = (wide ? 340.0 : 260.0) + topInset;
          final form = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              subtitle,
              const SizedBox(height: 28),
              child,
            ],
          );
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SiteImage(
                        contentKey: 'image.auth.cover',
                        original: Image.asset(
                          'assets/images/pact-river.jpg',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -.1),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x4D171A25), Color(0xAA171A25)],
                          ),
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 56 : 24,
                            16,
                            wide ? 56 : 24,
                            42,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (!compact &&
                                      Navigator.canPop(context)) ...[
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.maybePop(context),
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  const Text(
                                    'PACT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.4,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xB3FFFFFF),
                                    size: 19,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'Your next chapter,\ntogether.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: wide ? 44 : 32,
                                  fontWeight: FontWeight.w500,
                                  height: 1.08,
                                  letterSpacing: -1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 1100),
                    margin: EdgeInsets.symmetric(horizontal: wide ? 40 : 0),
                    padding: EdgeInsets.fromLTRB(
                      wide ? 44 : 26,
                      wide ? 40 : 30,
                      wide ? 44 : 26,
                      18 + MediaQuery.paddingOf(context).bottom,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(wide ? 30 : 28),
                      boxShadow: wide
                          ? const [
                              BoxShadow(
                                color: Color(0x07000000),
                                blurRadius: 40,
                                offset: Offset(0, 16),
                              ),
                            ]
                          : null,
                    ),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    18,
                                    60,
                                    24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.blur_on_rounded,
                                        size: 38,
                                        color: Color(0xFF6255DC),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'A place for\nwhat comes next.',
                                        style: TextStyle(
                                          fontSize: 34,
                                          height: 1.15,
                                          letterSpacing: -1,
                                          color: Color(0xFF292737),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const Text(
                                        'Your workspace, your people, your next opportunity. Connected on every screen.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.7,
                                          color: Color(0xFF777584),
                                        ),
                                      ),
                                      const SizedBox(height: 34),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF6F4FF),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.devices_rounded,
                                              color: Color(0xFF6255DC),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'One account. Phone to desktop.',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF6255DC),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(child: form),
                            ],
                          )
                        : form,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

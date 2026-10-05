import 'package:flutter/material.dart';

class NovaTarget extends StatefulWidget {
  const NovaTarget({super.key, required this.id, required this.child});
  final String id;
  final Widget child;
  static final _anchors = <String, List<GlobalKey>>{};
  static BuildContext? contextFor(String id) {
    for (final key in (_anchors[id] ?? const <GlobalKey>[]).reversed) {
      final context = key.currentContext;
      if (context != null && ModalRoute.of(context)?.isCurrent != false)
        return context;
    }
    return null;
  }

  @override
  State<NovaTarget> createState() => _NovaTargetState();
}

class _NovaTargetState extends State<NovaTarget> {
  final _anchor = GlobalKey();
  @override
  void initState() {
    super.initState();
    NovaTarget._anchors.putIfAbsent(widget.id, () => []).add(_anchor);
  }

  @override
  void dispose() {
    NovaTarget._anchors[widget.id]?.remove(_anchor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _anchor, child: widget.child);
}

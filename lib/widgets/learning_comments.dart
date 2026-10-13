import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backend_service.dart';
import '../services/learning_service.dart';
import '../services/learning_examples.dart';
import '../screens/auth_page.dart';
import 'dashboard_ui.dart';

class LearningComments extends StatefulWidget {
  const LearningComments({
    super.key,
    required this.post,
    this.isOwner = false,
    this.loadComments,
    this.exampleComments,
    this.onExampleChanged,
  });
  final LearningPost post;
  final bool isOwner;
  final List<LearningComment>? exampleComments;
  final ValueChanged<List<LearningComment>>? onExampleChanged;
  final Future<List<LearningComment>> Function()? loadComments;
  @override
  State<LearningComments> createState() => _LearningCommentsState();
}

class _LearningCommentsState extends State<LearningComments> {
  final body = TextEditingController();
  final expanded = <String>{};
  late Future<List<LearningComment>> comments;
  LearningComment? reply;
  bool busy = false;
  String? error;
  int limit = 100;
  late List<LearningComment> exampleComments;
  int exampleSerial = 0;
  bool get isExample => widget.post.exampleIndex != null;
  @override
  void initState() {
    super.initState();
    exampleComments = List.of(
      widget.exampleComments ??
          (isExample
              ? LearningExamples.commentsFor(widget.post)
              : <LearningComment>[]),
    );
    exampleSerial = exampleComments.length;
    reload();
  }

  void reload() {
    if (isExample) {
      comments = Future.value(List.of(exampleComments));
      return;
    }
    comments =
        (widget.loadComments ??
        () => LearningService.comments(widget.post.id, limit: limit))();
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (isExample) {
      if (body.text.trim().isEmpty) {
        setState(() => error = 'Write a comment before posting.');
        return;
      }
      final comment = LearningComment(
        id: '${widget.post.id}-new-${exampleSerial++}',
        postId: widget.post.id,
        authorId: 'example-you',
        author: 'You (example)',
        body: body.text.trim(),
        createdAt: DateTime.now(),
        parentId: reply?.id,
        depth: reply == null ? 0 : reply!.depth + 1,
      );
      setState(() {
        exampleComments = [...exampleComments, comment];
        if (reply != null) expanded.add(reply!.id);
        body.clear();
        reply = null;
        error = null;
        reload();
      });
      widget.onExampleChanged?.call(List.of(exampleComments));
      return;
    }
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await LearningService.comment(
        widget.post.id,
        body.text,
        parentId: reply?.id,
      );
      if (!mounted) return;
      setState(() {
        if (reply != null) expanded.add(reply!.id);
        body.clear();
        reply = null;
        reload();
      });
    } catch (e) {
      if (mounted)
        setState(
          () => error = e.toString().contains('Please wait')
              ? 'Please wait a few minutes before posting more comments.'
              : e.toString().contains('comment was removed')
              ? 'That comment has been removed. Choose another comment to reply to.'
              : body.text.trim().isEmpty
              ? 'Write a comment before posting.'
              : 'Could not post this comment. Please try again.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove(LearningComment c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this comment?'),
        content: const Text(
          'Replies stay in the thread. Your comment text will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    if (isExample) {
      setState(() {
        exampleComments = exampleComments
            .map(
              (v) => v.id != c.id
                  ? v
                  : LearningComment(
                      id: v.id,
                      postId: v.postId,
                      authorId: v.authorId,
                      author: v.author,
                      body: '',
                      createdAt: v.createdAt,
                      parentId: v.parentId,
                      depth: v.depth,
                      removed: true,
                    ),
            )
            .toList();
        reload();
      });
      widget.onExampleChanged?.call(List.of(exampleComments));
      return;
    }
    try {
      await LearningService.removeComment(c.id);
      if (mounted) setState(reload);
    } catch (_) {
      if (mounted) setState(() => error = 'This comment could not be removed.');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        16,
        18,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comments',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close comments',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.post.title,
              style: const TextStyle(color: DashboardUi.muted),
            ),
          ),
          if (isExample)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Example thread · Changes stay in this preview',
                style: TextStyle(fontSize: 12, color: DashboardUi.muted),
              ),
            ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<LearningComment>>(
              future: comments,
              builder: (context, s) {
                if (s.hasError)
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(reload),
                      child: const Text('Could not load comments. Retry'),
                    ),
                  );
                if (!s.hasData)
                  return const Center(child: CircularProgressIndicator());
                final all = s.data!;
                if (all.isEmpty)
                  return const Center(
                    child: Text(
                      'Start the conversation. Ask a question or share a useful experience.',
                    ),
                  );
                final children = <String?, List<LearningComment>>{};
                for (final c in all) {
                  children.putIfAbsent(c.parentId, () => []).add(c);
                }
                Widget thread(LearningComment c) {
                  final replies = children[c.id] ?? [];
                  final open = expanded.contains(c.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        key: ValueKey('comment-${c.id}'),
                        margin: EdgeInsets.only(
                          left: math.min(c.depth, 3) * 12.0,
                          bottom: 12,
                        ),
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: c.depth == 0
                                  ? Colors.transparent
                                  : DashboardUi.line,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    c.author.isEmpty ? '?' : c.author[0],
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.author,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM d',
                                  ).format(c.createdAt.toLocal()),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: DashboardUi.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              c.removed ? 'Comment removed' : c.body,
                              style: TextStyle(
                                height: 1.5,
                                color: c.removed
                                    ? DashboardUi.muted
                                    : DashboardUi.ink,
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (!c.removed && c.depth < 8)
                                  TextButton(
                                    onPressed: () {
                                      setState(() => reply = c);
                                    },
                                    child: const Text('Reply'),
                                  ),
                                if (replies.isNotEmpty)
                                  TextButton(
                                    onPressed: () => setState(() {
                                      open
                                          ? expanded.remove(c.id)
                                          : expanded.add(c.id);
                                    }),
                                    child: Text(
                                      open
                                          ? 'Hide replies'
                                          : '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                                    ),
                                  ),
                                if (!c.removed &&
                                    (isExample
                                        ? c.authorId == 'example-you'
                                        : (c.authorId ==
                                                  BackendService.user?.id ||
                                              widget.isOwner)))
                                  TextButton(
                                    onPressed: () => remove(c),
                                    child: const Text('Remove'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (open)
                        for (final child in replies) thread(child),
                    ],
                  );
                }

                return ListView(
                  children: [
                    for (final c in children[null] ?? <LearningComment>[])
                      thread(c),
                    if (all.length >= limit)
                      TextButton(
                        onPressed: () => setState(() {
                          limit += 100;
                          reload();
                        }),
                        child: const Text('Load more comments'),
                      ),
                  ],
                );
              },
            ),
          ),
          if (reply != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to ${reply!.author}',
                    style: const TextStyle(color: DashboardUi.blue),
                  ),
                ),
                IconButton(
                  tooltip: 'Cancel reply',
                  onPressed: () => setState(() => reply = null),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: body,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: reply == null
                        ? 'Add a comment…'
                        : 'Write a reply…',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Post comment',
                onPressed: busy ? null : send,
                icon: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

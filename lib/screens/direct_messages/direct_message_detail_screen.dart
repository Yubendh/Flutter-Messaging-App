import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_routes.dart';
import '../../models/message.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_input_bar.dart';

class DirectMessageDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;

  const DirectMessageDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
  });

  @override
  State<DirectMessageDetailScreen> createState() => _DirectMessageDetailScreenState();
}

class _DirectMessageDetailScreenState extends State<DirectMessageDetailScreen> {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();
  final ScrollController _scrollController = ScrollController();
  bool _blocked = false;
  String? _myAvatarUrl;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _loadBlockState();
    _loadMyAvatar();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockState() async {
    final blocked = await _firestore.isBlockedEitherDirection(widget.otherUserId);
    if (!mounted) return;
    setState(() => _blocked = blocked);
  }

  void _markUnreadDmMessages(List<Message> messages) {
    final uid = _myUid;
    if (uid == null) return;
    final unread = messages
        .where((m) => !m.isMe && !m.readBy.containsKey(uid))
        .map((m) => m.id)
        .toList();
    if (unread.isNotEmpty) {
      _firestore.markDmMessagesRead(widget.conversationId, unread);
    }
  }

  Future<void> _loadMyAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userData = await _firestore.getUser(uid);
    if (!mounted) return;
    setState(() {
      _myAvatarUrl = userData?['avatarUrl'] as String?;
    });
  }

  Future<void> _sendText(String text) async {
    if (_blocked) return;
    if (text.isEmpty) return;

    try {
      await _firestore.sendDirectTextMessage(widget.conversationId, text);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendImage(File file) async {
    if (_blocked) return;
    try {
      final imageUrl =
          await _storage.uploadDirectMessageImage(widget.conversationId, file);
      await _firestore.sendDirectImageMessage(widget.conversationId, imageUrl);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendFile(File file) async {
    if (_blocked) return;
    try {
      final fileUrl =
          await _storage.uploadDirectMessageFile(widget.conversationId, file);
      final fileName = file.path.split(Platform.pathSeparator).last;
      final sizeBytes = await file.length();
      final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
      await _firestore.sendDirectFileMessage(
        widget.conversationId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSubtitle: '$sizeKb KB',
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send file: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildMessageBubble(Message msg) {
    final isMe = msg.isMe;
    final cs = Theme.of(context).colorScheme;

    if (msg.type == MessageType.image && (msg.imageUrl?.isNotEmpty ?? false)) {
      return InkWell(
        onTap: () => _openExternalUrl(msg.imageUrl!),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            msg.imageUrl!,
            width: 220,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 220,
              height: 160,
              color: isMe
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined,
                  size: 40, color: Colors.blueGrey),
            ),
          ),
        ),
      );
    }

    if (msg.type == MessageType.file && (msg.fileUrl?.isNotEmpty ?? false)) {
      return InkWell(
        onTap: () => _openExternalUrl(msg.fileUrl!),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryDark : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: isMe ? null : Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppTheme.primaryDark.withValues(alpha: 0.6)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description,
                    color: isMe ? Colors.white : AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.fileName ?? 'File',
                      style: TextStyle(
                        color: isMe ? Colors.white : cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg.fileSubtitle ?? 'Tap to open',
                      style: TextStyle(
                        color: isMe ? Colors.white70 : cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primary : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        msg.text ?? '',
        style: TextStyle(
          color: isMe ? Colors.white : cs.onSurface,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleBlock() async {
    if (_blocked) {
      await _firestore.unblockUser(widget.otherUserId);
    } else {
      await _firestore.blockUser(widget.otherUserId);
    }
    if (!mounted) return;
    await _loadBlockState();
  }

  Future<void> _reportUser() async {
    final noteCtrl = TextEditingController();
    String reason = 'harassment';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: reason,
              items: const [
                DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                DropdownMenuItem(value: 'spam', child: Text('Spam')),
                DropdownMenuItem(value: 'impersonation', child: Text('Impersonation')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => reason = value ?? 'harassment',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Optional details',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );

    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    await _firestore.reportUser(
      targetUid: widget.otherUserId,
      reason: reason,
      note: noteCtrl.text.trim(),
    );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Report submitted.'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              backgroundImage: widget.otherUserAvatarUrl != null
                  ? NetworkImage(widget.otherUserAvatarUrl!)
                  : null,
              child: widget.otherUserAvatarUrl == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') _toggleBlock();
              if (value == 'report') _reportUser();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'block',
                child: Text(_blocked ? 'Unblock User' : 'Block User'),
              ),
              const PopupMenuItem(value: 'report', child: Text('Report User')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_blocked)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Direct messaging is disabled because one of you has blocked the other.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _firestore.directMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                _markUnreadDmMessages(messages);
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi to start the conversation.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.isMe;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: isMe
                              ? [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildMessageBubble(msg),
                                      const SizedBox(height: 2),
                                      _DmReadReceipt(message: msg, myUid: _myUid ?? ''),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.profile,
                                    ),
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          AppTheme.primary.withValues(alpha: 0.15),
                                      backgroundImage:
                                          _myAvatarUrl != null && _myAvatarUrl!.isNotEmpty
                                              ? NetworkImage(_myAvatarUrl!)
                                              : null,
                                      child: (_myAvatarUrl == null || _myAvatarUrl!.isEmpty)
                                          ? const Icon(
                                              Icons.person,
                                              size: 16,
                                              color: AppTheme.primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ]
                              : [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        AppTheme.primary.withValues(alpha: 0.12),
                                    backgroundImage: widget.otherUserAvatarUrl != null &&
                                            widget.otherUserAvatarUrl!.isNotEmpty
                                        ? NetworkImage(widget.otherUserAvatarUrl!)
                                        : null,
                                    child: (widget.otherUserAvatarUrl == null ||
                                            widget.otherUserAvatarUrl!.isEmpty)
                                        ? Text(
                                            widget.otherUserName.isNotEmpty
                                                ? widget.otherUserName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(child: _buildMessageBubble(msg)),
                                ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_blocked)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Text(
                  'You cannot send messages while this block is active.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ChatInputBar(
              onSend: _sendText,
              onImagePick: _sendImage,
              onFilePick: _sendFile,
            ),
        ],
      ),
    );
  }
}

class _DmReadReceipt extends StatelessWidget {
  final Message message;
  final String myUid;

  const _DmReadReceipt({required this.message, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final readByOther = message.readBy.keys.any((uid) => uid != myUid);
    return Icon(
      readByOther ? Icons.done_all : Icons.done,
      size: 13,
      color: readByOther ? AppTheme.primary : Colors.grey,
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_routes.dart';
import '../../models/study_group.dart';
import '../../models/message.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/chat_input_bar.dart';

class ChatDetailScreen extends StatefulWidget {
  final StudyGroup group;
  const ChatDetailScreen({super.key, required this.group});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  Message? _editingMessage;
  String? _myAvatarUrl;
  Set<String> _blockedUsers = {};
  StreamSubscription<Set<String>>? _blockSub;

  @override
  void initState() {
    super.initState();
    _loadMyAvatar();
    _blockSub = _firestore.myBlockedUsersStream().listen((blocked) {
      if (mounted) setState(() => _blockedUsers = blocked);
    });
  }

  String get _myRole {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return widget.group.memberRoles[uid] ?? 'member';
  }

  @override
  void dispose() {
    _blockSub?.cancel();
    _scrollCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
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

  void _markUnreadMessages(List<Message> messages) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final unread = messages
        .where((m) => !m.readBy.containsKey(uid))
        .map((m) => m.id)
        .toList();
    if (unread.isNotEmpty) {
      _firestore.markMessagesRead(widget.group.id, unread);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startEdit(Message message) {
    setState(() {
      _editingMessage = message;
      _editCtrl.text = message.text ?? '';
      _editCtrl.selection = TextSelection.collapsed(offset: _editCtrl.text.length);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _editCtrl.clear();
    });
  }

  Future<void> _saveEdit() async {
    final msg = _editingMessage;
    final text = _editCtrl.text.trim();
    if (msg == null || text.isEmpty) return;
    _cancelEdit();
    await _firestore.editMessage(widget.group.id, msg.id, text);
  }

  Future<void> _sendText(String text) async {
    await _firestore.sendTextMessage(widget.group.id, text);
    _scrollToBottom();
  }

  Future<void> _sendImage(File file) async {
    final confirmed = await _showFilePreview(file, isImage: true);
    if (confirmed != true || !mounted) return;
    try {
      final url = await _storage.uploadChatImage(widget.group.id, file);
      await _firestore.sendImageMessage(widget.group.id, url);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send image: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _sendFile(File file) async {
    final confirmed = await _showFilePreview(file, isImage: false);
    if (confirmed != true || !mounted) return;
    try {
      final url = await _storage.uploadChatFile(widget.group.id, file);
      final fileName = file.path.split(Platform.pathSeparator).last;
      final sizeBytes = await file.length();
      final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
      await _firestore.sendFileMessage(
        widget.group.id,
        fileUrl: url,
        fileName: fileName,
        fileSubtitle: '$sizeKb KB',
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool?> _showFilePreview(File file, {required bool isImage}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilePreviewSheet(file: file, isImage: isImage),
    );
  }

  Color get _templateColor {
    if (widget.group.template == 'exam_prep') return const Color(0xFF7C3AED);
    if (widget.group.template == 'assignment') return const Color(0xFFF97316);
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _templateColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.group_outlined, color: _templateColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.group.memberCount} members',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.primary),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.groupDetail,
              arguments: widget.group,
            ),
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.checklist_outlined,
                  label: 'Tasks',
                  color: AppTheme.primary,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.groupTasks,
                    arguments: widget.group,
                  ),
                ),
                _ActionButton(
                  icon: Icons.folder_outlined,
                  label: 'Resources',
                  color: const Color(0xFF059669),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.resourceVault,
                    arguments: widget.group,
                  ),
                ),
                _ActionButton(
                  icon: Icons.timer_outlined,
                  label: 'Pomodoro',
                  color: const Color(0xFFDC2626),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.pomodoro,
                    arguments: widget.group,
                  ),
                ),
                _ActionButton(
                  icon: Icons.people_outline,
                  label: 'Members',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.groupDetail,
                    arguments: widget.group,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _firestore.messagesStream(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                _markUnreadMessages(messages);
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Say hello to your group!',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (!msg.isMe && _blockedUsers.contains(msg.senderId)) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          'Message from a blocked user',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    return MessageBubble(
                      message: msg,
                      groupId: widget.group.id,
                      myRole: _myRole,
                      onEditRequest: _startEdit,
                      myAvatarUrl: _myAvatarUrl,
                      onMyAvatarTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      onSenderTap: (senderUid) {
                        final myUid = FirebaseAuth.instance.currentUser?.uid;
                        if (senderUid == myUid) {
                          Navigator.pushNamed(context, AppRoutes.profile);
                          return;
                        }
                        Navigator.pushNamed(context, AppRoutes.userProfile, arguments: senderUid);
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          if (_editingMessage != null)
            _EditBar(
              controller: _editCtrl,
              onSave: _saveEdit,
              onCancel: _cancelEdit,
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

class _EditBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  const _EditBar({
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Editing message',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onCancel,
                    child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: null,
                        autofocus: true,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Edit message...',
                          hintStyle:
                              TextStyle(color: cs.onSurfaceVariant),
                        ),
                        style:
                            TextStyle(fontSize: 15, color: cs.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.check,
                          color: Colors.white, size: 20),
                      onPressed: onSave,
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
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FilePreviewSheet extends StatefulWidget {
  final File file;
  final bool isImage;

  const _FilePreviewSheet({required this.file, required this.isImage});

  @override
  State<_FilePreviewSheet> createState() => _FilePreviewSheetState();
}

class _FilePreviewSheetState extends State<_FilePreviewSheet> {
  late String _fileName;
  late String _sizeLabel;
  late String _ext;

  @override
  void initState() {
    super.initState();
    _fileName = widget.file.path.split(Platform.pathSeparator).last;
    _ext = _fileName.contains('.') ? _fileName.split('.').last.toUpperCase() : 'FILE';
    _loadSize();
  }

  Future<void> _loadSize() async {
    final bytes = await widget.file.length();
    if (!mounted) return;
    final label = bytes >= 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(bytes / 1024).toStringAsFixed(1)} KB';
    setState(() => _sizeLabel = label);
  }

  IconData _iconForExt() {
    switch (_ext) {
      case 'PDF': return Icons.picture_as_pdf_outlined;
      case 'DOC': case 'DOCX': return Icons.description_outlined;
      case 'XLS': case 'XLSX': return Icons.table_chart_outlined;
      case 'PPT': case 'PPTX': return Icons.slideshow_outlined;
      case 'ZIP': case 'RAR': return Icons.folder_zip_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Send ${widget.isImage ? 'Image' : 'File'}?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 16),
          if (widget.isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(widget.file, height: 200, fit: BoxFit.cover),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_iconForExt(), size: 40, color: AppTheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fileName,
                            style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('$_ext  ·  $_sizeLabel',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

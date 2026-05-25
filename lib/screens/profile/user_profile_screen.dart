import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_routes.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirestoreService _firestore = FirestoreService();

  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _blocked = false;

  bool get _isMe => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _firestore.getVisibleUserProfile(widget.userId);
    final blocked = await _firestore.isBlockedEitherDirection(widget.userId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _blocked = blocked;
      _loading = false;
    });
  }

  Future<void> _startDm() async {
    final nav = Navigator.of(context);
    try {
      final conversationId = await _firestore.getOrCreateDirectConversation(widget.userId);
      if (!mounted) return;
      nav.pushNamed(
        AppRoutes.directMessageDetail,
        arguments: {
          'conversationId': conversationId,
          'otherUserId': widget.userId,
          'otherUserName': _profile?['displayName'] as String? ?? 'Unknown',
          'otherUserAvatarUrl': _profile?['avatarUrl'] as String?,
        },
      );
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

  Future<void> _toggleBlock() async {
    if (_blocked) {
      await _firestore.unblockUser(widget.userId);
    } else {
      await _firestore.blockUser(widget.userId);
    }
    await _load();
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
    await _firestore.reportUser(
      targetUid: widget.userId,
      reason: reason,
      note: noteCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted.'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'User not found.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final displayName = profile['displayName'] as String? ?? 'Unknown';
    final avatarUrl = profile['avatarUrl'] as String?;
    final studentId = profile['studentId'] as String? ?? '';
    final university = profile['university'] as String? ?? '';
    final location = profile['location'] as String? ?? '';
    final major = profile['major'] as String? ?? '';
    final bio = profile['bio'] as String? ?? '';
    final isLookingForGroup = profile['isLookingForGroup'] as bool? ?? false;
    final subjects = List<String>.from(profile['subjects'] as List? ?? const []);
    final limitedProfile = profile['limitedProfile'] as bool? ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        title: Text(
          'User Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 24),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (_blocked)
                              Text(
                                'Blocked',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else if (limitedProfile)
                              Text(
                                'Limited profile visibility',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!limitedProfile) ...[
                    if (studentId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'ID: ${studentId.replaceFirst('ID: ', '')}',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (university.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildIconInfo(Icons.school_outlined, university),
                    ],
                    if (major.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildIconInfo(Icons.menu_book_outlined, major),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildIconInfo(Icons.location_on_outlined, location),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        bio,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                      ),
                    ],
                    if (isLookingForGroup) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.onlineGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.circle, color: AppTheme.onlineGreen, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'Looking for a group',
                              style: TextStyle(
                                color: AppTheme.onlineGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subjects
                            .map(
                              _buildTag,
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (!_isMe) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _blocked ? null : _startDm,
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _toggleBlock,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _blocked ? AppTheme.onlineGreen : AppTheme.error),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_blocked ? 'Unblock' : 'Block'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _reportUser,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Report User'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../models/study_group.dart';
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupDetailScreen extends StatefulWidget {
  final StudyGroup group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late StudyGroup _group;
  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = true;
  String _myRole = 'member';
  bool _regenerating = false;

  bool get _isAnonymous =>
      FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
  bool get _isOwner => _myRole == 'owner' && !_isAnonymous;
  bool get _isAdminOrOwner =>
      (_myRole == 'owner' || _myRole == 'admin') && !_isAnonymous;

  String get _inviteLink => 'campuscollab://join/${_group.inviteCode}';

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadData();
  }

  Future<void> _loadData() async {
    final members = await FirestoreService().getGroupMembers(_group.id);
    final role = await FirestoreService().getUserRole(_group.id);
    if (!mounted) return;
    _sortMemberList(members);
    setState(() {
      _members = members;
      _myRole = role;
      _loadingMembers = false;
    });
  }

  void _sortMemberList(List<Map<String, dynamic>> list) {
    const order = {'owner': 0, 'admin': 1, 'member': 2, 'mentor': 3};
    list.sort((a, b) =>
        (order[a['role'] as String? ?? 'member'] ?? 2)
            .compareTo(order[b['role'] as String? ?? 'member'] ?? 2));
  }

  bool _canActOnMember(Map<String, dynamic> member) {
    if (_isAnonymous) return false;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final targetUid = member['uid'] as String;
    if (targetUid == myUid) return false;
    final targetRole = member['role'] as String? ?? 'member';
    if (targetRole == 'owner') return false;
    if (_myRole == 'owner') return true;
    if (_myRole == 'admin' && targetRole == 'member') return true;
    return false;
  }

  Future<void> _regenerateCode() async {
    setState(() => _regenerating = true);
    final newCode = await FirestoreService().regenerateInviteCode(_group.id);
    if (!mounted) return;
    setState(() {
      _group = _rebuildGroup(inviteCode: newCode);
      _regenerating = false;
    });
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Leave "${_group.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Leave', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final nav = Navigator.of(context);
    await FirestoreService().leaveGroup(_group.id);
    if (!mounted) return;
    nav.pop('left');
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
            'Permanently delete "${_group.name}"?\n\nAll members will lose access. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final nav = Navigator.of(context);
    await FirestoreService().deleteGroup(_group.id);
    if (!mounted) return;
    nav.pop('deleted');
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => _EditGroupSheet(
        group: _group,
        isOwner: _isOwner,
        onSaved: (name, description, courseCode) {
          setState(() {
            _group = _rebuildGroup(
              name: name,
              description: description,
              courseCode: courseCode,
            );
          });
        },
      ),
    );
  }

  void _showMemberActions(Map<String, dynamic> member) {
    final targetUid = member['uid'] as String;
    final targetRole = member['role'] as String? ?? 'member';
    final targetName = member['displayName'] as String? ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppTheme.primary.withValues(alpha: 0.12),
                    backgroundImage: member['avatarUrl'] != null
                        ? NetworkImage(member['avatarUrl'] as String)
                        : null,
                    child: member['avatarUrl'] == null
                        ? Icon(Icons.person,
                            color: AppTheme.primary, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(targetName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface)),
                      Text(
                          targetRole == 'admin'
                              ? 'Moderator'
                              : targetRole[0].toUpperCase() +
                                  targetRole.substring(1),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.divider),

            if (_myRole == 'owner' && targetRole == 'member')
              ListTile(
                leading: const Icon(Icons.shield_outlined,
                    color: AppTheme.primary),
                title: const Text('Promote to Moderator'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setRole(targetUid, targetName, 'admin');
                },
              ),

            if (_myRole == 'owner' && targetRole == 'admin')
              ListTile(
                leading: Icon(Icons.person_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: const Text('Demote to Member'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setRole(targetUid, targetName, 'member');
                },
              ),

            ListTile(
              leading: const Icon(Icons.person_remove_outlined,
                  color: AppTheme.error),
              title: Text('Remove from Group',
                  style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmKick(targetUid, targetName);
              },
            ),

            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.error),
              title: Text('Ban from Group',
                  style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmBan(targetUid, targetName);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _setRole(
      String targetUid, String targetName, String newRole) async {
    await FirestoreService().setMemberRole(_group.id, targetUid, newRole);
    if (!mounted) return;
    setState(() {
      final idx = _members.indexWhere((m) => m['uid'] == targetUid);
      if (idx != -1) {
        _members[idx] = {..._members[idx], 'role': newRole};
        _sortMemberList(_members);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '$targetName is now ${newRole == 'admin' ? 'a Moderator' : 'a Member'}'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _confirmBan(String targetUid, String targetName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ban Member'),
        content: Text('Ban $targetName from "${_group.name}"?\n\nThey will be removed and cannot rejoin.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ban', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await FirestoreService().banUser(_group.id, targetUid);
    if (!mounted) return;
    setState(() => _members.removeWhere((m) => m['uid'] == targetUid));
    messenger.showSnackBar(SnackBar(
      content: Text('$targetName was banned from the group'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _confirmKick(String targetUid, String targetName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $targetName from "${_group.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await FirestoreService().kickMember(_group.id, targetUid);
    if (!mounted) return;
    setState(() => _members.removeWhere((m) => m['uid'] == targetUid));
    messenger.showSnackBar(SnackBar(
      content: Text('$targetName was removed from the group'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  StudyGroup _rebuildGroup({
    String? name,
    String? description,
    String? courseCode,
    String? inviteCode,
  }) {
    return StudyGroup(
      id: _group.id,
      name: name ?? _group.name,
      description: description ?? _group.description,
      courseCode: courseCode ?? _group.courseCode,
      subject: _group.subject,
      template: _group.template,
      memberCount: _group.memberCount,
      maxMembers: _group.maxMembers,
      isOnline: _group.isOnline,
      isPublic: _group.isPublic,
      lastMessage: _group.lastMessage,
      lastMessageTime: _group.lastMessageTime,
      inviteCode: inviteCode ?? _group.inviteCode,
      tags: _group.tags,
      createdBy: _group.createdBy,
      memberRoles: _group.memberRoles,
      memberIds: _group.memberIds,
      messages: _group.messages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final displayCount =
        _loadingMembers ? _group.memberCount : _members.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        title: Text('Group Info',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4)),
        leading: const BackButton(color: AppTheme.primary),
        actions: [
          if (_isAdminOrOwner && !_loadingMembers)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppTheme.primary),
              tooltip: 'Edit Group',
              onPressed: _openEditSheet,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _templateColor(_group.template)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_templateIcon(_group.template),
                            color: _templateColor(_group.template), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_group.name,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                            if (_group.courseCode.isNotEmpty)
                              Text(_group.courseCode,
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                          ],
                        ),
                      ),
                      _templateBadge(_group.template),
                    ],
                  ),
                  if (_group.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_group.description,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                            height: 1.5)),
                  ],
                  if (_group.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _group.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(t,
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('$displayCount / ${_group.maxMembers} members',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('INVITE MEMBERS'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8)
                      ],
                    ),
                    child: QrImageView(
                      data: _inviteLink,
                      version: QrVersions.auto,
                      size: 160,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1565C0)),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1565C0)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_group.inviteCode,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                                color: AppTheme.primary)),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: _group.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Code copied!'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          },
                          child: Icon(Icons.copy,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Share.share(
                            'Join my study group "${_group.name}" on CampusCollab!\nInvite code: ${_group.inviteCode}',
                          ),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share Invite'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_isAdminOrOwner) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed:
                              _regenerating ? null : _regenerateCode,
                          icon: _regenerating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 18),
                          label: const Text('New Code'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('MEMBERS ($displayCount)'),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: _loadingMembers
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children:
                          _members.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        final isMe = m['uid'] == uid;
                        final canAct = _canActOnMember(m);

                        return Column(
                          children: [
                            if (i > 0)
                              const Divider(
                                  height: 1,
                                  indent: 60,
                                  color: AppTheme.divider),
                            ListTile(
                              onTap: () {
                                if (isMe) return;
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.userProfile,
                                  arguments: m['uid'] as String,
                                );
                              },
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primary
                                    .withValues(alpha: 0.12),
                                backgroundImage:
                                    m['avatarUrl'] != null
                                        ? NetworkImage(
                                            m['avatarUrl'] as String)
                                        : null,
                                child: m['avatarUrl'] == null
                                    ? Icon(Icons.person,
                                        color: AppTheme.primary,
                                        size: 22)
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    m['displayName'] ?? 'Unknown',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text('You',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.primary,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(m['major'] ?? '',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _roleBadge(
                                      m['role'] as String? ?? 'member'),
                                  if (canAct) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () =>
                                          _showMemberActions(m),
                                      child: Icon(Icons.more_vert,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          size: 20),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            if (_isAdminOrOwner) ...[
              _sectionLabel('BANNED MEMBERS'),
              _BannedMembersPanel(
                groupId: _group.id,
                onUnban: (uid, name) async {
                  final messenger = ScaffoldMessenger.of(context);
                  await FirestoreService().unbanUser(_group.id, uid);
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text('$name was unbanned'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
              const SizedBox(height: 24),
            ],

            if (_myRole != 'owner')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _leaveGroup,
                  icon: const Icon(Icons.exit_to_app,
                      color: AppTheme.error),
                  label: const Text('Leave Group',
                      style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),

            if (_isOwner) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danger Zone',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.error,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteGroup,
                        icon: const Icon(Icons.delete_forever_outlined,
                            color: AppTheme.error, size: 18),
                        label: const Text('Delete Group',
                            style: TextStyle(color: AppTheme.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2)),
    );
  }

  Color _templateColor(String t) {
    if (t == 'exam_prep') return const Color(0xFF7C3AED);
    if (t == 'assignment') return const Color(0xFFF97316);
    return AppTheme.primary;
  }

  IconData _templateIcon(String t) {
    if (t == 'exam_prep') return Icons.quiz_outlined;
    if (t == 'assignment') return Icons.assignment_outlined;
    return Icons.groups_outlined;
  }

  Widget _templateBadge(String t) {
    final color = _templateColor(t);
    final label = t == 'exam_prep'
        ? 'EXAM PREP'
        : t == 'assignment'
            ? 'ASSIGNMENT'
            : 'GENERAL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _roleBadge(String role) {
    Color color;
    String label;
    switch (role) {
      case 'owner':
        color = const Color(0xFFD4AF37);
        label = 'OWNER';
        break;
      case 'admin':
        color = AppTheme.primary;
        label = 'MOD';
        break;
      case 'mentor':
        color = const Color(0xFF059669);
        label = 'MENTOR';
        break;
      default:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        label = 'MEMBER';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _EditGroupSheet extends StatefulWidget {
  final StudyGroup group;
  final bool isOwner;
  final void Function(String name, String description, String courseCode)
      onSaved;

  const _EditGroupSheet({
    required this.group,
    required this.isOwner,
    required this.onSaved,
  });

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _courseCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
    _descCtrl = TextEditingController(text: widget.group.description);
    _courseCtrl = TextEditingController(text: widget.group.courseCode);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (widget.isOwner && name.isEmpty) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService().updateGroupInfo(
        widget.group.id,
        name: widget.isOwner ? name : null,
        description: _descCtrl.text.trim(),
        courseCode: _courseCtrl.text.trim(),
      );
      widget.onSaved(
        widget.isOwner ? name : widget.group.name,
        _descCtrl.text.trim(),
        _courseCtrl.text.trim(),
      );
      nav.pop();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Edit Group',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 22),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.isOwner) ...[
            _fieldLabel('Group Name'),
            const SizedBox(height: 6),
            _textField(_nameCtrl, 'Group name'),
            const SizedBox(height: 12),
          ],

          _fieldLabel('Description'),
          const SizedBox(height: 6),
          _textField(_descCtrl, 'Description (optional)',
              maxLines: 3, minLines: 2),
          const SizedBox(height: 12),

          _fieldLabel('Course Code'),
          const SizedBox(height: 6),
          _textField(_courseCtrl, 'e.g. ITM390'),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(label,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.4));

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    int minLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      minLines: minLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface),
    );
  }
}

class _BannedMembersPanel extends StatefulWidget {
  final String groupId;
  final Future<void> Function(String uid, String name) onUnban;

  const _BannedMembersPanel({required this.groupId, required this.onUnban});

  @override
  State<_BannedMembersPanel> createState() => _BannedMembersPanelState();
}

class _BannedMembersPanelState extends State<_BannedMembersPanel> {
  List<Map<String, dynamic>> _banned = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final banned = await FirestoreService().getBannedUsers(widget.groupId);
    if (mounted) setState(() { _banned = banned; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_banned.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Text('No banned members.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: _banned.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final name = m['displayName'] as String? ?? 'Unknown';
          final uid = m['uid'] as String;
          return Column(
            children: [
              if (i > 0) const Divider(height: 1, indent: 60, color: AppTheme.divider),
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.error.withValues(alpha: 0.12),
                  backgroundImage: m['avatarUrl'] != null
                      ? NetworkImage(m['avatarUrl'] as String)
                      : null,
                  child: m['avatarUrl'] == null
                      ? const Icon(Icons.person, color: AppTheme.error, size: 20)
                      : null,
                ),
                title: Text(name, style: TextStyle(color: cs.onSurface, fontSize: 14)),
                subtitle: Text('Banned', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                trailing: TextButton(
                  onPressed: () async {
                    await widget.onUnban(uid, name);
                    if (mounted) setState(() => _banned.removeWhere((b) => b['uid'] == uid));
                  },
                  child: const Text('Unban', style: TextStyle(color: AppTheme.primary)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_routes.dart';
import '../../models/chat_folder.dart';
import '../../models/study_group.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/group_chat_card.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String? _activeFolderId;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = v);
    });
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  void _openCreateGroup() async {
    final result = await Navigator.pushNamed(context, AppRoutes.createGroup);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created! It will appear in your chats.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showJoinByCode() {
    final codeCtrl = TextEditingController();
    bool joining = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join by Invite Code',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('Enter the 8-character code shared by a group member.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: AppTheme.primary),
                decoration: InputDecoration(
                  hintText: 'ABC12345',
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 4, fontSize: 18),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: joining
                      ? null
                      : () async {
                          final code = codeCtrl.text.trim();
                          if (code.length != 8) return;
                          setModal(() => joining = true);
                          try {
                            await FirestoreService().joinGroupByCode(code);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Joined group successfully!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setModal(() => joining = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Join Group',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Add a Group',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.group_add_outlined,
                iconBg: Color(0xFFE8F0FE),
                iconColor: Color(0xFF1A73E8),
                label: 'Create New Group',
                subtitle: 'Start a study group for your course',
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateGroup();
                },
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.vpn_key_outlined,
                iconBg: Color(0xFFFFF3E0),
                iconColor: Color(0xFFF57C00),
                label: 'Join by Invite Code',
                subtitle: 'Enter an 8-character code to join',
                onTap: () {
                  Navigator.pop(ctx);
                  _showJoinByCode();
                },
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.explore_outlined,
                iconBg: Color(0xFFE8F5E9),
                iconColor: Color(0xFF2E7D32),
                label: 'Browse Groups',
                subtitle: 'Discover public groups to join',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.discover);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolder() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Folder',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              await _firestore.createFolder(name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(ChatFolder folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Folder',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
            'Delete "${folder.name}"? Groups inside won\'t be removed.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await _firestore.deleteFolder(folder.id);
              if (mounted) setState(() => _activeFolderId = null);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddToFolder(StudyGroup group, List<ChatFolder> folders) {
    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Create a folder first using the + chip.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Create',
            onPressed: _showCreateFolder,
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add "${group.name}" to folder',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 12),
              ...folders.map((folder) {
                final inFolder = folder.groupIds.contains(group.id);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: inFolder
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      inFolder ? Icons.folder : Icons.folder_outlined,
                      color: inFolder
                          ? AppTheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  title: Text(folder.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: inFolder
                              ? AppTheme.primary
                              : Theme.of(context).colorScheme.onSurface)),
                  trailing: inFolder
                      ? Icon(Icons.check_circle,
                          color: AppTheme.primary, size: 20)
                      : null,
                  onTap: () async {
                    if (inFolder) {
                      await _firestore.removeGroupFromFolder(
                          folder.id, group.id);
                    } else {
                      await _firestore.addGroupToFolder(folder.id, group.id);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatFolder>>(
      stream: _firestore.foldersStream(),
      builder: (context, folderSnap) {
        final folders = folderSnap.data ?? [];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0.5,
            leading: _isSearching
                ? IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: _stopSearch,
                  )
                : null,
            title: _isSearching
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16),
                  )
                : Text('Chats',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
            actions: [
              if (_isSearching && _searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }),
                )
              else if (!_isSearching) ...[
                IconButton(
                  icon: Icon(Icons.mark_chat_unread_outlined,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.directMessages),
                ),
                IconButton(
                  icon: Icon(Icons.person_search,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.userSearch),
                ),
                IconButton(
                  icon: Icon(Icons.search,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _startSearch,
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _showCreateMenu,
                ),
              ],
            ],
          ),
          body: Column(
            children: [

              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [

                      _FilterChip(
                        label: 'All',
                        active: _activeFolderId == null,
                        onTap: () =>
                            setState(() => _activeFolderId = null),
                      ),
                      const SizedBox(width: 8),

                      ...folders.map((folder) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onLongPress: () =>
                                  _confirmDeleteFolder(folder),
                              child: _FilterChip(
                                label: folder.name,
                                icon: Icons.folder_outlined,
                                active: _activeFolderId == folder.id,
                                onTap: () => setState(
                                    () => _activeFolderId = folder.id),
                              ),
                            ),
                          )),

                      GestureDetector(
                        onTap: _showCreateFolder,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.divider,
                                style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              SizedBox(width: 4),
                              Text('New Folder',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<List<StudyGroup>>(
                  stream: _firestore.myGroupsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final allGroups = snapshot.data ?? [];

                    final activeFolder = _activeFolderId == null
                        ? null
                        : folders
                            .where((f) => f.id == _activeFolderId)
                            .firstOrNull;
                    final folderFiltered = activeFolder == null
                        ? allGroups
                        : allGroups
                            .where((g) =>
                                activeFolder.groupIds.contains(g.id))
                            .toList();
                    final q = _searchQuery.trim().toLowerCase();
                    final groups = q.isEmpty
                        ? folderFiltered
                        : folderFiltered
                            .where((g) =>
                                g.name.toLowerCase().contains(q) ||
                                g.courseCode.toLowerCase().contains(q))
                            .toList();

                    if (allGroups.isEmpty) {
                      return _EmptyState(
                        onCreateGroup: _openCreateGroup,
                        onJoinByCode: _showJoinByCode,
                        onBrowse: () =>
                            Navigator.pushNamed(context, AppRoutes.discover),
                      );
                    }

                    if (groups.isEmpty) {
                      final isSearchEmpty = q.isNotEmpty;
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSearchEmpty
                                  ? Icons.search_off
                                  : Icons.folder_open,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isSearchEmpty
                                  ? 'No results for "$q"'
                                  : 'No groups in "${activeFolder?.name}"',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isSearchEmpty
                                  ? 'Try a different name or course code.'
                                  : 'Long-press a group chat to add it here.',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const Divider(
                          height: 1, indent: 72, color: AppTheme.divider),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: GroupChatCard(
                            group: group,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ChatDetailScreen(group: group)),
                            ),
                            onLongPress: () =>
                                _showAddToFolder(group, folders),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateMenu,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.add, color: Colors.white),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 2,
            onTap: (i) {
              if (i == 0) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (r) => false);
              }
              if (i == 1) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.discover, (r) => false);
              }
              if (i == 3) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.calendar, (r) => false);
              }
              if (i == 4) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.profile, (r) => false);
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Discover'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Chat'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Calendar'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppTheme.primary : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinByCode;
  final VoidCallback onBrowse;

  const _EmptyState({
    required this.onCreateGroup,
    required this.onJoinByCode,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        children: [

          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_outlined,
                size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text('No study groups yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Create a group, join one with an invite\ncode, or browse public groups.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 32),

          _ActionCard(
            icon: Icons.group_add_outlined,
            iconBg: const Color(0xFFE8F0FE),
            iconColor: const Color(0xFF1A73E8),
            label: 'Create a New Group',
            subtitle: 'Set up a study group for your course',
            onTap: onCreateGroup,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallActionCard(
                  icon: Icons.vpn_key_outlined,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFF57C00),
                  label: 'Join by Code',
                  onTap: onJoinByCode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallActionCard(
                  icon: Icons.explore_outlined,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                  label: 'Browse Groups',
                  onTap: onBrowse,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppTheme.primary : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.2)
                      : iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon,
                    color: isPrimary ? Colors.white : iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isPrimary
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isPrimary
                                ? Colors.white.withValues(alpha: 0.8)
                                : Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios,
                  size: 14,
                  color:
                      isPrimary ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

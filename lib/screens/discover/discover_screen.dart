import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_routes.dart';
import '../../models/study_group.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

const List<String> _filterLabels = [
  'All Groups',
  'General',
  'Exam Prep',
  'Assignment',
];

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _activeFilter = 'All Groups';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<StudyGroup> _allGroups = [];
  Set<String> _myGroupIds = {};
  bool _loading = true;
  final Set<String> _joining = {};
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = v);
    });
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await FirestoreService().getDiscoverGroups();
      final myGroups = await FirestoreService().myGroupsStream().first;
      if (mounted) {
        setState(() {
          _allGroups = groups;
          _myGroupIds = myGroups.map((g) => g.id).toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<StudyGroup> get _filtered {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _allGroups.where((g) {

      if (g.memberIds.contains(uid)) return false;
      final matchesFilter = _activeFilter == 'All Groups' ||
          g.template.toLowerCase() ==
              _activeFilter.toLowerCase().replaceAll(' ', '_');
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          g.name.toLowerCase().contains(q) ||
          g.courseCode.toLowerCase().contains(q) ||
          g.subject.toLowerCase().contains(q) ||
          g.tags.any((t) => t.toLowerCase().contains(q));
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _joinGroup(StudyGroup group) async {
    setState(() => _joining.add(group.id));
    try {
      await FirestoreService().joinGroup(group.id);
      if (mounted) {
        setState(() => _myGroupIds.add(group.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${group.name}"!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining.remove(group.id));
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Text('Enter the 8-character code from your group member.',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 4,
                      fontSize: 18),
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
                                  content: Text('Joined group!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pushNamed(context, AppRoutes.chats);
                            }
                          } catch (e) {
                            setModal(() => joining = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceFirst('Exception: ', '')),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Join Group',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
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
            Image.asset('assets/images/logo.png', width: 28),
            const SizedBox(width: 8),
            Text('CampusCollab',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key_outlined, color: AppTheme.primary),
            tooltip: 'Join by code',
            onPressed: _showJoinByCode,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discover Groups',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by course, topic, or group name...',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filterLabels.map((label) {
                  final active = _activeFilter == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeFilter = label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppTheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadGroups,
                    child: _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text('No groups found',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 15)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _GroupCard(
                              group: _filtered[i],
                              isJoining: _joining.contains(_filtered[i].id),
                              onJoin: () => _joinGroup(_filtered[i]),
                            ),
                          ),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createGroup),
        backgroundColor: AppTheme.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('New Group',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
          if (i == 2) Navigator.pushNamed(context, AppRoutes.chats);
          if (i == 3) Navigator.pushNamed(context, AppRoutes.calendar);
          if (i == 4) Navigator.pushNamed(context, AppRoutes.profile);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
  }
}

class _GroupCard extends StatelessWidget {
  final StudyGroup group;
  final bool isJoining;
  final VoidCallback onJoin;

  const _GroupCard({
    required this.group,
    required this.isJoining,
    required this.onJoin,
  });

  Color get _templateColor {
    if (group.template == 'exam_prep') return const Color(0xFF7C3AED);
    if (group.template == 'assignment') return const Color(0xFFF97316);
    return AppTheme.primary;
  }

  String get _templateLabel {
    if (group.template == 'exam_prep') return 'EXAM PREP';
    if (group.template == 'assignment') return 'ASSIGNMENT';
    return 'GENERAL';
  }

  @override
  Widget build(BuildContext context) {
    final color = _templateColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              if (group.courseCode.isNotEmpty) ...[
                _Tag(label: group.courseCode, color: color),
                const SizedBox(width: 6),
              ],
              _Tag(label: _templateLabel, color: color),
              const Spacer(),
              Text('${group.memberCount}/${group.maxMembers}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),

          Text(group.name,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),

          if (group.subject.isNotEmpty)
            Text(group.subject,
                style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),

          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4)),
          ],

          if (group.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: group.tags
                  .take(4)
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(Icons.people_outline,
                  size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${group.memberCount} members',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              ElevatedButton(
                onPressed: isJoining ? null : onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 9),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
                child: isJoining
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Join',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.4,
          )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_routes.dart';
import '../../models/study_group.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _karma = 0;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    FirestoreService().getKarmaTotal().then((k) {
      if (mounted) setState(() => _karma = k);
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirestoreService().getUser(uid).then((data) {
        if (mounted) {
          setState(() => _displayName = data?['displayName'] as String? ?? '');
        }
      });
    }
  }

  void _openCreateGroup() async {
    final result = await Navigator.pushNamed(context, AppRoutes.createGroup);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created! Check your chats.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _displayName.isNotEmpty
        ? _displayName.split(' ').first
        : 'Student';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            SliverAppBar(
              floating: true,
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

                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 3),
                      Text('$_karma',
                          style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.calendar),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _HeroCard(
                      firstName: firstName,
                      onCreateGroup: _openCreateGroup,
                      onViewSchedule: () =>
                          Navigator.pushNamed(context, AppRoutes.calendar),
                    ),
                    const SizedBox(height: 28),

                    _SectionHeader(
                      title: 'Your Active Groups',
                      subtitle: 'Stay updated with your ongoing collaborations',
                      actionLabel: 'View All',
                      onAction: () =>
                          Navigator.pushNamed(context, AppRoutes.chats),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 165,
                      child: StreamBuilder<List<StudyGroup>>(
                        stream: FirestoreService().myGroupsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final groups = snapshot.data ?? [];
                          if (groups.isEmpty) {
                            return _EmptyGroupsCard(
                                onTap: _openCreateGroup);
                          }
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: groups.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.chat,
                                arguments: groups[i],
                              ),
                              child: _ActiveGroupCard(group: groups[i]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    _SectionHeader(
                      title: 'Discover Groups',
                      subtitle: 'Find groups matching your courses',
                      actionLabel: 'Browse All',
                      onAction: () =>
                          Navigator.pushNamed(context, AppRoutes.discover),
                    ),
                    const SizedBox(height: 12),
                    _QuickActions(onCreateGroup: _openCreateGroup),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateGroup,
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) Navigator.pushNamed(context, AppRoutes.discover);
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

class _HeroCard extends StatelessWidget {
  final String firstName;
  final VoidCallback onCreateGroup;
  final VoidCallback onViewSchedule;

  const _HeroCard({
    required this.firstName,
    required this.onCreateGroup,
    required this.onViewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey, $firstName!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to collaborate today?',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateGroup,
              icon: Icon(Icons.add, size: 18),
              label: Text('Create a Study Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewSchedule,
              icon: Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('View Schedule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
              )),
        ),
      ],
    );
  }
}

class _EmptyGroupsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyGroupsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined,
                size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('No active groups yet',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Tap to create your first group',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ActiveGroupCard extends StatelessWidget {
  final StudyGroup group;

  const _ActiveGroupCard({required this.group});

  Color get _color {
    if (group.template == 'exam_prep') return const Color(0xFF7C3AED);
    if (group.template == 'assignment') return const Color(0xFFF97316);
    final colors = [
      AppTheme.primary,
      const Color(0xFF0E7490),
      const Color(0xFF065F46),
    ];
    return colors[group.id.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.group_outlined, color: _color, size: 20),
              ),
              if (group.isOnline)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.onlineGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Spacer(),
          if (group.courseCode.isNotEmpty) ...[
            Text(group.courseCode,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _color,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
          ],
          Text(
            group.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.people_outline,
                  size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${group.memberCount}',
                  style: TextStyle(
                      fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onCreateGroup;
  const _QuickActions({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            icon: Icons.explore_outlined,
            title: 'Browse Groups',
            subtitle: 'Find public groups',
            color: AppTheme.primary,
            onTap: () => Navigator.pushNamed(context, AppRoutes.discover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickCard(
            icon: Icons.vpn_key_outlined,
            title: 'Join by Code',
            subtitle: 'Use an invite code',
            color: const Color(0xFF059669),
            onTap: () => Navigator.pushNamed(context, AppRoutes.chats),
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/study_group.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_routes.dart';
import '../../services/firestore_service.dart';
import 'package:campuscollab/screens/profile/settings_screen.dart';
import 'package:campuscollab/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentIndex = 4;

  String _name = "";
  String _id = "";
  String _university = "";
  String _location = "";
  String _major = "";
  String _bio = "";
  List<String> _courses = [];
  bool _isLookingForGroup = false;
  String? _avatarUrl;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final data = await FirestoreService().getUser(uid);
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        if (data != null) {
          _name = data['displayName'] ?? '';
          _id = data['studentId'] ?? '';
          _university = data['university'] ?? '';
          _location = data['location'] ?? '';
          _major = data['major'] ?? '';
          _bio = data['bio'] ?? '';
          _courses = List<String>.from(data['subjects'] ?? []);
          _isLookingForGroup = data['isLookingForGroup'] ?? false;
          _avatarUrl = data['avatarUrl'];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  void _openEditProfile() async {
    final result = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initial: ProfileData(
            name: _name,
            studentId: _id,
            university: _university,
            location: _location,
            major: _major,
            bio: _bio,
            courses: _courses,
            isLookingForGroup: _isLookingForGroup,
            avatarUrl: _avatarUrl,
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _name = result.name;
        _id = result.studentId;
        _university = result.university;
        _location = result.location;
        _major = result.major;
        _bio = result.bio;
        _courses = result.courses;
        _isLookingForGroup = result.isLookingForGroup;
        _avatarUrl = result.avatarUrl;
      });
    }
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : (_name.isNotEmpty
                        ? NetworkImage(
                            'https://ui-avatars.com/api/?name=$_name&background=1565C0&color=fff')
                        : null),
                child: _avatarUrl == null && _name.isEmpty
                    ? Icon(Icons.person, color: AppTheme.primary, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildDirectConnectionActions(),
                  const SizedBox(height: 24),
                  _buildGroupsSummaryCard(),
                  const SizedBox(height: 24),
                  _buildCurrentFocusSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  image: _avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _avatarUrl == null
                    ? Icon(Icons.person, size: 56, color: AppTheme.primary)
                    : null,
              ),
              Positioned(
                bottom: -10,
                right: -10,
                child: GestureDetector(
                  onTap: _openEditProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "EDIT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Text(
                _name.isEmpty ? 'Your Name' : _name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school, color: AppTheme.primary, size: 18),
              ),
            ],
          ),

          if (_id.isNotEmpty)
            Text(
              'ID: ${_id.replaceFirst('ID: ', '')}',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 16),

          if (_university.isNotEmpty) _buildIconInfo(Icons.location_on_outlined, _university),
          if (_university.isNotEmpty) const SizedBox(height: 8),
          if (_major.isNotEmpty) _buildIconInfo(Icons.menu_book_outlined, _major),
          if (_major.isNotEmpty) const SizedBox(height: 8),
          if (_location.isNotEmpty) _buildIconInfo(Icons.directions_walk, _location),

          if (_bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _bio,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],

          if (_isLookingForGroup) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.onlineGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: AppTheme.onlineGreen, size: 8),
                  const SizedBox(width: 6),
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

          const SizedBox(height: 20),

          if (_courses.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _courses.map(_buildTag).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGroupsSummaryCard() {
    return StreamBuilder<List<StudyGroup>>(
      stream: FirestoreService().myGroupsStream(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.groups, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${count == 1 ? 'Group' : 'Groups'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'ACTIVE MEMBERSHIPS',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectConnectionActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.userSearch),
            icon: const Icon(Icons.person_search),
            label: const Text('Find Users'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.directMessages),
            icon: const Icon(Icons.mark_chat_unread_outlined),
            label: const Text('Direct Messages'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentFocusSection() {
    return StreamBuilder<List<StudyGroup>>(
      stream: FirestoreService().myGroupsStream(),
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_motion,
                    color: AppTheme.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Current Focus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (groups.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Join a study group to see your focus areas here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              )
            else
              ...groups.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFocusCard(g),
                  )),
          ],
        );
      },
    );
  }

  static const List<Color> _memberColors = [
    Color(0xFFF57C00),
    Color(0xFF1A73E8),
    Color(0xFF2E7D32),
    Color(0xFF9C27B0),
    Color(0xFFE53935),
    Color(0xFF00838F),
  ];

  Widget _buildFocusCard(StudyGroup group) {
    final templateColor = group.template == 'exam_prep'
        ? const Color(0xFF6A1B9A)
        : group.template == 'assignment'
            ? const Color(0xFFE65100)
            : AppTheme.primary;

    final visibleMembers = group.memberCount.clamp(0, 4);
    final overflow = group.memberCount - visibleMembers;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (group.courseCode.isNotEmpty)
                Text(
                  group.courseCode,
                  style: TextStyle(
                    color: templateColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: templateColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    group.template == 'exam_prep'
                        ? 'Exam Prep'
                        : group.template == 'assignment'
                            ? 'Assignment'
                            : 'General',
                    style: TextStyle(
                        color: templateColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              Icon(Icons.star, color: Color(0xFFD4AF37), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            group.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: (visibleMembers * 16.0) + 8,
                height: 24,
                child: Stack(
                  children: List.generate(visibleMembers, (i) => Positioned(
                    left: i * 16.0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            _memberColors[i % _memberColors.length],
                      ),
                    ),
                  )),
                ),
              ),
              if (overflow > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) {
        if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
        if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.discover);
        if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.chats);
        if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.calendar);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:campuscollab/theme/app_theme.dart';
import 'package:campuscollab/constants/app_routes.dart';
import 'package:campuscollab/providers/auth_provider.dart';
import 'package:campuscollab/providers/theme_provider.dart';
import 'package:campuscollab/services/firestore_service.dart';
import 'package:campuscollab/services/otp_service.dart';
import 'package:campuscollab/services/email_service.dart';
import '../auth/verify_otp_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _isSendingOtp = false;

  String _name = '';
  String _major = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _handleChangePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.isAnonymous) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text('Not available',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
          content: Text(
            'Guest accounts cannot change a password. Create a full account first.',
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
      return;
    }

    final providers =
        user.providerData.map((p) => p.providerId).toSet();
    if (providers.contains('google.com') && !providers.contains('password')) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text('Google account',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
          content: Text(
            'You signed in with Google. To change your password, manage it through your Google account settings.',
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
      return;
    }

    final email = user.email ?? '';
    if (email.isEmpty) return;

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSendingOtp = true);
    try {
      final data = await FirestoreService().getUser(user.uid);
      final name = data?['displayName'] as String? ?? '';
      final code = await OtpService()
          .generateAndStore(user.uid, OtpPurpose.changePassword);
      await EmailService()
          .sendPasswordResetCode(toEmail: email, name: name, code: code);
      if (!mounted) return;
      nav.push(MaterialPageRoute(
        builder: (_) => VerifyOtpScreen(
          initialUid: user.uid,
          initialEmail: email,
          initialName: name,
          purpose: OtpPurpose.changePassword,
        ),
      ));
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Could not send verification code. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final data = await FirestoreService().getUser(uid);
      if (!mounted || data == null) return;
      setState(() {
        _name = data['displayName'] ?? '';
        _major = data['major'] ?? '';
        _avatarUrl = data['avatarUrl'];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            _buildUserHeader(),
            const SizedBox(height: 32),

            _buildSectionHeader("PREFERENCES"),
            _buildSettingsContainer([
              _buildSwitchTile(
                icon: Icons.notifications_none_outlined,
                title: "Push Notifications",
                subtitle: "Instant alerts for group updates",
                value: _pushNotifications,
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader("SECURITY & TRUST"),
            _buildSettingsContainer([
              _buildActionTile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy & Messaging",
                onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader("APPEARANCE"),
            _buildThemeSelector(),
            const SizedBox(height: 24),

            _buildSectionHeader("ACCOUNT"),
            _buildSettingsContainer([
              _buildActionTile(
                icon: Icons.vpn_key_outlined,
                title: _isSendingOtp ? "Sending code…" : "Change Password",
                onTap: _isSendingOtp ? () {} : _handleChangePassword,
              ),
            ]),
            const SizedBox(height: 16),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildUserHeader() {
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              image: _avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _avatarUrl == null
                ? Icon(Icons.person, color: AppTheme.primary, size: 36)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isEmpty ? 'Your Name' : _name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_major.isNotEmpty)
                  Text(
                    _major,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildThemeSelector() {
    final selectedTheme = context.watch<ThemeProvider>().selectedThemeLabel;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          _buildThemeOption(Icons.wb_sunny_outlined, "Light", selectedTheme),
          _buildThemeOption(Icons.nightlight_outlined, "Dark", selectedTheme),
          _buildThemeOption(
              Icons.settings_overscan_outlined, "System", selectedTheme),
        ],
      ),
    );
  }

  Widget _buildThemeOption(IconData icon, String label, String selectedTheme) {
    final bool isSelected = selectedTheme == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          final provider = context.read<ThemeProvider>();
          switch (label) {
            case 'Light':
              provider.setThemeMode(ThemeMode.light);
              break;
            case 'Dark':
              provider.setThemeMode(ThemeMode.dark);
              break;
            default:
              provider.setThemeMode(ThemeMode.system);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppTheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.logout, color: AppTheme.error, size: 20),
        ),
        title: Text(
          "Log Out",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        onTap: () async {
          final nav = Navigator.of(context);
          await context.read<AppAuthProvider>().logout();
          nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 4,
      onTap: (i) {
        if (i == 0) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
        if (i == 1) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.discover, (r) => false);
        if (i == 2) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.chats, (r) => false);
        if (i == 3) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.calendar, (r) => false);
        if (i == 4) Navigator.pop(context);
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

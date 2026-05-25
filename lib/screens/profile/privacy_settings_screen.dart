import 'package:flutter/material.dart';
import '../../models/user_privacy.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _loading = true;
  UserPrivacy? _privacy;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final privacy = await _firestore.getMyPrivacy();
    final blocked = <Map<String, dynamic>>[];
    for (final uid in privacy.blockedUsers) {
      final user = await _firestore.getUser(uid);
      blocked.add({
        'uid': uid,
        'displayName': user?['displayName'] ?? 'Unknown',
        'avatarUrl': user?['avatarUrl'],
      });
    }

    if (!mounted) return;
    setState(() {
      _privacy = privacy;
      _blockedUsers = blocked;
      _loading = false;
    });
  }

  Future<void> _updateDmAccess(String value) async {
    await _firestore.updateMyPrivacy(dmAccess: value);
    if (!mounted) return;
    setState(() {
      _privacy = UserPrivacy(
        uid: _privacy!.uid,
        dmAccess: value,
        profileVisibility: _privacy!.profileVisibility,
        blockedUsers: _privacy!.blockedUsers,
      );
    });
  }

  Future<void> _updateProfileVisibility(String value) async {
    await _firestore.updateMyPrivacy(profileVisibility: value);
    if (!mounted) return;
    setState(() {
      _privacy = UserPrivacy(
        uid: _privacy!.uid,
        dmAccess: _privacy!.dmAccess,
        profileVisibility: value,
        blockedUsers: _privacy!.blockedUsers,
      );
    });
  }

  Future<void> _unblockUser(String uid) async {
    await _firestore.unblockUser(uid);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        title: Text(
          'Privacy Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct messages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'all',
                          groupValue: _privacy!.dmAccess,
                          onChanged: (value) => _updateDmAccess(value!),
                          title: const Text('Allow DMs from anyone'),
                        ),
                        RadioListTile<String>(
                          value: 'none',
                          groupValue: _privacy!.dmAccess,
                          onChanged: (value) => _updateDmAccess(value!),
                          title: const Text('Disable direct messages'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Profile visibility',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'public',
                          groupValue: _privacy!.profileVisibility,
                          onChanged: (value) => _updateProfileVisibility(value!),
                          title: const Text('Public profile'),
                        ),
                        RadioListTile<String>(
                          value: 'shared_group',
                          groupValue: _privacy!.profileVisibility,
                          onChanged: (value) => _updateProfileVisibility(value!),
                          title: const Text('Only shared-group users see full profile'),
                        ),
                        RadioListTile<String>(
                          value: 'private',
                          groupValue: _privacy!.profileVisibility,
                          onChanged: (value) => _updateProfileVisibility(value!),
                          title: const Text('Private (minimal profile only)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Blocked users',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_blockedUsers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No blocked users.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _blockedUsers
                            .map(
                              (user) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                  backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl'] as String) : null,
                                  child: user['avatarUrl'] == null
                                      ? Text(
                                          (user['displayName'] as String).isNotEmpty
                                              ? (user['displayName'] as String)[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                                        )
                                      : null,
                                ),
                                title: Text(user['displayName'] as String),
                                trailing: TextButton(
                                  onPressed: () => _unblockUser(user['uid'] as String),
                                  child: const Text('Unblock'),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'constants/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/discover/discover_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chats/chats_screen.dart';
import 'screens/chats/chat_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/privacy_settings_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/profile/user_search_screen.dart';
import 'screens/groups/create_group_screen.dart';
import 'screens/groups/group_detail_screen.dart';
import 'screens/tasks/group_tasks_screen.dart';
import 'screens/resources/resource_vault_screen.dart';
import 'screens/study/pomodoro_screen.dart';
import 'screens/direct_messages/direct_messages_screen.dart';
import 'screens/direct_messages/direct_message_detail_screen.dart';
import 'models/study_group.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusCollabApp());
}

class CampusCollabApp extends StatelessWidget {
  const CampusCollabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'CampusCollab',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          home: const AuthGate(),
          routes: {
            AppRoutes.login:       (_) => const LoginScreen(),
            AppRoutes.register:    (_) => const RegisterScreen(),
            AppRoutes.discover:    (_) => const DiscoverScreen(),
            AppRoutes.calendar:    (_) => const CalendarScreen(),
            AppRoutes.home:        (_) => const HomeScreen(),
            AppRoutes.chats:       (_) => const ChatsScreen(),
            AppRoutes.profile:     (_) => const ProfileScreen(),
            AppRoutes.createGroup: (_) => const CreateGroupScreen(),
            AppRoutes.directMessages: (_) => const DirectMessagesScreen(),
            AppRoutes.privacySettings: (_) => const PrivacySettingsScreen(),
            AppRoutes.userSearch: (_) => const UserSearchScreen(),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AppRoutes.chat:
                final group = settings.arguments as StudyGroup;
                return MaterialPageRoute(builder: (_) => ChatDetailScreen(group: group));
              case AppRoutes.groupDetail:
                final group = settings.arguments as StudyGroup;
                return MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group));
              case AppRoutes.groupTasks:
                final group = settings.arguments as StudyGroup;
                return MaterialPageRoute(
                    builder: (_) => GroupTasksScreen(groupId: group.id, groupName: group.name));
              case AppRoutes.resourceVault:
                final group = settings.arguments as StudyGroup;
                return MaterialPageRoute(
                    builder: (_) => ResourceVaultScreen(groupId: group.id, groupName: group.name));
              case AppRoutes.pomodoro:
                final group = settings.arguments as StudyGroup;
                return MaterialPageRoute(
                    builder: (_) => PomodoroScreen(groupId: group.id, groupName: group.name));
              case AppRoutes.userProfile:
                final uid = settings.arguments as String;
                return MaterialPageRoute(builder: (_) => UserProfileScreen(userId: uid));
              case AppRoutes.directMessageDetail:
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => DirectMessageDetailScreen(
                    conversationId: args['conversationId'] as String,
                    otherUserId: args['otherUserId'] as String,
                    otherUserName: args['otherUserName'] as String? ?? 'Unknown',
                    otherUserAvatarUrl: args['otherUserAvatarUrl'] as String?,
                  ),
                );
            }
            return null;
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants/app_routes.dart';
import '../../models/direct_message_conversation.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class DirectMessagesScreen extends StatelessWidget {
  const DirectMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        title: Text(
          'Direct Messages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: StreamBuilder<List<DirectMessageConversation>>(
        stream: FirestoreService().myDirectConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No direct messages yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search for a user and start a private chat.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72, color: AppTheme.divider),
            itemBuilder: (context, i) {
              final convo = conversations[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  backgroundImage: convo.otherUserAvatarUrl != null
                      ? NetworkImage(convo.otherUserAvatarUrl!)
                      : null,
                  child: convo.otherUserAvatarUrl == null
                      ? Text(
                          convo.otherUserName.isNotEmpty ? convo.otherUserName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                title: Text(
                  convo.otherUserName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  convo.lastMessage.isEmpty ? 'Start a conversation' : convo.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.directMessageDetail,
                  arguments: {
                    'conversationId': convo.id,
                    'otherUserId': convo.otherUserId,
                    'otherUserName': convo.otherUserName,
                    'otherUserAvatarUrl': convo.otherUserAvatarUrl,
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.userSearch),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.person_search, color: Colors.white),
      ),
    );
  }
}

class ChatFolder {
  final String id;
  final String name;
  final List<String> groupIds;

  const ChatFolder({
    required this.id,
    required this.name,
    this.groupIds = const [],
  });

  factory ChatFolder.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatFolder(
      id: id,
      name: data['name'] as String? ?? '',
      groupIds: List<String>.from(data['groupIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'groupIds': groupIds,
      };
}

class User {
  final String id;
  final String displayName;
  final String major;
  final List<String> subjects;
  final String? avatarUrl;
  final bool isLookingForGroup;

  const User({
    required this.id,
    required this.displayName,
    required this.major,
    required this.subjects,
    this.avatarUrl,
    this.isLookingForGroup = false,
  });
}

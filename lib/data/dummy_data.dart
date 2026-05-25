import '../models/message.dart';
import '../models/study_group.dart';
import '../models/discover_group.dart';
import '../models/suggested_group.dart';
import '../models/app_notification.dart';
import '../models/deadline.dart';

final List<StudyGroup> dummyGroups = [
  StudyGroup(
    id: 'g1',
    name: 'Study Group: Advanced Physics',
    memberCount: 12,
    isOnline: true,
    lastMessage: 'Person 2: Physics Study Guide.docx',
    lastMessageTime: '10:42 AM',
    messages: _physicsMessages,
  ),
  StudyGroup(
    id: 'g2',
    name: 'Calculus II — Exam Prep',
    memberCount: 8,
    isOnline: true,
    lastMessage: 'Person 3: Does anyone have the practice set?',
    lastMessageTime: '9:15 AM',
    messages: _calculusMessages,
  ),
  StudyGroup(
    id: 'g3',
    name: 'CS301 — Algorithms Help',
    memberCount: 5,
    isOnline: false,
    lastMessage: "You: I'll share my notes tonight",
    lastMessageTime: 'Yesterday',
    messages: _algorithmMessages,
  ),
  StudyGroup(
    id: 'g4',
    name: 'ITM 390 — Mobile Dev',
    memberCount: 3,
    isOnline: true,
    lastMessage: 'Person 5: Flutter setup done!',
    lastMessageTime: 'Yesterday',
    messages: _mobileMessages,
  ),
  StudyGroup(
    id: 'g5',
    name: 'General Study — Library B2',
    memberCount: 20,
    isOnline: false,
    lastMessage: 'Person 6: See everyone at 3 PM',
    lastMessageTime: 'Mon',
    messages: _generalMessages,
  ),
];

final List<Message> _physicsMessages = [
  Message(
    id: 'm1',
    senderId: 'u1',
    senderName: 'Person 1',
    type: MessageType.text,
    text: 'Has anyone started the problem set due Thursday? I\'m stuck on the quantum mechanics part.',
    timestamp: DateTime(2026, 3, 23, 9, 30),
    isMe: false,
  ),
  Message(
    id: 'm2',
    senderId: 'me',
    senderName: 'Me',
    type: MessageType.text,
    text: 'I just finished the first two questions. Here are my notes for the second one. Hope it helps!',
    timestamp: DateTime(2026, 3, 23, 9, 45),
    isMe: true,
  ),
  Message(
    id: 'm3',
    senderId: 'me',
    senderName: 'Me',
    type: MessageType.image,
    imageUrl: 'assets/images/notes_placeholder.png',
    timestamp: DateTime(2026, 3, 23, 9, 46),
    isMe: true,
  ),
  Message(
    id: 'm4',
    senderId: 'u2',
    senderName: 'Person 2',
    type: MessageType.text,
    text: 'Thanks! I\'m putting everything into our shared study guide doc here so we can all collaborate:',
    timestamp: DateTime(2026, 3, 23, 10, 42),
    isMe: false,
  ),
  Message(
    id: 'm5',
    senderId: 'u2',
    senderName: 'Person 2',
    type: MessageType.file,
    fileName: 'Physics Study Guide.docx',
    fileSubtitle: 'Shared via Google Drive',
    timestamp: DateTime(2026, 3, 23, 10, 42),
    isMe: false,
  ),
];

final List<Message> _calculusMessages = [
  Message(
    id: 'c1',
    senderId: 'u3',
    senderName: 'Person 3',
    type: MessageType.text,
    text: 'Does anyone have the practice set from last week?',
    timestamp: DateTime(2026, 3, 23, 9, 10),
    isMe: false,
  ),
  Message(
    id: 'c2',
    senderId: 'me',
    senderName: 'Me',
    type: MessageType.text,
    text: 'I think I saved it — let me check my Drive.',
    timestamp: DateTime(2026, 3, 23, 9, 15),
    isMe: true,
  ),
];

final List<Message> _algorithmMessages = [
  Message(
    id: 'a1',
    senderId: 'u4',
    senderName: 'Person 4',
    type: MessageType.text,
    text: 'Who\'s going to the TA session tomorrow?',
    timestamp: DateTime(2026, 3, 22, 18, 0),
    isMe: false,
  ),
  Message(
    id: 'a2',
    senderId: 'me',
    senderName: 'Me',
    type: MessageType.text,
    text: 'I\'ll share my notes tonight.',
    timestamp: DateTime(2026, 3, 22, 18, 30),
    isMe: true,
  ),
];

final List<Message> _mobileMessages = [
  Message(
    id: 'mob1',
    senderId: 'u5',
    senderName: 'Person 5',
    type: MessageType.text,
    text: 'Flutter setup done! Ready to start on the UI.',
    timestamp: DateTime(2026, 3, 22, 14, 0),
    isMe: false,
  ),
];

final List<Message> _generalMessages = [
  Message(
    id: 'gen1',
    senderId: 'u6',
    senderName: 'Person 6',
    type: MessageType.text,
    text: 'See everyone at 3 PM at the library B2!',
    timestamp: DateTime(2026, 3, 21, 11, 0),
    isMe: false,
  ),
];

final List<DiscoverGroup> dummyDiscoverGroups = [
  const DiscoverGroup(
    id: 'dg1',
    courseCode: 'CS161',
    subject: 'COMPUTER SCIENCE',
    colorValue: 0xFF1565C0,
    accentColorValue: 0xFF1976D2,
    name: 'Machine Learning',
    description:
        'Deep diving into sorting algorithms and Big O notation for the upcoming midterms. All skill levels welcome.',
    memberCount: 42,
    filterTags: ['All Groups', 'Course Code', 'Subject'],
  ),
  const DiscoverGroup(
    id: 'dg2',
    courseCode: 'BIO101',
    subject: 'BOTANY',
    colorValue: 0xFF065F46,
    accentColorValue: 0xFFF59E0B,
    name: 'Computer Vision',
    description:
        'Focusing on DNA-replication and transcription pathways. Weekly lab report reviews on Thursdays.',
    memberCount: 8,
    filterTags: ['All Groups', 'Course Code', 'Subject'],
  ),
  const DiscoverGroup(
    id: 'dg3',
    courseCode: 'ECON201',
    subject: 'ECONOMICS',
    colorValue: 0xFF92400E,
    accentColorValue: 0xFFDC2626,
    name: 'Mobile App',
    description:
        'Discussing global market trends and policy implications. General discussion and homework support.',
    memberCount: 24,
    filterTags: ['All Groups', 'Course Code', 'Homework Help'],
  ),
  const DiscoverGroup(
    id: 'dg4',
    courseCode: 'MTH301',
    subject: 'MATHEMATICS',
    colorValue: 0xFF6D28D9,
    accentColorValue: 0xFF6D28D9,
    name: 'Calculus III Study Hub',
    description:
        'Multi-variable calculus, partial derivatives and surface integrals. Exam prep every Sunday.',
    memberCount: 31,
    filterTags: ['All Groups', 'Subject', 'Exam Prep'],
  ),
  const DiscoverGroup(
    id: 'dg5',
    courseCode: 'ENG102',
    subject: 'ENGLISH',
    colorValue: 0xFF0E7490,
    accentColorValue: 0xFF0E7490,
    name: 'Essay Writing Workshop',
    description:
        'Peer review sessions and writing tips for academic essays. Open to all majors.',
    memberCount: 15,
    filterTags: ['All Groups', 'Subject', 'Homework Help', 'General'],
  ),
];

final List<SuggestedGroup> dummySuggestedGroups = [
  const SuggestedGroup(
    id: 'sg1',
    subject: 'MATHEMATICS',
    colorValue: 0xFF1565C0,
    iconName: 'functions',
    name: 'Calculus III Study Hub',
    description: 'Multi-variable calculus...',
    badges: ['14+ SIZE', 'POSTS'],
  ),
  const SuggestedGroup(
    id: 'sg2',
    subject: 'RESEARCH',
    colorValue: 0xFF6D28D9,
    iconName: 'psychology',
    name: 'AI Research Lab',
    description: 'Collaborative LLM...',
    badges: ['INVITE ONLY'],
  ),
  const SuggestedGroup(
    id: 'sg3',
    subject: 'SCIENCE',
    colorValue: 0xFF0E7490,
    iconName: 'nightlight',
    name: 'Astrophysics Circle',
    description: 'Analyzing spectral...',
    badges: ['5 ACTIVE MEMBERS'],
  ),
];

final List<AppNotification> dummyNotifications = [
  AppNotification(
    id: 'n1',
    type: NotificationType.mention,
    title: 'Marcus Thorne mentioned you',
    body: 'in UX Design Collective',
    timestamp: DateTime(2026, 3, 31, 8, 0),
    isRead: false,
  ),
  AppNotification(
    id: 'n2',
    type: NotificationType.mention,
    title: 'Marcus Thorne mentioned you',
    body: 'in UX Design Collective',
    timestamp: DateTime(2026, 3, 31, 8, 5),
  ),
  AppNotification(
    id: 'n3',
    type: NotificationType.mention,
    title: 'Marcus Thorne mentioned you',
    body: 'in UX Design Collective',
    timestamp: DateTime(2026, 3, 31, 8, 10),
  ),
  AppNotification(
    id: 'n4',
    type: NotificationType.mention,
    title: 'Marcus Thorne mentioned you',
    body: 'in UX Design Collective',
    timestamp: DateTime(2026, 3, 31, 8, 15),
    isRead: false,
  ),
  AppNotification(
    id: 'n5',
    type: NotificationType.mention,
    title: 'Marcus Thorne mentioned you',
    body: 'in UX Design Collective',
    timestamp: DateTime(2026, 3, 31, 8, 20),
  ),
  AppNotification(
    id: 'n6',
    type: NotificationType.badge,
    title: 'Academic Karma milestone reached!',
    body: 'You\'ve earned the "Deep Researcher" badge.',
    timestamp: DateTime(2026, 3, 30, 14, 0),
    isRead: false,
  ),
  AppNotification(
    id: 'n7',
    type: NotificationType.message,
    title: 'New Message',
    body: 'in Micro-Biology Study Group',
    timestamp: DateTime(2026, 3, 29, 10, 0),
  ),
];

final List<Deadline> dummyDeadlines = [
  Deadline(
    id: 'dl1',
    date: DateTime(2026, 4, 3),
    title: 'Problem Set 4 Due',
    groupId: 'dg1',
    groupName: 'Machine Learning',
    colorValue: 0xFF1565C0,
  ),
  Deadline(
    id: 'dl2',
    date: DateTime(2026, 4, 7),
    title: 'Lab Report Submission',
    groupId: 'dg2',
    groupName: 'Computer Vision',
    colorValue: 0xFF065F46,
  ),
  Deadline(
    id: 'dl3',
    date: DateTime(2026, 4, 10),
    title: 'Midterm Exam',
    groupId: 'dg4',
    groupName: 'Calculus III Study Hub',
    colorValue: 0xFF6D28D9,
  ),
  Deadline(
    id: 'dl4',
    date: DateTime(2026, 4, 14),
    title: 'Group Presentation',
    groupId: 'ux1',
    groupName: 'UX Design Collective',
    colorValue: 0xFFF97316,
  ),
  Deadline(
    id: 'dl5',
    date: DateTime(2026, 4, 21),
    title: 'Essay Draft Due',
    groupId: 'dg5',
    groupName: 'Essay Writing Workshop',
    colorValue: 0xFF0E7490,
  ),
  Deadline(
    id: 'dl6',
    date: DateTime(2026, 4, 28),
    title: 'Final Project Submission',
    groupId: 'dg3',
    groupName: 'Mobile App Group',
    colorValue: 0xFFDC2626,
  ),
];

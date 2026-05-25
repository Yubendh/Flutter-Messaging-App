import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_routes.dart';
import '../../models/study_group.dart';
import '../../models/study_session.dart';
import '../../models/task.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: const BackButton(color: AppTheme.primary),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 26),
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
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.person, color: AppTheme.primary, size: 20),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NotificationsTab(),
          _CalendarTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('No notifications yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text('Study session reminders will appear here',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab();

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  final FirestoreService _firestore = FirestoreService();
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
        _selectedDay = null;
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
        _selectedDay = null;
      });

  void _showAddSession(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSessionSheet(
        initialDate: _selectedDay ?? DateTime.now(),
        onAdded: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudySession>>(
      stream: _firestore.mySessionsStream(),
      builder: (context, sessionSnap) {
        return StreamBuilder<List<Task>>(
          stream: _firestore.myTasksStream(),
          builder: (context, taskSnap) {
            final sessions = sessionSnap.data ?? [];
            final allTasks = taskSnap.data ?? [];

            final sessionDayColors = _buildSessionDayColors(sessions);
            final sessionDays = sessionDayColors.keys.toSet();
            final taskDeadlineDays = _buildTaskDeadlineDays(allTasks);

            final selectedSessions = _selectedDay == null
                ? <StudySession>[]
                : sessions
                    .where((s) =>
                        s.startTime.year == _selectedDay!.year &&
                        s.startTime.month == _selectedDay!.month &&
                        s.startTime.day == _selectedDay!.day)
                    .toList();

            final selectedTasks = _selectedDay == null
                ? <Task>[]
                : allTasks
                    .where((t) =>
                        t.dueDate != null &&
                        t.dueDate!.year == _selectedDay!.year &&
                        t.dueDate!.month == _selectedDay!.month &&
                        t.dueDate!.day == _selectedDay!.day)
                    .toList();

            final now = DateTime.now();
            final upcomingSessions = sessions
                .where((s) => s.startTime.isAfter(now))
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

            final upcomingTasks = allTasks
                .where((t) =>
                    t.dueDate != null &&
                    !t.isCompleted &&
                    t.dueDate!.isAfter(now.subtract(const Duration(days: 1))))
                .toList();

            final hasSelectedItems =
                selectedSessions.isNotEmpty || selectedTasks.isNotEmpty;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _MonthHeader(
                              month: _focusedMonth,
                              onPrev: _prevMonth,
                              onNext: _nextMonth),
                          const SizedBox(height: 12),
                          _WeekdayRow(),
                          const SizedBox(height: 4),
                          _DayGrid(
                            focusedMonth: _focusedMonth,
                            selectedDay: _selectedDay,
                            sessionDays: sessionDays,
                            sessionColors: sessionDayColors,
                            taskDeadlineDays: taskDeadlineDays,
                            onDayTap: (day) =>
                                setState(() => _selectedDay = day),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text('Sessions',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                              const SizedBox(width: 14),
                              Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.warning,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text('Task deadlines',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (hasSelectedItems) ...[
                      Text(
                        _formatDate(_selectedDay!),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...selectedSessions
                          .map((s) => _SessionTile(session: s)),
                      ...selectedTasks
                          .map((t) => _CalendarTaskTile(task: t)),
                      const SizedBox(height: 16),
                    ],

                    Text('Upcoming Sessions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                    const SizedBox(height: 12),

                    if (sessionSnap.connectionState ==
                        ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (upcomingSessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'No upcoming sessions.\nSchedule one with the + button!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...upcomingSessions
                          .map((s) => _SessionTile(session: s)),

                    const SizedBox(height: 24),

                    Text('Upcoming Task Deadlines',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                    const SizedBox(height: 12),

                    if (taskSnap.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (upcomingTasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'No tasks with upcoming deadlines.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...upcomingTasks.map((t) => _CalendarTaskTile(task: t)),
                  ],
                ),

                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () => _showAddSession(context),
                    backgroundColor: AppTheme.primary,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<int, Color> _buildSessionDayColors(List<StudySession> sessions) {
    final map = <int, Color>{};
    for (final s in sessions) {
      if (s.startTime.year == _focusedMonth.year &&
          s.startTime.month == _focusedMonth.month) {
        map[s.startTime.day] = AppTheme.primary;
      }
    }
    return map;
  }

  Set<int> _buildTaskDeadlineDays(List<Task> tasks) {
    final set = <int>{};
    for (final t in tasks) {
      if (t.dueDate != null &&
          t.dueDate!.year == _focusedMonth.year &&
          t.dueDate!.month == _focusedMonth.month &&
          !t.isCompleted) {
        set.add(t.dueDate!.day);
      }
    }
    return set;
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _AddSessionSheet extends StatefulWidget {
  final DateTime initialDate;
  final VoidCallback onAdded;

  const _AddSessionSheet({required this.initialDate, required this.onAdded});

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  final _firestore = FirestoreService();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _saving = false;
  StudyGroup? _selectedGroup;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate;
    final now = DateTime.now();
    _startTime = DateTime(base.year, base.month, base.day, now.hour, 0);
    _endTime = DateTime(base.year, base.month, base.day, now.hour + 1, 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime! : _endTime!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked != null && mounted) {
      setState(() {
        final updated = DateTime(
          initial.year, initial.month, initial.day,
          picked.hour, picked.minute,
        );
        if (isStart) {
          _startTime = updated;
        } else {
          _endTime = updated;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_selectedGroup == null) return;
    if (_startTime == null || _endTime == null) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final session = StudySession(
        id: '',
        title: _titleCtrl.text.trim(),
        groupId: _selectedGroup!.id,
        groupName: _selectedGroup!.name,
        startTime: _startTime!,
        endTime: _endTime!,
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        createdBy: uid,
      );
      await _firestore.addSession(_selectedGroup!.id, session);
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating),
        );
      }
      setState(() => _saving = false);
    }
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Session',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),

          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'Session title',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<StudyGroup>>(
            stream: _firestore.myGroupsStream(),
            builder: (context, snap) {
              final groups = snap.data ?? [];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StudyGroup>(
                    value: _selectedGroup,
                    isExpanded: true,
                    hint: Text('Select a group',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    items: groups
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (g) => setState(() => _selectedGroup = g),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: _TimePill(label: 'Start', time: _fmtTime(_startTime!)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: _TimePill(label: 'End', time: _fmtTime(_endTime!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              hintText: 'Location (optional)',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              prefixIcon: Icon(Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Schedule',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String label;
  final String time;
  const _TimePill({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(time,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final StudySession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    String fmtTime(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  months[session.startTime.month - 1].toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary),
                ),
                Text(
                  '${session.startTime.day}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 13, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(session.groupName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${fmtTime(session.startTime)} – ${fmtTime(session.endTime)}',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                if (session.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(session.location!,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader(
      {required this.month, required this.onPrev, required this.onNext});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Icon(Icons.chevron_left, color: AppTheme.primary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text('${_months[month.month - 1]} ${month.year}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            )),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: AppTheme.primary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  static const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _days
          .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                ),
              ))
          .toList(),
    );
  }
}

class _DayGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Set<int> sessionDays;
  final Map<int, Color> sessionColors;
  final Set<int> taskDeadlineDays;
  final void Function(DateTime) onDayTap;

  const _DayGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.sessionDays,
    required this.sessionColors,
    required this.taskDeadlineDays,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth =
        DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final today = DateTime.now();
    final cells = <Widget>[];

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = selectedDay != null &&
          date.year == selectedDay!.year &&
          date.month == selectedDay!.month &&
          date.day == selectedDay!.day;
      final hasSession = sessionDays.contains(day);
      final hasTask = taskDeadlineDays.contains(day);

      cells.add(
        GestureDetector(
          onTap: () => onDayTap(date),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : isToday
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppTheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                      )),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSession)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: AppTheme.primary, shape: BoxShape.circle),
                      ),
                    if (hasSession && hasTask) const SizedBox(width: 2),
                    if (hasTask)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: AppTheme.warning, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: cells,
    );
  }
}

class _CalendarTaskTile extends StatelessWidget {
  final Task task;
  const _CalendarTaskTile({required this.task});

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':   return AppTheme.error;
      case 'medium': return AppTheme.warning;
      default:       return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final now = DateTime.now();
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(now) &&
        !task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [

          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  task.dueDate != null
                      ? months[task.dueDate!.month - 1].toUpperCase()
                      : '—',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warning),
                ),
                Text(
                  task.dueDate != null ? '${task.dueDate!.day}' : '—',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warning),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                if (task.groupName != null)
                  Row(
                    children: [
                      Icon(Icons.group_outlined,
                          size: 13, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.groupName!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                if (task.priority != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          _priorityColor(task.priority!).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      task.priority![0].toUpperCase() +
                          task.priority!.substring(1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _priorityColor(task.priority!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? AppTheme.success
                  : isOverdue
                      ? AppTheme.error
                      : AppTheme.warning,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      onTap: (i) {
        if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
        if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.discover);
        if (i == 2) Navigator.pushNamed(context, AppRoutes.chats);
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
    );
  }
}

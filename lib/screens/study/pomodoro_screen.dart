import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PomodoroScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const PomodoroScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  static const int _workSeconds = 25 * 60;
  static const int _breakSeconds = 5 * 60;

  Timer? _timer;
  int _secondsLeft = _workSeconds;
  bool _isRunning = false;
  bool _isBreak = false;
  int _sessionsCompleted = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int get _totalSeconds => _isBreak ? _breakSeconds : _workSeconds;
  double get _progress => _secondsLeft / _totalSeconds;

  String get _timeLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggle() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft <= 0) {
          _timer?.cancel();
          if (!_isBreak) {
            setState(() {
              _sessionsCompleted++;
              _isBreak = true;
              _secondsLeft = _breakSeconds;
              _isRunning = false;
            });
          } else {
            setState(() {
              _isBreak = false;
              _secondsLeft = _workSeconds;
              _isRunning = false;
            });
          }
          return;
        }
        setState(() => _secondsLeft--);
      });
      setState(() => _isRunning = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _isBreak ? _breakSeconds : _workSeconds;
      _isRunning = false;
    });
  }

  void _skipPhase() {
    _timer?.cancel();
    setState(() {
      if (!_isBreak) {
        _sessionsCompleted++;
        _isBreak = true;
        _secondsLeft = _breakSeconds;
      } else {
        _isBreak = false;
        _secondsLeft = _workSeconds;
      }
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color phaseColor = _isBreak ? const Color(0xFF059669) : AppTheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: const BackButton(color: AppTheme.primary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pomodoro Timer',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4)),
            Text(widget.groupName, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isBreak ? 'Break Time' : 'Focus Session',
                style: TextStyle(color: phaseColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.divider,
                      color: phaseColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeLabel,
                        style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: phaseColor,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isBreak ? 'Rest up!' : 'Stay focused',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                _circleButton(
                  icon: Icons.replay,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  bgColor: Theme.of(context).scaffoldBackgroundColor,
                  onTap: _reset,
                  size: 52,
                ),
                const SizedBox(width: 20),

                GestureDetector(
                  onTap: _toggle,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: phaseColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: phaseColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                _circleButton(
                  icon: Icons.skip_next,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  bgColor: Theme.of(context).scaffoldBackgroundColor,
                  onTap: _skipPhase,
                  size: 52,
                ),
              ],
            ),
            const SizedBox(height: 40),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) => _sessionDot(i < _sessionsCompleted % 4, phaseColor)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_sessionsCompleted session${_sessionsCompleted == 1 ? '' : 's'} completed',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text('Every 4 sessions = long break',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Put your phone away, close distracting tabs, and focus on one task at a time.',
                      style: TextStyle(color: AppTheme.primary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, border: Border.all(color: AppTheme.divider)),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }

  Widget _sessionDot(bool filled, Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: filled ? color : AppTheme.divider, width: 2),
      ),
    );
  }
}

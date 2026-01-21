import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  final DateTime start;
  DateTime? end;

  Session({required this.start, this.end});

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'end': end?.millisecondsSinceEpoch,
  };

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      start: DateTime.fromMillisecondsSinceEpoch(json['start']),
      end: json['end'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['end'])
          : null,
    );
  }
}

class BreakInfo {
  final DateTime start;
  final DateTime? end;
  final Duration duration;

  BreakInfo({required this.start, this.end, required this.duration});
}

class OfficeTimerService extends ChangeNotifier {
  static const String _keySessions = 'sessions_list_v2';
  static const String _keyDailyGoal = 'daily_goal_hours';
  static const String _keyLastTimestamp = 'last_active_timestamp';

  List<Session> _sessions = [];
  double _dailyGoalHours = 8.0;

  double get dailyGoalHours => _dailyGoalHours;

  bool get isCheckedIn => _sessions.isNotEmpty && _sessions.last.end == null;

  // UI Helpers
  DateTime? get checkInTime =>
      _sessions.isNotEmpty ? _sessions.first.start : null;
  DateTime? get checkOutTime {
    if (_sessions.isEmpty) return null;
    final last = _sessions.last;
    if (last.end != null) return last.end;
    // If currently checked in, return the end time of the *previous* session?
    // Or null? The UI uses this to show "Last Check Out".
    // If I am currently in office, my last check out was the previous session's end.
    if (_sessions.length > 1) {
      return _sessions[_sessions.length - 2].end;
    }
    return null;
  }

  OfficeTimerService() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // 9 AM Reset Logic
    final int? lastTimestamp = prefs.getInt(_keyLastTimestamp);
    final now = DateTime.now();

    // Calculate cutoff: Most recent 9:00 AM
    // If now is 8:00 AM, cutoff is Yesterday 9:00 AM.
    // If now is 10:00 AM, cutoff is Today 9:00 AM.
    DateTime cutoff = DateTime(now.year, now.month, now.day, 9, 0, 0);
    if (now.isBefore(cutoff)) {
      cutoff = cutoff.subtract(const Duration(days: 1));
    }

    // If last active time was BEFORE the cutoff, it belongs to a previous "day" (cycle).
    // So we clear it.
    if (lastTimestamp != null) {
      final lastActive = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
      if (lastActive.isBefore(cutoff)) {
        await _clearSession(prefs);
      } else {
        _loadSessions(prefs);
      }
    } else {
      _loadSessions(prefs);
    }

    // Update last active time to now
    await prefs.setInt(_keyLastTimestamp, now.millisecondsSinceEpoch);
    _dailyGoalHours = prefs.getDouble(_keyDailyGoal) ?? 8.0;

    notifyListeners();
  }

  void _loadSessions(SharedPreferences prefs) {
    final String? sessionsJson = prefs.getString(_keySessions);
    if (sessionsJson != null) {
      final List<dynamic> decoded = jsonDecode(sessionsJson);
      _sessions = decoded.map((e) => Session.fromJson(e)).toList();
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_keySessions);
    _sessions = [];
  }

  Future<void> checkIn() async {
    if (isCheckedIn) {
      throw Exception('Already checked in');
    }

    final now = DateTime.now();
    _sessions.add(Session(start: now));

    await _saveSessions();

    notifyListeners();
  }

  Future<void> checkOut() async {
    if (!isCheckedIn) {
      throw Exception('Please check in first');
    }

    final now = DateTime.now();
    _sessions.last.end = now;

    await _saveSessions();
    notifyListeners();
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(
      _sessions.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(_keySessions, jsonStr);
    // Update timestamp on save to keep it fresh
    await prefs.setInt(
      _keyLastTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> setDailyGoal(double hours) async {
    _dailyGoalHours = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDailyGoal, hours);
    notifyListeners();
  }

  /// Returns total duration spent in office today
  Duration get currentDuration {
    Duration total = Duration.zero;
    final now = DateTime.now();
    for (var session in _sessions) {
      if (session.end != null) {
        total += session.end!.difference(session.start);
      } else {
        total += now.difference(session.start);
      }
    }
    return total;
  }

  Duration get remainingDuration {
    final goal = Duration(minutes: (_dailyGoalHours * 60).round());
    final spent = currentDuration;
    final left = goal - spent;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isGoalMet => remainingDuration == Duration.zero;

  List<BreakInfo> get breaks {
    List<BreakInfo> list = [];
    if (_sessions.isEmpty) return list;

    for (int i = 0; i < _sessions.length; i++) {
      // Break is Gaps BETWEEN sessions.
      // Gap exists between session[i-1].end and session[i].start
      if (i > 0) {
        final prevEnd = _sessions[i - 1].end!;
        final currStart = _sessions[i].start;
        list.add(
          BreakInfo(
            start: prevEnd,
            end: currStart,
            duration: currStart.difference(prevEnd),
          ),
        );
      }
    }

    // Current open break (if checked out)
    // If not checked in (meaning last session has an end time), we are on a break right now.
    // Wait, checkIn logic: isCheckedIn => _sessions.last.end == null.
    // So if !isCheckedIn => _sessions.last.end != null.
    if (_sessions.isNotEmpty && _sessions.last.end != null) {
      final lastEnd = _sessions.last.end!;
      final now = DateTime.now();
      list.add(
        BreakInfo(
          start: lastEnd,
          end: null, // Continuing
          duration: now.difference(lastEnd),
        ),
      );
    }

    return list;
  }

  Duration get totalBreakDuration {
    return breaks.fold(
      Duration.zero,
      (prev, element) => prev + element.duration,
    );
  }
}

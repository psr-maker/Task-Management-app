import 'package:flutter/material.dart';

/// Provider to manage app-wide data refresh
class DataRefreshNotifier extends ChangeNotifier {
  // Keys to trigger refresh for specific data types
  DateTime? _lastTaskRefresh;
  DateTime? _lastGoalRefresh;
  DateTime? _lastUserRefresh;
  DateTime? _lastLeaveRefresh;
  DateTime? _lastPermissionRefresh;
  DateTime? _lastWorklogRefresh;
  DateTime? _lastAnnouncementRefresh;
  DateTime? _lastPointsRefresh;

  // Getters
  DateTime? get lastTaskRefresh => _lastTaskRefresh;
  DateTime? get lastGoalRefresh => _lastGoalRefresh;
  DateTime? get lastUserRefresh => _lastUserRefresh;
  DateTime? get lastLeaveRefresh => _lastLeaveRefresh;
  DateTime? get lastPermissionRefresh => _lastPermissionRefresh;
  DateTime? get lastWorklogRefresh => _lastWorklogRefresh;
  DateTime? get lastAnnouncementRefresh => _lastAnnouncementRefresh;
  DateTime? get lastPointsRefresh => _lastPointsRefresh;

  /// Trigger refresh for tasks
  void refreshTasks() {
    _lastTaskRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for goals
  void refreshGoals() {
    _lastGoalRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for users
  void refreshUsers() {
    _lastUserRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for leaves
  void refreshLeaves() {
    _lastLeaveRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for permissions
  void refreshPermissions() {
    _lastPermissionRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for worklogs
  void refreshWorklogs() {
    _lastWorklogRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for announcements
  void refreshAnnouncements() {
    _lastAnnouncementRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for points
  void refreshPoints() {
    _lastPointsRefresh = DateTime.now();
    notifyListeners();
  }

  /// Trigger refresh for all data
  void refreshAll() {
    _lastTaskRefresh = DateTime.now();
    _lastGoalRefresh = DateTime.now();
    _lastUserRefresh = DateTime.now();
    _lastLeaveRefresh = DateTime.now();
    _lastPermissionRefresh = DateTime.now();
    _lastWorklogRefresh = DateTime.now();
    _lastAnnouncementRefresh = DateTime.now();
    _lastPointsRefresh = DateTime.now();
    notifyListeners();
  }
}

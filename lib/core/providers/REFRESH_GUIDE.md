# Auto-Refresh Implementation Guide

## Overview
A Provider-based system has been implemented to automatically refresh data across the entire app when any add, edit, delete, or toggle action is performed.

## How It Works

### 1. **DataRefreshNotifier** (`lib/core/providers/data_refresh_provider.dart`)
- Central state management for triggering refreshes
- Tracks refresh timestamps for different data types
- Methods available:
  - `refreshTasks()` - Refresh task data
  - `refreshGoals()` - Refresh goal data
  - `refreshUsers()` - Refresh user data
  - `refreshLeaves()` - Refresh leave data
  - `refreshPermissions()` - Refresh permission data
  - `refreshWorklogs()` - Refresh worklog data
  - `refreshAnnouncements()` - Refresh announcement data
  - `refreshPoints()` - Refresh points data
  - `refreshAll()` - Refresh all data types at once

### 2. **Provider Setup** (`lib/main.dart`)
- `DataRefreshNotifier` is provided globally using `MultiProvider`
- All screens have access to the refresh notifier via `context.read<DataRefreshNotifier>()`

### 3. **Listening for Refreshes** (`didChangeDependencies`)
Each screen should add this method to listen for refresh signals:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Listen for refresh signals from the provider
  context.watch<DataRefreshNotifier>().lastUserRefresh;
  context.watch<DataRefreshNotifier>().lastGoalRefresh;
  // Add more watches as needed
}
```

Then use `addPostFrameCallback` to reload data when refresh is triggered:
```dart
void didChangeDependencies() {
  super.didChangeDependencies();
  // Watch triggers rebuilds
  context.watch<DataRefreshNotifier>().lastGoalRefresh;
  // Reload in a callback to avoid rebuild during frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    loadEmployeeGoals();
  });
}
```

## Updated Screens

### 1. **Employee Details** (`empdetails.dart`)
- ✅ Listens for user and goal refreshes
- ✅ Toggle active/deactive triggers `refreshUsers()`
- ✅ Edit user triggers `refreshUsers()`
- ✅ Add goal/task triggers `refreshGoals()`
- ✅ Uses `didUpdateWidget()` to reload when employee parameter changes
- ✅ Properly resets status initialization flag

### 2. **Goal/Task Creation** (`goalntask_create.dart`)
- ✅ Task creation triggers `refreshTasks()` and `refreshGoals()`
- ✅ Goal creation triggers `refreshGoals()` and `refreshTasks()`

### 3. **Worklog Screens**
- ✅ Add Worklog (`addworklog.dart`) - triggers `refreshWorklogs()` on success
- ✅ Edit Worklog (`edit_worklog.dart`) - triggers `refreshWorklogs()` on success

### 4. **Announcement Screens**
- ✅ Post Announcement (`postanounce.dart`) - triggers `refreshAnnouncements()` on success

## How to Use in Your Screens

### To Trigger a Refresh (After Data Change):
```dart
// After successful API call
context.read<DataRefreshNotifier>().refreshGoals();
// or for multiple:
context.read<DataRefreshNotifier>().refreshUsers();
context.read<DataRefreshNotifier>().refreshGoals();
```

### To Listen for Refreshes:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Watch for changes
  final lastRefresh = context.watch<DataRefreshNotifier>().lastGoalRefresh;
  
  // Reload data when refresh is triggered
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (lastRefresh != _lastLoadedRefresh) {
      _lastLoadedRefresh = lastRefresh;
      loadEmployeeGoals(); // Your data loading method
    }
  });
}
```

### To Return and Notify Parent:
```dart
// After successful operation
if (mounted) {
  context.read<DataRefreshNotifier>().refreshGoals();
  Navigator.pop(context, true);
}
```

## Key Benefits

1. **No Local State Issues** - Data is always fresh from the server
2. **Automatic Sync** - All screens receive refresh notifications simultaneously
3. **No Navigation Complexity** - Works seamlessly with navigation
4. **Scalable** - Easy to add more data types
5. **Clean Architecture** - Separation of concerns with Provider

## Screens Still Needing Updates

The following screens should be updated to trigger refreshes on success:
- Leave management screens (add, edit, delete, approve/reject)
- Permission management screens (add, active/deactive, delete)
- Five points/task points screens (add, edit, delete)
- Any other data management screens

## Common Pattern to Apply

For any create/edit/delete screen:

1. **Add imports at top:**
```dart
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
```

2. **After successful API call:**
```dart
context.read<DataRefreshNotifier>().refreshDataType();
Navigator.pop(context, true);
```

3. **In parent screen's didChangeDependencies or initState:**
```dart
context.watch<DataRefreshNotifier>().lastDataTypeRefresh;
// Then reload your data
```

This ensures automatic synchronization across the entire app!

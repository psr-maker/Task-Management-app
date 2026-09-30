import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/employee.dart';
import 'package:staff_work_track/screen/division_head/div_users.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/dept.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Users.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/adaptive_goal_cards.dart';

enum DashboardListKind { staff, departments, goals, tasks }

enum WorkStatusFilter { all, completed, pending, overdue, onTime, delayed }

void openDashboardList(
  BuildContext context, {
  required DashboardListKind kind,
  WorkStatusFilter filter = WorkStatusFilter.all,
  required String title,
  String? department,
  List<String>? departments,
  int? userId,
  bool companyDepartments = false,
}) {
  final page = switch (kind) {
    DashboardListKind.staff => _staffPage(department, departments),
    DashboardListKind.departments => DepartmentBrowsePage(
        title: title,
        departments: departments,
        companyWide: companyDepartments,
      ),
    DashboardListKind.goals || DashboardListKind.tasks => WorkListPage(
        title: title,
        kind: kind,
        filter: filter,
        department: department,
        departments: departments,
        userId: userId,
      ),
  };

  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

Widget _staffPage(String? department, List<String>? departments) {
  if (departments != null &&
      departments.isNotEmpty &&
      department != null &&
      department.trim().isNotEmpty) {
    return DivUsers(
      department: department,
      showAppBar: true,
      openReports: true,
    );
  }
  if (department != null && department.trim().isNotEmpty) {
    return const Employeelist(showAppBar: true, openReports: true);
  }
  return const Usersview(showAppBar: true);
}

class DepartmentBrowsePage extends StatefulWidget {
  final String title;
  final List<String>? departments;
  final bool companyWide;

  const DepartmentBrowsePage({
    super.key,
    required this.title,
    this.departments,
    this.companyWide = false,
  });

  @override
  State<DepartmentBrowsePage> createState() => _DepartmentBrowsePageState();
}

class _DepartmentBrowsePageState extends State<DepartmentBrowsePage> {
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    final provided = widget.departments
        ?.map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (widget.departments != null) {
      _future = Future.value(provided ?? []);
    } else if (widget.companyWide) {
      _future = _loadCompanyDepartments();
    } else {
      _future = ReportsService.getAllDepartments();
    }
  }

  Future<List<String>> _loadCompanyDepartments() async {
    try {
      final rows = await SuperAdminService().getDepartments();
      final names = rows
          .map((item) => item.departmentName.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (names.isNotEmpty) return names;
    } catch (_) {}
    return ReportsService.getAllDepartments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (snapshot.hasError) {
            return const AppLoadError();
          }
          final departments = snapshot.data ?? [];
          if (departments.isEmpty) {
            return const Center(child: Text('No departments found'));
          }
          return ListView.separated(
            padding: AppLayout.pagePadding(context),
            itemCount: departments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final department = departments[index];
              return Material(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  leading: const Icon(Icons.apartment),
                  title: Text(department),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DepartmentReportsTab(department: department),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WorkListPage extends StatefulWidget {
  final String title;
  final DashboardListKind kind;
  final WorkStatusFilter filter;
  final String? department;
  final List<String>? departments;
  final int? userId;

  const WorkListPage({
    super.key,
    required this.title,
    required this.kind,
    required this.filter,
    this.department,
    this.departments,
    this.userId,
  });

  @override
  State<WorkListPage> createState() => _WorkListPageState();
}

class _WorkListPageState extends State<WorkListPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final scoped = widget.departments
            ?.map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList() ??
        [];

    final reports = <Map<String, dynamic>>[];
    if (scoped.isNotEmpty) {
      final results = await Future.wait(
        scoped.map((department) async {
          try {
            return await ReportsService.getFullReport(department: department);
          } catch (error) {
            debugPrint('Work list $department: $error');
            return <String, dynamic>{};
          }
        }),
      );
      reports.addAll(results);
    } else if (widget.department != null &&
        widget.department!.trim().isNotEmpty) {
      reports.add(
        await ReportsService.getFullReport(department: widget.department),
      );
    } else if (widget.userId != null) {
      reports.add(await ReportsService.getFullReport(userId: widget.userId));
    } else {
      reports.add(await ReportsService.getFullReport());
    }

    final people = widget.kind == DashboardListKind.goals
        ? await _peopleByGoalCode(
            department: widget.department,
            departments: scoped,
            userId: widget.userId,
          )
        : const <String, Map>{};

    final seen = <String>{};
    final items = <Map<String, dynamic>>[];

    void addItem(Map<String, dynamic> item) {
      final id = _itemKey(item, widget.kind);
      if (!seen.add(id)) return;
      if (_matches(item, widget.filter)) items.add(item);
    }

    for (final report in reports) {
      if (widget.kind == DashboardListKind.goals) {
        final raw = report['goals'];
        if (raw is! List) continue;
        for (final entry in raw) {
          if (entry is! Map) continue;
          final goal = _normalizeGoal(entry, people);
          addItem(goal);
          final months = goal['monthlyGoals'];
          if (months is List) {
            for (final month in months) {
              if (month is Map) addItem(Map<String, dynamic>.from(month));
            }
          }
        }
      } else {
        final raw = report['tasks'];
        if (raw is List) {
          for (final entry in raw) {
            if (entry is Map) addItem(_normalizeTask(entry));
          }
        }
        final goals = report['goals'];
        if (goals is List) {
          for (final goal in goals) {
            if (goal is! Map) continue;
            final nested = goal['tasks'] ?? goal['Tasks'];
            if (nested is! List) continue;
            for (final entry in nested) {
              if (entry is Map) addItem(_normalizeTask(entry));
            }
          }
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final noun = widget.kind == DashboardListKind.goals ? 'goals' : 'tasks';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (snapshot.hasError) {
            return const AppLoadError();
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(child: Text('No $noun found'));
          }
          return Padding(
            padding: AppLayout.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} $noun',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: AdaptiveGoalCards(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (widget.kind == DashboardListKind.goals) {
                        return GoalCard(goal: item);
                      }
                      return Taskstatus(
                        task: item,
                        onTap: () {
                          final code = (item['taskCode'] ?? '').toString();
                          if (code.isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetails(taskCode: code),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _itemKey(Map<String, dynamic> item, DashboardListKind kind) {
  if (kind == DashboardListKind.goals) {
    final code = (item['goalCode'] ?? '').toString();
    final due = (item['dueDate'] ?? '').toString();
    if (code.isNotEmpty) return 'goal:$code|$due';
    return 'goal:${item['title']}|$due';
  }
  final code = (item['taskCode'] ?? '').toString();
  if (code.isNotEmpty) return 'task:$code';
  return 'task:${item['task']}|${item['dueDate']}';
}

Future<Map<String, Map>> _peopleByGoalCode({
  String? department,
  List<String> departments = const [],
  int? userId,
}) async {
  final chunks = <List<dynamic>>[];
  try {
    if (departments.isNotEmpty) {
      for (final name in departments) {
        chunks.add(await AdminService.getGoalsByDepartment(name));
      }
    } else if (department != null && department.trim().isNotEmpty) {
      chunks.add(await AdminService.getGoalsByDepartment(department));
    } else if (userId != null) {
      chunks.add(await AdminService.getusergoalbyid(userId));
    } else {
      chunks.add(await SuperAdminService.getGoals());
    }
  } catch (error) {
    debugPrint('Goal names: $error');
  }

  final byCode = <String, Map>{};
  void index(dynamic raw) {
    if (raw is! Map) return;
    final code = (raw['goalCode'] ?? raw['GoalCode'] ?? '').toString();
    if (code.isNotEmpty) byCode[code] = raw;
    final months = raw['monthlyGoals'] ?? raw['MonthlyGoals'];
    if (months is List) {
      for (final month in months) {
        index(month);
      }
    }
  }

  for (final chunk in chunks) {
    for (final item in chunk) {
      index(item);
    }
  }
  return byCode;
}

void _copyPersonFields(Map<String, dynamic> goal, Map? source) {
  if (source == null) return;
  for (final key in const [
    'createdByName',
    'assignBy',
    'createdBy',
    'CreatedBy',
    'assignedUsers',
    'AssignedUsers',
    'assignedTo',
    'AssignedTo',
    'assignTo',
  ]) {
    final value = source[key];
    if (value == null) continue;
    if (value is String && value.trim().isEmpty) continue;
    if (value is List && value.isEmpty) continue;
    final current = goal[key];
    final empty = current == null ||
        (current is String &&
            (current.trim().isEmpty ||
                current.trim().toLowerCase() == 'n/a')) ||
        (current is List && current.isEmpty);
    if (empty) goal[key] = value;
  }
}

Map<String, dynamic> _normalizeGoal(Map raw, Map<String, Map> people) {
  final goal = Map<String, dynamic>.from(raw);
  final code = (goal['goalCode'] ?? goal['GoalCode'] ?? '').toString();
  _copyPersonFields(goal, people[code]);
  goal['title'] = goal['title'] ?? goal['Title'] ?? '';
  goal['status'] = goal['status'] ?? goal['Status'] ?? '';
  goal['priority'] = goal['priority'] ?? goal['Priority'] ?? '';
  goal['goalCode'] = code;
  goal['goalType'] = goal['goalType'] ?? goal['GoalType'] ?? '';
  goal['dueDate'] = goal['dueDate'] ?? goal['due_Date'] ?? goal['DueDate'];
  goal['targetQuantity'] =
      goal['targetQuantity'] ?? goal['TargetQuantity'] ?? 0;
  goal['completedQuantity'] =
      goal['completedQuantity'] ?? goal['CompletedQuantity'] ?? 0;
  goal['completed_Date'] =
      goal['completed_Date'] ?? goal['completedDate'] ?? goal['CompletedDate'];
  goal['isOverdue'] = goal['isOverdue'] ?? goal['IsOverdue'] ?? false;
  final createdBy = (goal['createdByName'] ??
          goal['assignBy'] ??
          goal['createdBy'] ??
          goal['CreatedBy'] ??
          '')
      .toString()
      .trim();
  if (createdBy.isNotEmpty && createdBy.toLowerCase() != 'n/a') {
    goal['createdByName'] = createdBy;
  }
  final assigned = goal['assignedUsers'] ?? goal['AssignedUsers'];
  if (assigned is! List || assigned.isEmpty) {
    final to = goal['assignedTo'] ?? goal['AssignedTo'] ?? goal['assignTo'];
    if (to is List && to.isNotEmpty) goal['assignedUsers'] = to;
  }
  if (goal['tasks'] is! List) goal['tasks'] = [];
  final months = goal['monthlyGoals'] ?? goal['MonthlyGoals'];
  if (months is List) {
    goal['monthlyGoals'] = [
      for (final month in months)
        if (month is Map) _normalizeGoal(month, people),
    ];
  } else {
    goal['monthlyGoals'] = [];
  }
  return goal;
}

Map<String, dynamic> _normalizeTask(Map raw) {
  final task = Map<String, dynamic>.from(raw);
  task['task'] = task['task'] ?? task['title'] ?? task['Task'] ?? '';
  task['status'] = task['status'] ?? task['Status'] ?? '';
  task['priority'] = task['priority'] ?? task['Priority'] ?? '';
  task['taskCode'] = task['taskCode'] ?? task['TaskCode'] ?? '';
  task['dueDate'] = task['dueDate'] ?? task['due_Date'] ?? task['DueDate'];
  task['completed_Date'] =
      task['completed_Date'] ?? task['completedDate'] ?? task['CompletedDate'];
  task['isOverdue'] = task['isOverdue'] ?? task['IsOverdue'] ?? false;
  task['totalMembers'] = task['totalMembers'] ?? task['TotalMembers'] ?? 0;
  return task;
}

bool _matches(Map<String, dynamic> item, WorkStatusFilter filter) {
  switch (filter) {
    case WorkStatusFilter.all:
      return true;
    case WorkStatusFilter.completed:
      return _isCompleted(item);
    case WorkStatusFilter.pending:
      if (_isCompleted(item)) return false;
      final status = AppHelpers.normalize((item['status'] ?? '').toString());
      if (status == 'pending' ||
          status == 'inprogress' ||
          status == 'paused' ||
          status == 'notstarted' ||
          status == 'onhold') {
        return true;
      }
      return !_isOverdue(item);
    case WorkStatusFilter.overdue:
      return _isOverdue(item);
    case WorkStatusFilter.onTime:
      return _isCompleted(item) && !_isLate(item);
    case WorkStatusFilter.delayed:
      return _isCompleted(item) && _isLate(item);
  }
}

bool _isCompleted(Map<String, dynamic> item) {
  return AppHelpers.normalize((item['status'] ?? '').toString()) == 'completed';
}

bool _isOverdue(Map<String, dynamic> item) {
  if (_isCompleted(item)) return false;
  if (item['isOverdue'] == true) return true;
  final status = AppHelpers.normalize((item['status'] ?? '').toString());
  if (status == 'overdue') return true;
  final due = _dateOnly(_parseDate(item['dueDate']));
  if (due == null) return false;
  final today = _dateOnly(DateTime.now())!;
  return due.isBefore(today);
}

bool _isLate(Map<String, dynamic> item) {
  if (item['isOverdue'] == true) return true;
  final status = AppHelpers.normalize((item['status'] ?? '').toString());
  if (status == 'delayed' || status == 'overdue') return true;
  final completed = _dateOnly(_parseDate(item['completed_Date']));
  final due = _dateOnly(_parseDate(item['dueDate']));
  if (completed == null || due == null) return false;
  return completed.isAfter(due);
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.startsWith('0001-01-01')) return null;
  return DateTime.tryParse(text);
}

DateTime? _dateOnly(DateTime? value) {
  if (value == null) return null;
  return DateTime(value.year, value.month, value.day);
}

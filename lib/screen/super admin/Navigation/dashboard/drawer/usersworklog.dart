import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/worklog_date_picker.dart';
import 'package:staff_work_track/core/widgets/worklog_web_board.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/worklog_session_tile.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class UsersWorklog extends StatefulWidget {
  final List<String>? allowedDepartments;
  const UsersWorklog({super.key, this.allowedDepartments});

  @override
  State<UsersWorklog> createState() => _UsersWorklogState();
}

class _UsersWorklogState extends State<UsersWorklog> {
  List<dynamic> worklogs = [];
  List<dynamic> filteredLogs = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  String searchQuery = "";
  String selectedDepartment = "All";
  DateTime? selectedDate;

  List<String> get filterDepartments =>
      widget.allowedDepartments != null && widget.allowedDepartments!.isNotEmpty
      ? ["All", ...widget.allowedDepartments!]
      : ["All", ...departments];

  List<String> departments = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String formatTime(String? dateTime) {
    if (dateTime == null) return "";
    final time = DateTime.parse(dateTime);
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // ✅ FORMAT HOURS
  String formatHours(double hours) {
    int h = hours.floor();
    int m = ((hours - h) * 60).round();
    return "${h}h ${m}m";
  }

  Future<void> fetchData() async {
    if (mounted) setState(() => isLoading = true);
    try {
      List data = [];
      try {
        data = await AnnouncementService.getWorklogs();
      } catch (_) {}

      final allowed = widget.allowedDepartments;
      if (allowed != null && allowed.isNotEmpty) {
        final perDept = await Future.wait(
          allowed.map((dept) async {
            try {
              return await AnnouncementService.getWorklogs(department: dept);
            } catch (_) {
              return <dynamic>[];
            }
          }),
        );
        for (final list in perDept) {
          data.addAll(list);
        }
      }

      final unique = <String, dynamic>{};
      for (final log in data) {
        final key =
            (log['id'] ??
                    "${log['userId']}_${log['workDate']}_${log['startTime']}")
                .toString();
        unique[key] = log;
      }
      data = pairWorkLogs(unique.values.toList());

      if (allowed != null && allowed.isNotEmpty) {
        data = data.where((log) {
          return DivisionConfig.isAllowedDepartment(
            (log['departmentName'] ?? log['department'] ?? '').toString(),
            allowed,
          );
        }).toList();
      }

      final deptSet = <String>{};
      for (var log in data) {
        final name = (log['departmentName'] ?? log['department'] ?? '')
            .toString();
        if (name.isNotEmpty) deptSet.add(name);
      }

      if (!mounted) return;
      setState(() {
        worklogs = data;
        filteredLogs = data;
        departments = deptSet.toList();
        isLoading = false;
      });
      applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print(e);
    }
  }

  void applyFilter() {
    List<dynamic> temp = worklogs;

    if (selectedDepartment != "All") {
      temp = temp
          .where(
            (w) => DivisionConfig.isAllowedDepartment(
              (w['departmentName'] ?? w['department'] ?? '').toString(),
              [selectedDepartment],
            ),
          )
          .toList();
    }

    if (selectedDate != null) {
      temp = temp
          .where(
            (w) {
              try {
                final localDate = TimeUtils.fromUtcIso8601(w['workDate']);
                return localDate.day == selectedDate!.day &&
                    localDate.month == selectedDate!.month &&
                    localDate.year == selectedDate!.year;
              } catch (_) {
                return false;
              }
            },
          )
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      temp = temp
          .where(
            (w) {
              final name = (w['name'] ?? w['userName'] ?? "")
                  .toString()
                  .toLowerCase();
              final title = (w['title'] ?? "").toString().toLowerCase();
              final query = searchQuery.toLowerCase();
              return name.contains(query) || title.contains(query);
            },
          )
          .toList();
    }

    setState(() {
      filteredLogs = temp;
    });
  }

  void _setDate(DateTime? value) {
    setState(() => selectedDate = value);
    applyFilter();
  }

  Map<String, List<dynamic>> groupByDate(List logs) {
    Map<String, List<dynamic>> grouped = {};

    for (var log in logs) {
      try {
        // Use TimeUtils to properly convert UTC to local for correct date grouping
        final localDate = TimeUtils.fromUtcIso8601(log["workDate"]);
        final dateKey = "${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}";
        
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(log);
      } catch (_) {
        String date = log["workDate"]?.split("T")[0] ?? "";
        if (!grouped.containsKey(date)) {
          grouped[date] = [];
        }
        grouped[date]!.add(log);
      }
    }

    return grouped;
  }

  Widget _webBoard() {
    return WorklogWebBoard(
      title: 'Worklogs',
      subtitle: 'Check-in and check-out across departments',
      loading: isLoading,
      logs: filteredLogs,
      searchController: searchController,
      onSearch: (value) {
        searchQuery = value;
        applyFilter();
      },
      selectedDate: selectedDate,
      onDate: _setDate,
      departments: filterDepartments,
      selectedDepartment: selectedDepartment,
      onDepartment: (value) {
        setState(() => selectedDepartment = value);
        applyFilter();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isMobile(context)) return _webBoard();
    final groupedLogs = groupByDate(filteredLogs);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: "Search by user...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    applyFilter();
                  });
                },
              )
            : const Text("Users Worklogs"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  searchQuery = "";
                  applyFilter();
                }
                isSearching = !isSearching;
              });
            },
          ),

          if (widget.allowedDepartments == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_alt),
              onSelected: (value) {
                setState(() {
                  selectedDepartment = value;
                  applyFilter();
                });
              },
              itemBuilder: (context) => filterDepartments
                  .map(
                    (d) => PopupMenuItem<String>(
                      value: d,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              d == "All" ? "All Departments" : d,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          if (selectedDepartment == d)
                            const Icon(Icons.check, color: Colors.green),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: WorklogDateButton(date: selectedDate, onChanged: _setDate),
            ),
          ),
          if (widget.allowedDepartments != null &&
              widget.allowedDepartments!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: filterDepartments.map((dept) {
                    final selected = selectedDepartment == dept;
                    final label = dept == "All"
                        ? "All"
                        : dept.replaceAll(" Department", "");
                    final secondary = Theme.of(context).colorScheme.secondary;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDepartment = dept;
                            applyFilter();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: selected ? secondary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? secondary
                                  : const Color(0xFFD0D5D2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                label,
                                style: TextStyle(
                                  color: selected ? Colors.white : secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: RotatingFlower())
                : filteredLogs.isEmpty
                ? const Center(child: Text("No Worklogs Found"))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: groupedLogs.entries.map((entry) {
                      String date = entry.key;
                      List logs = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              TimeUtils.formatDate(DateTime.parse(date)),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          ...logs.map((log) => WorklogSessionTile(log: log)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

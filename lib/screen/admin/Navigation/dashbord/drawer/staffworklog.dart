import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/worklog_session_tile.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class Staffworklog extends StatefulWidget {
  const Staffworklog({super.key});

  @override
  State<Staffworklog> createState() => _UsersWorklogState();
}

class _UsersWorklogState extends State<Staffworklog> {
  List<dynamic> worklogs = [];
  List<dynamic> filteredLogs = [];
  bool isLoading = true;

  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  List<String> departments = [];
  String searchQuery = "";
  String? selectedDepartment;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // FETCH DATA
  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final data = await AnnouncementService.getDepartmentWorklogs();

      final sessions = pairWorkLogs(data);
      setState(() {
        worklogs = sessions;
        filteredLogs = sessions;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  // FILTER
  void applyFilter() {
    List<dynamic> temp = worklogs;

    if (selectedDate != null) {
      temp = temp.where((w) {
        final date = TimeUtils.fromUtcIso8601(w['workDate']);
        return date.year == selectedDate!.year &&
            date.month == selectedDate!.month &&
            date.day == selectedDate!.day;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      temp = temp.where((w) {
        final name = (w['name'] ?? w['userName'] ?? "").toString().toLowerCase();
        final title = (w['title'] ?? "").toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || title.contains(query);
      }).toList();
    }

    setState(() {
      filteredLogs = temp;
    });
  }

  // GROUP BY DATE
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

  // DATE PICKER
  void _showDatePicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        applyFilter();
      });
    }
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(
                  hintText: "Search user...",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    applyFilter();
                  });
                },
              )
            : const Text("Worklogs"),
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
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
          ),
        ],
      ),

      body: isLoading
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
                    // DATE HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        TimeUtils.formatDate(DateTime.parse(date)),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),

                    // WORKLOGS
                    ...logs.map((log) => WorklogSessionTile(log: log)),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/services/announ_service.dart';

class UsersWorklog extends StatefulWidget {
  const UsersWorklog({super.key});

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
  String? selectedDepartment;
  DateTime? selectedDate;

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
    setState(() => isLoading = true);
    try {
      final data = await AnnouncementService.getWorklogs();
      final deptSet = <String>{};
      for (var log in data) {
        if (log['departmentName'] != null) {
          deptSet.add(log['departmentName']);
        }
      }

      setState(() {
        worklogs = data;
        filteredLogs = data;
        departments = deptSet.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  void applyFilter() {
    List<dynamic> temp = worklogs;

    if (selectedDepartment != null && selectedDepartment!.isNotEmpty) {
      temp = temp
          .where((w) => w['departmentName'] == selectedDepartment)
          .toList();
    }

    if (selectedDate != null) {
      temp = temp
          .where(
            (w) =>
                DateTime.parse(w['workDate']).toLocal().day ==
                    selectedDate!.day &&
                DateTime.parse(w['workDate']).toLocal().month ==
                    selectedDate!.month &&
                DateTime.parse(w['workDate']).toLocal().year ==
                    selectedDate!.year,
          )
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      temp = temp
          .where(
            (w) => (w['userName'] ?? "").toString().toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    setState(() {
      filteredLogs = temp;
    });
  }

  void _showDepartmentFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: ListView(
            children: [
              ListTile(
                title: Center(
                  child: Text(
                    "All Departments",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                onTap: () {
                  setState(() {
                    selectedDepartment = null;
                    applyFilter();
                  });
                  Navigator.pop(context);
                },
              ),
              ...departments.map(
                (d) => ListTile(
                  title: Text(
                    d,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  onTap: () {
                    setState(() {
                      selectedDepartment = d;
                      applyFilter();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDateMonthPicker() {
    int tempYear = selectedDate?.year ?? DateTime.now().year;
    int tempMonth = selectedDate?.month ?? DateTime.now().month;
    int tempDay = selectedDate?.day ?? DateTime.now().day;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Date or Month",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              // Year picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Year",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  DropdownButton<int>(
                    value: tempYear,
                    style: Theme.of(context).textTheme.headlineSmall,
                    items: List.generate(10, (i) => DateTime.now().year - i)
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text("$y")),
                        )
                        .toList(),
                    onChanged: (v) => tempYear = v!,
                  ),
                ],
              ),
              // Month picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Month",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  DropdownButton<int>(
                    value: tempMonth,
                    style: Theme.of(context).textTheme.headlineSmall,
                    items: List.generate(12, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          DateFormat('MMMM').format(DateTime(0, i + 1)),
                        ),
                      );
                    }),
                    onChanged: (v) => tempMonth = v!,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Day picker (optional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Day", style: Theme.of(context).textTheme.headlineLarge),
                  DropdownButton<int>(
                    value: tempDay,
                    style: Theme.of(context).textTheme.headlineSmall,
                    items:
                        List.generate(
                              DateTime(tempYear, tempMonth + 1, 0).day,
                              (i) => i + 1,
                            )
                            .map(
                              (d) =>
                                  DropdownMenuItem(value: d, child: Text("$d")),
                            )
                            .toList(),
                    onChanged: (v) => tempDay = v!,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: AppButton(
                  text: "Apply",
                  isLoading: isLoading,
                  onPressed: () {
                    setState(() {
                      selectedDate = DateTime(tempYear, tempMonth, tempDay);
                      applyFilter();
                    });
                    Navigator.pop(context);
                  },
                  color: Theme.of(context).colorScheme.secondary,
                  txtcolor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<dynamic>> groupByDate(List logs) {
    Map<String, List<dynamic>> grouped = {};

    for (var log in logs) {
      String date = log["workDate"]?.split("T")[0] ?? "";

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }

      grouped[date]!.add(log);
    }

    return grouped;
  }

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

          IconButton(
            onPressed: _showDepartmentFilter,
            icon: const Icon(Icons.filter_alt),
          ),

          IconButton(
            onPressed: _showDateMonthPicker,
            icon: const Icon(Icons.calendar_today),
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
                    // 📅 DATE HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        DateFormat("yyyy-MMMM-dd").format(DateTime.parse(date)),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),

                    // 📍 TIMELINE ITEMS
                    ...logs
                        .map((log) => buildTimelineItem(context, log))
                        .toList(),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget buildTimelineItem(BuildContext context, dynamic log) {
    final accentColor = Theme.of(context).colorScheme.secondary;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool isExpanded = false;

        return StatefulBuilder(
          builder: (context, setStateItem) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.location_history,
                      size: 30,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    Container(width: 2, height: 25, color: accentColor),
                  ],
                ),

                const SizedBox(width: 15),

                // 📦 CONTENT BOX
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log["userName"] ?? "",
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            Row(
                              children: [
                                Text(
                                  formatHours(
                                    (log["totalHours"] ?? 0).toDouble(),
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                IconButton(
                                  icon: Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                  ),
                                  onPressed: () {
                                    setStateItem(() {
                                      isExpanded = !isExpanded;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          log["title"] ?? "",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),

                        const SizedBox(height: 5),

                        // 📍 LOCATION
                        Text(
                          " Location : ${log["locationName"] ?? "No location"}",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                        // // ⬇ EXPANDED CONTENT
                        if (isExpanded) ...[
                          Divider(color: accentColor),
                          const SizedBox(height: 5),
                          Text(
                            "Start Time: ${formatTime(log["startTime"])}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "End Time: ${formatTime(log["endTime"])}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Description: ${log["description"] ?? ""}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (log["imageUrl"] != null &&
                              log["imageUrl"].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: GestureDetector(
                                onTap: () {
                                  final fullUrl =
                                      "${ApiConstants.Uploaded}${log["imageUrl"].toString()}";

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageViewer(
                                        imageUrl: fullUrl,
                                      ),
                                    ),
                                  );
                                },
                                // child: ClipRRect(
                                //   borderRadius: BorderRadius.circular(10),
                                //   child: Image.network(
                                //     "${ApiConstants.Uploaded}${log["imageUrl"].toString()}",
                                //     height: 150,
                                //     width: double.infinity,
                                //     fit: BoxFit.cover,
                                //   ),
                                // ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: Image.network(
                                      "${ApiConstants.Uploaded}${log["imageUrl"]}",
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;

                                            return const Center(
                                              child: RotatingFlower(),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.broken_image),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

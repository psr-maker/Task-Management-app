import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/services/announ_service.dart';

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

  // ✅ FORMAT TIME
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

  // ✅ FETCH DATA
  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final data = await AnnouncementService.getDepartmentWorklogs();

      setState(() {
        worklogs = data;
        filteredLogs = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  // ✅ FILTER
  void applyFilter() {
    List<dynamic> temp = worklogs;

    if (selectedDate != null) {
      temp = temp.where((w) {
        final date = DateTime.parse(w['workDate']).toLocal();
        return date.year == selectedDate!.year &&
            date.month == selectedDate!.month &&
            date.day == selectedDate!.day;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      temp = temp.where((w) {
        return (w['userName'] ?? "").toString().toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
      }).toList();
    }

    setState(() {
      filteredLogs = temp;
    });
  }

  // ✅ GROUP BY DATE
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

  // ✅ DATE PICKER
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

  // ✅ BUILD UI
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
            : const Text("Staff Worklogs"),
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
                                      "${ApiConstants.Uploaded}${log["imageUrl"].toString().replaceFirst('/uploads/', '')}";

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageViewer(
                                        imageUrl: fullUrl,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    "${ApiConstants.Uploaded}${log["imageUrl"].toString().replaceFirst('/uploads/', '')}",
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
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

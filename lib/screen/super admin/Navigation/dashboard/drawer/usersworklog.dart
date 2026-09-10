import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
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
      data = unique.values.toList();

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

  void _showDateMonthPicker() {
    int tempYear = selectedDate?.year ?? DateTime.now().year;
    int tempMonth = selectedDate?.month ?? DateTime.now().month;
    int tempDay = selectedDate?.day ?? DateTime.now().day;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Ensure day doesn't exceed month's max days
            final maxDays = DateTime(tempYear, tempMonth + 1, 0).day;

            if (tempDay > maxDays) {
              tempDay = maxDays;
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select Date",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),

                  const SizedBox(height: 20),

                  // YEAR
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
                            .map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text("$year"),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            tempYear = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  // MONTH
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
                              DateFormat('MMMM').format(DateTime(2025, i + 1)),
                            ),
                          );
                        }),
                        onChanged: (value) {
                          setModalState(() {
                            tempMonth = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  // DAY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Day",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      DropdownButton<int>(
                        value: tempDay,
                        style: Theme.of(context).textTheme.headlineSmall,
                        items: List.generate(maxDays, (i) => i + 1).map((day) {
                          return DropdownMenuItem(
                            value: day,
                            child: Text("$day"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            tempDay = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  AppButton(
                    text: "Apply",
                    isLoading: false,
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

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
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
          IconButton(
            onPressed: _showDateMonthPicker,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: Column(
        children: [
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
                              DateFormat(
                                "yyyy-MMMM-dd",
                              ).format(DateTime.parse(date)),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          ...logs
                              .map((log) => buildTimelineItem(context, log)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildTimelineItem(BuildContext context, dynamic log) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final String workType = (log["workType"] ?? "").toString().toUpperCase();

    String displayTime = "--:--";

    if (log["time"] != null) {
      try {
        final localDateTime = TimeUtils.fromUtcIso8601(log["time"].toString());
        displayTime = DateFormat("HH:mm:ss").format(localDateTime);
      } catch (e) {
        displayTime = log["time"].toString();
      }
    }

    final bool isIn = workType == "IN";
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
                          children: [
                            // IN / OUT
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),

                              decoration: BoxDecoration(
                                color: isIn
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.orange.withOpacity(0.12),

                                borderRadius: BorderRadius.circular(7),
                              ),

                              child: Text(
                                workType.isEmpty ? "-" : workType,

                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isIn
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),

                            const Spacer(),

                            // TIME
                            Text(
                              displayTime,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 5),
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

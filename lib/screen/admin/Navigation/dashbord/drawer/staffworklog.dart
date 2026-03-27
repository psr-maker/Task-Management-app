import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
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
  bool _isLoading = false;

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

  String formatHours(double hours) {
    int h = hours.floor();
    int m = ((hours - h) * 60).round();
    return "${h}h ${m}m";
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final data = await AnnouncementService.getDepartmentWorklogs();

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

  void _showDateMonthPicker() {
    int tempYear = selectedDate?.year ?? DateTime.now().year;
    int tempMonth = selectedDate?.month ?? DateTime.now().month;
    int tempDay = selectedDate?.day ?? DateTime.now().day;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Date or Month",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // YEAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Year"),
                      DropdownButton<int>(
                        value: tempYear,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                        items: List.generate(10, (i) => DateTime.now().year - i)
                            .map(
                              (y) =>
                                  DropdownMenuItem(value: y, child: Text("$y")),
                            )
                            .toList(),
                        onChanged: (v) {
                          setModalState(() {
                            tempYear = v!;
                          });
                        },
                      ),
                    ],
                  ),

                  // MONTH
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Month"),
                      DropdownButton<int>(
                        value: tempMonth,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                        items: List.generate(12, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(0, i + 1)),
                            ),
                          );
                        }),
                        onChanged: (v) {
                          setModalState(() {
                            tempMonth = v!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // DAY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Day (optional)"),
                      DropdownButton<int>(
                        value: tempDay,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                        items:
                            List.generate(
                                  DateTime(tempYear, tempMonth + 1, 0).day,
                                  (i) => i + 1,
                                )
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text("$d"),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          setModalState(() {
                            tempDay = v!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: AppButton(
                      text: "Apply",
                      isLoading: _isLoading,
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
      },
    );
  }

  Color _getUserColor(String userName) {
    int hash = userName.hashCode;
    int r = (hash & 0xFF0000) >> 16;
    int g = (hash & 0x00FF00) >> 8;
    int b = (hash & 0x0000FF);
    return Color.fromARGB(255, r, g, b).withOpacity(0.2);
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _showDateMonthPicker,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : filteredLogs.isEmpty
          ? const Center(child: Text("No Worklogs Found"))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary,
                    ),
                    headingTextStyle: Theme.of(context).textTheme.labelLarge,
                    columns: const [
                      DataColumn(label: Text("User")),
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Title")),
                      DataColumn(label: Text("Description")),
                      DataColumn(label: Text("Start Time")),
                      DataColumn(label: Text("End Time")),
                      DataColumn(label: Text("Hours")),
                      DataColumn(label: Text("Department")),
                    ],
                    rows: filteredLogs.map((log) {
                      String userName = log["userName"] ?? "";
                      Color rowColor = _getUserColor(userName);
                      return DataRow(
                        color: MaterialStateProperty.all(
                          rowColor.withOpacity(0.1),
                        ),
                        cells: [
                          DataCell(
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          DataCell(
                            Text(
                              log["workDate"]?.split("T")[0] ?? "",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                log["title"] ?? "",
                                softWrap: true,
                                maxLines: null,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                log["description"] ?? "",
                                softWrap: true,
                                maxLines: null,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatTime(log["startTime"]),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          DataCell(
                            Text(
                              formatTime(log["endTime"]),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          DataCell(
                            Text(
                              formatHours((log["totalHours"] ?? 0).toDouble()),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          DataCell(
                            Text(
                              log["departmentName"] ?? "",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
    );
  }
}

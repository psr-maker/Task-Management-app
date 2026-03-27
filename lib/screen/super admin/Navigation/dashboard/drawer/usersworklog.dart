import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

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

  Color _getUserColor(String userName) {
    // Generate color based on user name
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
          : Padding(
              padding: const EdgeInsets.all(15),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.secondary,
                        ),
                        headingTextStyle: Theme.of(
                          context,
                        ).textTheme.labelLarge,
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
                            color: MaterialStateProperty.all(rowColor),
                            cells: [
                              DataCell(Text(userName)),
                              DataCell(
                                Text(
                                  log["workDate"]?.toString().split("T")[0] ??
                                      "",
                                ),
                              ),
                              DataCell(Text(log["title"] ?? "")),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    log["description"] ?? "",
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(AppHelpers.formatDate(log["startTime"])),
                              ),

                              DataCell(
                                Text(AppHelpers.formatDate(log["endTime"])),
                              ),

                              DataCell(
                                Text(
                                  formatHours(
                                    (log["totalHours"] ?? 0).toDouble(),
                                  ),
                                ),
                              ),
                              DataCell(Text(log["departmentName"] ?? "")),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

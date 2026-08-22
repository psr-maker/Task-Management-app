import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/leave/leaveapply.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class Leavelist extends StatefulWidget {
  const Leavelist({super.key});
  @override
  State<Leavelist> createState() => _LeavelistState();
}

class _LeavelistState extends State<Leavelist>
    with SingleTickerProviderStateMixin {
  List allItems = [];
  List filteredItems = [];
  bool isLoading = true;
  String activeTab = "Leave"; // "Leave", "Permission", "Compensation"
  late TabController _tabController;
  final tabs = ["All", "Pending", "Approved", "Rejected"];
  final permissionTabs = ["All", "Pending", "Approved", "Rejected"];
  final compensationTabs = ["All", "Pending", "Approved", "Rejected"];
  Set<int> expandedItems = {};
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  static const num clMonthlyQuota = 1;

  num clUsed = 0;
  num lopUsed = 0;
  num compUsed = 0;
  num compApprovedTotal = 0;

  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadItems();
    loadSummaryData();
    _tabController.addListener(() {
      filterItems();
    });
  }

  Future<void> loadSummaryData() async {
    setState(() => _summaryLoading = true);
    try {
      final leaves = await AdminService.getLeaves();
      final service = AdminService();
      final compensation = await service.getMyExtraWork();
      computeLeaveSummary(leaves, compensation);
    } catch (e) {
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  void computeLeaveSummary(List leaves, List compensation) {
    final now = DateTime.now();
    num cl = 0, lop = 0;

    // ---- CL & LOP: current-month count from LeaveForm rows ----
    for (var item in leaves) {
      final status = (item["status"] ?? "").toString().toLowerCase();
      if (status == "rejected") {
        continue; // rejected leave doesn't count as used
      }

      final fromDateStr = item["fromDate"];
      if (fromDateStr == null) continue;
      DateTime itemDate;
      try {
        itemDate = DateTime.parse(fromDateStr);
      } catch (_) {
        continue;
      }
      if (itemDate.year != now.year || itemDate.month != now.month) continue;

      final dayTypes = (item["leaveType"] ?? "").toString().split(",");
      final categories = (item["leaveTyp"] ?? "").toString().split(",");

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i].trim();
        if (category.isEmpty) continue;

        num weight = 1;
        if (i < dayTypes.length) {
          final dayType = dayTypes[i].trim();
          if (dayType == "First Half" || dayType == "Second Half") {
            weight = 0.5;
          }
        }

        if (category == "CL") {
          cl += weight;
        } else if (category == "LOP") {
          lop += weight;
        }
      }
    }

    final approvedComp = compensation
        .where(
          (e) => (e["status"] ?? "").toString().toLowerCase() == "approved",
        )
        .toList();

    final approvedTotal = approvedComp.length;
    final usedCount = approvedComp
        .where((e) => e["isCompensationUsed"] == true)
        .length;

    if (!mounted) return;
    setState(() {
      clUsed = cl;
      lopUsed = lop;
      compUsed = usedCount;
      compApprovedTotal = approvedTotal;
      _summaryLoading = false;
    });
  }

  String formatNum(num n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  static String formatDate(String? date) {
    if (date == null) return "";
    return DateFormat("EEE, dd MMMM").format(DateTime.parse(date));
  }

  Future<void> loadItems() async {
    setState(() {
      isLoading = true;
      allItems = [];
      filteredItems = [];
      expandedItems.clear();
    });

    try {
      List data = [];

      if (activeTab == "Leave") {
        data = await AdminService.getLeaves();
      } else if (activeTab == "Permission") {
        data = await AdminService.getPermissions();
      } else if (activeTab == "Compensation") {
        final service = AdminService();
        data = await service.getMyExtraWork();
      }

      setState(() {
        allItems = data;
        filteredItems = data;
        isLoading = false;
      });
      filterItems();
    } catch (e) {
      setState(() {
        isLoading = false;
        allItems = [];
        filteredItems = [];
      });
      showTopMessage("Error loading data: $e", isError: true);
    }
  }

  void filterItems() {
    String selected;

    if (activeTab == "Leave") {
      selected = tabs[_tabController.index];
    } else if (activeTab == "Permission") {
      selected = permissionTabs[_tabController.index];
    } else {
      selected = compensationTabs[_tabController.index];
    }

    setState(() {
      if (selected == "All") {
        filteredItems = allItems;
      } else {
        filteredItems = allItems
            .where(
              (e) =>
                  (e["status"] ?? "").toLowerCase() == selected.toLowerCase(),
            )
            .toList();
      }
    });
  }

  Map<String, List> groupByMonth(List data) {
    Map<String, List> grouped = {};
    for (var item in data) {
      final dateString = activeTab == "Compensation"
          ? item["workedDate"]
          : (item["fromDate"] ?? item["date"] ?? item["submittedDate"]);
      final date = dateString != null
          ? DateTime.parse(dateString)
          : DateTime.now();
      final key = DateFormat("MMMM yyyy").format(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTopMessage = false;
      });
    });
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty) return "-";

    try {
      List<String> parts = time.split(":");

      if (parts.length >= 2) {
        return "${parts[0]}:${parts[1]}";
      }

      return time;
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByMonth(filteredItems);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(activeTab),
        actions: [
          if (activeTab == "Leave")
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Leaveapply()),
                );

                if (result == true) {
                  loadItems(); // refresh immediately
                  loadSummaryData();
                }
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            activeTab = "Leave";
                          });
                          loadItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: activeTab == "Leave"
                                ? Colors.white24
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Leave',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            activeTab = "Permission";
                          });
                          loadItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: activeTab == "Permission"
                                ? Colors.white24
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Permission',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            activeTab = "Compensation";
                          });
                          loadItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: activeTab == "Compensation"
                                ? Colors.white24
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Compen',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              TabBar(
                controller: _tabController,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 20),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.tertiary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                tabs:
                    (activeTab == "Leave"
                            ? tabs
                            : activeTab == "Permission"
                            ? permissionTabs
                            : compensationTabs)
                        .map((e) => Tab(text: e))
                        .toList(),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : filteredItems.isEmpty
          ? Center(
              child: Text(
                activeTab == "Leave"
                    ? "No Leave Found"
                    : activeTab == "Permission"
                    ? "No Permission Found"
                    : "No Compensation Found",
              ),
            )
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (activeTab == "Leave") ...[
                      leaveSummaryCard(),
                      const SizedBox(height: 12),
                    ],
                    ...groupedData.entries.map((entry) {
                      String month = entry.key;
                      List items = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              month,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          ...items.asMap().entries.map((entry) {
                            int index = entry.key;
                            var item = entry.value;
                            return buildItem(item, index);
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                if (_topMessage != null)
                  AnimatedPositioned(
                    top: _showTopMessage ? 10 : -120,
                    left: 16,
                    right: 16,
                    duration: const Duration(milliseconds: 300),
                    child: Msgsnackbar(
                      context,
                      message: _topMessage!,
                      isError: _isErrorMessage,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget buildItem(dynamic e, int index) {
    final isPermission = activeTab == "Permission";
    final isCompensation = activeTab == "Compensation";
    final status = (e["status"] ?? "").toString().toLowerCase();
    final isExpanded = expandedItems.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedItems.remove(index);
                } else {
                  expandedItems.add(index);
                }
              });
            },
            onLongPress: () async {
              if (isPermission) {
                if (status != "pending") {
                  showTopMessage(
                    "Only pending permission can be deleted",
                    isError: true,
                  );
                  return;
                }

                final confirmed = await showConfirmDialog(
                  context,
                  "Delete",
                  "permission",
                );

                if (confirmed == true) {
                  bool success = await AdminService.deletePermission(e["id"]);

                  if (success) {
                    showTopMessage(
                      "Permission deleted successfully",
                      isError: false,
                    );
                  } else {
                    showTopMessage(
                      "Failed to delete permission",
                      isError: true,
                    );
                  }

                  await loadItems();
                }

                return;
              }
              if (!isPermission && !isCompensation && status != "pending") {
                showTopMessage(
                  "Only pending leave can be deleted",
                  isError: true,
                );
                return;
              }

              final confirmed = await showConfirmDialog(
                context,
                "Delete",
                isCompensation ? "compensation" : "leave",
              );

              if (confirmed == true) {
                final success = await AdminService.deleteLeave(e["id"]);

                if (success) {
                  showTopMessage(
                    isCompensation
                        ? "Compensation deleted successfully"
                        : "Leave deleted successfully",
                    isError: false,
                  );
                  loadItems();
                  loadSummaryData();
                } else {
                  showTopMessage(
                    isCompensation
                        ? "Failed to delete compensation"
                        : "Failed to delete leave",
                    isError: true,
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompensation
                              ? e["workType"] ?? "Work"
                              : isPermission
                              ? e["name"] ?? ""
                              : "${e["leaveType"]} - ${e["leaveTyp"]}",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isCompensation
                              ? formatDate(e["workedDate"])
                              : isPermission
                              ? formatDate(e["date"] ?? e["fromDate"])
                              : formatDate(e["fromDate"]),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        if (isPermission) ...[
                          const SizedBox(height: 4),
                          Text(
                            e["totalHours"].toString() + " hours",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ] else if (isCompensation) ...[
                          const SizedBox(height: 4),
                          Text(
                            "${formatTime(e["startTime"])} - ${formatTime(e["endTime"])}",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            "Applied on ${AppHelpers.formatDate(e["submittedDate"])}",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔽 EXPANDED CONTENT
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey.shade200),

                  if (isCompensation) ...[
                    infoRow("Work Type", e["workType"]),
                    infoRow("Date", formatDate(e["workedDate"])),
                    infoRow("From Time", formatTime(e["startTime"])),
                    infoRow("To Time", formatTime(e["endTime"])),
                    infoRow("Reason", e["reason"]),
                  ] else if (isPermission) ...[
                    infoRow("Name", e["name"]),
                    infoRow("Date", formatDate(e["date"] ?? e["fromDate"])),
                    infoRow("From Time", formatTime(e["fromTime"])),
                    infoRow("To Time", formatTime(e["toTime"])),
                    infoRow(
                      "Total Hours",
                      e["totalHours"] != null
                          ? e["totalHours"].toString() + " hours"
                          : "-",
                    ),
                    infoRow("Reason", e["reason"]),
                  ] else ...[
                    infoRow("Name", e["name"]),
                    infoRow("Designation", e["designation"]),
                    infoRow("Reason", e["reason"]),
                    infoRow("Contact", e["contactNumber"]),
                    if (e["applicationSource"] == "PermissionExceeded")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.orange.withOpacity(0.1),
                        ),
                        child: const Text(
                          "Application Source: Permission Exceeded",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),

                    if (status == "approved")
                      infoRow(
                        "Approved Date",
                        AppHelpers.formatDate(e["approvedDate"]),
                      ),

                    if (status == "rejected")
                      infoRow("Rejected Reason", e["rejectionReason"]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget leaveSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat("MMMM yyyy").format(DateTime.now()),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          _summaryLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: summaryStat("CL Leave", clUsed, clMonthlyQuota),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(child: summaryStat("LOP Leave", lopUsed, null)),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: summaryStat(
                        "Compensation",
                        compUsed,
                        compApprovedTotal,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget summaryStat(String label, num used, num? total) {
    return Column(
      children: [
        Text(
          total != null
              ? "${formatNum(used)}/${formatNum(total)}"
              : formatNum(used),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

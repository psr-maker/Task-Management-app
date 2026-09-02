import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class StaffLeaves extends StatefulWidget {
  const StaffLeaves({super.key});
  @override
  State<StaffLeaves> createState() => _StaffLeavesState();
}

class _StaffLeavesState extends State<StaffLeaves>
    with SingleTickerProviderStateMixin {
  List allItems = [];
  List filteredItems = [];
  bool isLoading = true;
  bool _isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  String activeTab =
      "Leave"; // "Leave", "Permission", "Department Compensation"

  late TabController _tabController;
  final tabs = ["All", "Pending", "Approved", "Rejected"];
  final permissionTabs = ["All", "Pending", "Approved", "Rejected"];
  final compensationTabs = ["All", "Pending", "Approved", "Rejected"];
  Set<int> expandedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadItems();
    _tabController.addListener(() {
      filterItems();
    });
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
        data = await AdminService.getDepartmentLeaves();
      } else if (activeTab == "Permission") {
        data = await AdminService.getDepartmentPermissions();
      } else if (activeTab == "Department Compensation") {
        final service = AdminService();
        data = await service.getDepartmentExtraWork();
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

  void filterItems() {
    String selected;

    if (activeTab == "Leave") {
      selected = tabs[_tabController.index];
    } else if (activeTab == "Permission") {
      selected = permissionTabs[_tabController.index];
    } else if (activeTab == "Department Compensation") {
      selected = compensationTabs[_tabController.index];
    } else {
      selected = tabs[_tabController.index];
    }

    setState(() {
      if (selected == "All") {
        filteredItems = allItems;
      } else {
        filteredItems = allItems.where((item) {
          return (item["status"] ?? "").toString().toLowerCase() ==
              selected.toLowerCase();
        }).toList();
      }
    });
  }

  Map<String, List> groupByMonth(List data) {
    Map<String, List> grouped = {};
    for (var item in data) {
      final dateString = activeTab == "Department Compensation"
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

  static String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";
    return DateFormat("EEE, dd MMMM").format(DateTime.parse(date));
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
        title: Text(activeTab),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            activeTab = "Leave";
                            _tabController.index = 0;
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
                            _tabController.index = 0;
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
                            activeTab = "Department Compensation";
                            _tabController.index = 0;
                          });
                          loadItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: activeTab == "Department Compensation"
                                ? Colors.white24
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Dept Comp.',
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
                  borderSide: const BorderSide(width: 3, color: Colors.white),
                  insets: const EdgeInsets.symmetric(horizontal: 20),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
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
                  children: groupedData.entries.map((entry) {
                    String month = entry.key;
                    List items = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            month,
                            style: Theme.of(context).textTheme.bodyMedium,
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
                ),
                if (_topMessage != null)
                  AnimatedPositioned(
                    top: _showTopMessage ? 20 : -120,
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
    final isCompensation = activeTab == "Department Compensation";
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
                              : (e["name"] ?? ""),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        if (isCompensation) ...[
                          Text(
                            formatDate(e["workedDate"]),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${formatTime(e["startTime"])} - ${formatTime(e["endTime"])}",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ] else if (isPermission) ...[
                          Text(
                            formatDate(e["date"] ?? e["fromDate"]),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            e["totalHours"].toString() + " hours",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ] else ...[
                          Text(
                            "${e["leaveType"]} - ${e["leaveTyp"]}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            formatDate(e["fromDate"] ?? e["date"]),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
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

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade200),
                  if (isCompensation) ...[
                    infoRow("Staff Name", e["staffName"] ?? "-"),
                    infoRow("Work Type", e["workType"]),
                    infoRow("Date", formatDate(e["workedDate"])),
                    infoRow("From Time", formatTime(e["startTime"])),
                    infoRow("To Time", formatTime(e["endTime"])),
                    infoRow("Reason", e["reason"]),
                    if (e["remarks"] != null &&
                        e["remarks"].toString().isNotEmpty)
                      infoRow("Remarks", e["remarks"]),
                    if (status == "pending")
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: "Approve",
                                isLoading: _isLoading,
                                onPressed: () => _handleCompensationStatus(
                                  e["id"],
                                  "approved",
                                ),
                                color: Theme.of(context).colorScheme.secondary,
                                txtcolor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppButton(
                                text: "Reject",
                                isLoading: _isLoading,
                                onPressed: () => _handleCompensationStatus(
                                  e["id"],
                                  "rejected",
                                ),
                                color: Theme.of(context).colorScheme.error,
                                txtcolor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else if (isPermission) ...[
                    infoRow("Name", e["name"]),
                    infoRow("Date", formatDate(e["date"] ?? e["fromDate"])),
                    infoRow("From Time", formatTime(e["fromTime"])),
                    infoRow("To Time", formatTime(e["toTime"])),
                    infoRow("Total Hours", e["totalHours"] ?? "-"),
                    infoRow("Reason", e["reason"]),
                    if (status == "pending") buildPermissionActionSection(e),
                  ] else ...[
                    infoRow("Name", e["name"]),
                    infoRow("Designation", e["designation"]),
                    infoRow("Reason", e["reason"]),
                    infoRow("Contact", e["contactNumber"]),
                    if (e["compensationExtraWorkId"] != null)
                      infoRow(
                        "Compensation Date",
                        AppHelpers.formatDate(
                          e["compensationWorkedDate"] ?? "-",
                        ),
                      ),
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
                    const SizedBox(height: 8),
                    if (status.toLowerCase() == "pending")
                      buildActionSection(e),
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

  Widget buildActionSection(dynamic e) {
    TextEditingController reasonController = TextEditingController();
    bool showRejectBox = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: "Approve",
                    isLoading: _isLoading,
                    onPressed: () async {
                      bool success = await AdminService.updateLeaveStatus(
                        id: e["id"],
                        status: "Approved",
                      );

                      if (success) {
                        showTopMessage(
                          "Leave approved successfully",
                          isError: false,
                        );
                      } else {
                        showTopMessage(
                          "Failed to approve leave",
                          isError: true,
                        );
                      }
                      await loadItems();
                    },
                    color: Theme.of(context).colorScheme.secondary,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    text: "Reject",
                    isLoading: _isLoading,
                    onPressed: () {
                      setState(() {
                        showRejectBox = !showRejectBox;
                      });
                    },
                    color: Theme.of(context).colorScheme.error,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),

            /// 🔴 Reject TextField
            if (showRejectBox) ...[
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                style: Theme.of(context).textTheme.headlineLarge,
                decoration: InputDecoration(
                  hintText: "Enter Rejection reason",
                  hintStyle: Theme.of(context).textTheme.labelSmall,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              AppButton(
                text: "Submit Rejection",
                isLoading: _isLoading,
                onPressed: () async {
                  bool success = await AdminService.updateLeaveStatus(
                    id: e["id"],
                    status: "Rejected",
                    reason: reasonController.text,
                  );

                  if (success) {
                    showTopMessage(
                      "Leave rejected successfully",
                      isError: false,
                    );
                  } else {
                    showTopMessage("Failed to reject leave", isError: true);
                  }
                  await loadItems();
                },
                color: Theme.of(context).colorScheme.error,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget buildPermissionActionSection(dynamic e) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: "Approve",
                isLoading: _isLoading,
                onPressed: () async {
                  bool success = await AdminService.updatePermissionStatus(
                    id: e["id"],
                    status: "Approved",
                  );

                  if (success) {
                    showTopMessage(
                      "Permission approved successfully",
                      isError: false,
                    );
                  } else {
                    showTopMessage("Failed to approve permission");
                  }

                  await loadItems();
                },
                color: Theme.of(context).colorScheme.secondary,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: AppButton(
                text: "Reject",
                isLoading: _isLoading,
                onPressed: () async {
                  bool success = await AdminService.updatePermissionStatus(
                    id: e["id"],
                    status: "Rejected",
                  );

                  if (success) {
                    showTopMessage(
                      "Permission rejected successfully",
                      isError: false,
                    );
                  } else {
                    showTopMessage("Failed to reject permission");
                  }

                  await loadItems();
                },
                color: Theme.of(context).colorScheme.error,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleCompensationStatus(int id, String status) async {
    try {
      setState(() => _isLoading = true);

      final service = AdminService();
      await service.updateExtraWorkStatus(
        id: id,
        status: status,
        remarks: null,
      );

      showTopMessage(
        "Compensation ${status == 'approved' ? 'approved' : 'rejected'} successfully",
        isError: false,
      );

      await loadItems();
    } catch (e) {
      showTopMessage("Error: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

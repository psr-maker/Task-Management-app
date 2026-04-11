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
  bool showPermissions = false;

  late TabController _tabController;
  final tabs = ["All", "Pending", "Approved", "Rejected"];
  Set<int> expandedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadItems();
    _tabController.addListener(() {
      if (!showPermissions) filterItems();
    });
  }

  Future<void> loadItems() async {
    setState(() {
      isLoading = true;
      allItems = [];
      filteredItems = [];
      expandedItems.clear();
    });

    final data = showPermissions
        ? await AdminService.getDepartmentPermissions()
        : await AdminService.getDepartmentLeaves();

    setState(() {
      allItems = data;
      filteredItems = data;
      isLoading = false;
    });
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
    String selected = tabs[_tabController.index];
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
      final dateString =
          item["fromDate"] ?? item["date"] ?? item["submittedDate"];
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

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByMonth(filteredItems);
    return Scaffold(
      appBar: AppBar(
        title: Text(showPermissions ? "Permissions" : "Leaves"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(showPermissions ? 60 : 100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (showPermissions) {
                            setState(() {
                              showPermissions = false;
                            });
                            loadItems();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: showPermissions
                                ? Colors.transparent
                                : Colors.white24,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!showPermissions) {
                            setState(() {
                              showPermissions = true;
                            });
                            loadItems();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: showPermissions
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
                  ],
                ),
              ),
              if (!showPermissions)
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
                  tabs: tabs.map((e) => Tab(text: e)).toList(),
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
                showPermissions ? "No Permission Found" : "No Leave Found",
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
    final isPermission = showPermissions;
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
                          e["name"] ?? "",
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPermission
                              ? formatDate(e["date"] ?? e["fromDate"])
                              : e["leaveType"] ?? "",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isPermission
                              ? e["totalHours"].toString() + " hours"
                              : formatDate(e["fromDate"] ?? e["date"]),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (!isPermission) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Applied on ${AppHelpers.formatDate(e["submittedDate"])}",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isPermission)
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
                  infoRow("Name", e["name"]),
                  if (isPermission) ...[
                    infoRow("Date", formatDate(e["date"] ?? e["fromDate"])),
                    infoRow("From Time", e["fromTime"]),
                    infoRow("To Time", e["toTime"]),
                    infoRow("Total Hours", e["totalHours"] ?? "-"),
                    infoRow("Reason", e["reason"]),
                  ] else ...[
                    infoRow("Designation", e["designation"]),
                    infoRow("Reason", e["reason"]),
                    infoRow("Contact", e["contactNumber"]),
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
                        await loadItems();
                      }
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
}

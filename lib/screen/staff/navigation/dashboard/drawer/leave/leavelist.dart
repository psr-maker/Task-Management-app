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
  bool showPermissions = false;
  late TabController _tabController;
  final tabs = ["All", "Pending", "Approved", "Rejected"];
  Set<int> expandedItems = {};
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadItems();
    _tabController.addListener(() {
      if (!showPermissions) filterItems();
    });
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

    final data = showPermissions
        ? await AdminService.getPermissions()
        : await AdminService.getLeaves();

    setState(() {
      allItems = data;
      filteredItems = data;
      isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByMonth(filteredItems);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(showPermissions ? "Permissions" : "Leaves"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Leaveapply()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(showPermissions ? 60 : 100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
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
            onLongPress: () async {
              if (isPermission) return; // No delete for permissions
              if (status != "pending") {
                showTopMessage(
                  "Only pending leave can be deleted",
                  isError: true,
                );
                return;
              }

              final confirmed = await showConfirmDialog(
                context,
                "Delete",
                "leave",
              );

              if (confirmed == true) {
                final success = await AdminService.deleteLeave(e["id"]);

                if (success) {
                  showTopMessage("Leave deleted successfully", isError: false);
                  loadItems(); // 🔥 refresh list
                } else {
                  showTopMessage("Failed to delete leave", isError: true);
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
                          isPermission ? e["name"] ?? "" : e["leaveType"] ?? "",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isPermission
                              ? formatDate(e["date"] ?? e["fromDate"])
                              : formatDate(e["fromDate"]),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (isPermission) ...[
                          const SizedBox(height: 4),
                          Text(
                            'From ${e["fromTime"] ?? "-"} • To ${e["toTime"] ?? "-"}',
                            style: Theme.of(context).textTheme.displaySmall,
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

          /// 🔽 EXPANDED CONTENT
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade200),

                  if (isPermission) ...[
                    infoRow("Name", e["name"]),
                    infoRow("Date", formatDate(e["date"] ?? e["fromDate"])),
                    infoRow("From Time", e["fromTime"]),
                    infoRow("To Time", e["toTime"]),
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
}

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
  List allLeaves = [];
  List filteredLeaves = [];
  bool isLoading = true;
  bool _isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  late TabController _tabController;
  final tabs = ["All", "Pending", "Approved", "Rejected"];
  Set<int> expandedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadLeaves();
    _tabController.addListener(() {
      filterLeaves();
    });
  }

  Future<void> loadLeaves() async {
    final data = await AdminService.getDepartmentLeaves();
    setState(() {
      allLeaves = data;
      filteredLeaves = data;
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

  void filterLeaves() {
    String selected = tabs[_tabController.index];
    setState(() {
      if (selected == "All") {
        filteredLeaves = allLeaves;
      } else {
        filteredLeaves = allLeaves
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
      final date = DateTime.parse(item["fromDate"]);
      final key = DateFormat("MMMM yyyy").format(date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
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
    if (date == null) return "";
    return DateFormat("EEE, dd MMMM").format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByMonth(filteredLeaves);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaves"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: Colors.white),
              insets: EdgeInsets.symmetric(horizontal: 20),
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
        ),
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : filteredLeaves.isEmpty
          ? const Center(child: Text("No Leave Found"))
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: groupedData.entries.map((entry) {
                    String month = entry.key;
                    List leaves = entry.value;

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
                        ...leaves.asMap().entries.map((entry) {
                          int index = entry.key;
                          var leave = entry.value;
                          return buildLeaveItem(leave, index);
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

  Widget buildLeaveItem(dynamic e, int index) {
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
                          e["leaveType"] ?? "",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formatDate(e["fromDate"]),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Applied on ${AppHelpers.formatDate(e["submittedDate"])}",
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
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
                children: [
                  Divider(color: Colors.grey.shade200),

                  infoRow("Name", e["name"]),
                  infoRow("Designation", e["designation"]),
                  infoRow("Reason", e["reason"]),
                  infoRow("Contact", e["contactNumber"]),
                  const SizedBox(height: 8),
                  if (status.toLowerCase() == "pending") buildActionSection(e),
                  if (status == "approved")
                    infoRow(
                      "Approved Date",
                      AppHelpers.formatDate(e["approvedDate"]),
                    ),
                  if (status == "rejected")
                    infoRow("Rejected Reason", e["rejectionReason"]),
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
                        await loadLeaves();
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
                  await loadLeaves();
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

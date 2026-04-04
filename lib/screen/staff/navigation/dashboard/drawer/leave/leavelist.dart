import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
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
  List allLeaves = [];
  List filteredLeaves = [];
  bool isLoading = true;
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

  static String formatDate(String? date) {
    if (date == null) return "";
    return DateFormat("EEE, dd MMMM").format(DateTime.parse(date));
  }

  Future<void> loadLeaves() async {
    final data = await AdminService.getLeaves();
    setState(() {
      allLeaves = data;
      filteredLeaves = data;
      isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByMonth(filteredLeaves);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Leaves"),
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
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
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
        ),
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : filteredLeaves.isEmpty
          ? const Center(child: Text("No Leave Found"))
          : ListView(
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
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/overtime/overtime_details.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class ManagerOvertimeHistory extends StatefulWidget {
  final String dept;

  const ManagerOvertimeHistory({super.key, required this.dept});

  @override
  State<ManagerOvertimeHistory> createState() => _ManagerOvertimeHistoryState();
}

class _ManagerOvertimeHistoryState extends State<ManagerOvertimeHistory> {
  bool loading = true;

  List<dynamic> allData = [];
  List<dynamic> filteredStaff = [];

  String searchQuery = "";

  // Search AppBar
  bool searchOpen = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadHistory() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final data = await OvertimeService.getDepartmentOvertime();

      if (!mounted) return;

      allData = List<dynamic>.from(data);

      _buildStaffList();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        allData = [];
        filteredStaff = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load overtime history: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  void _buildStaffList() {
    final Map<String, Map<String, dynamic>> staffMap = {};

    for (final item in allData) {
      final uid = item["uid"]?.toString();

      if (uid == null || uid.isEmpty) {
        continue;
      }

      final staffName = item["staffName"]?.toString().trim().isNotEmpty == true
          ? item["staffName"].toString().trim()
          : "Unknown Staff";

      if (searchQuery.isNotEmpty &&
          !staffName.toLowerCase().contains(searchQuery)) {
        continue;
      }
      if (!staffMap.containsKey(uid)) {
        staffMap[uid] = {
          "uid": uid,
          "staffName": staffName,
          "count": 0,
          "records": <dynamic>[],
        };
      }

      staffMap[uid]!["count"] = (staffMap[uid]!["count"] as int) + 1;

      (staffMap[uid]!["records"] as List<dynamic>).add(item);
    }

    final List<dynamic> temp = staffMap.values.toList();

    // Sort alphabetically
    temp.sort((a, b) {
      final nameA = a["staffName"].toString().toLowerCase();

      final nameB = b["staffName"].toString().toLowerCase();

      return nameA.compareTo(nameB);
    });

    if (!mounted) return;

    setState(() {
      filteredStaff = temp;
    });
  }

  void _searchStaff(String value) {
    searchQuery = value.trim().toLowerCase();

    _buildStaffList();
  }

  void _toggleSearch() {
    setState(() {
      searchOpen = !searchOpen;

      if (!searchOpen) {
        searchController.clear();
        searchQuery = "";
        _buildStaffList();
      }
    });
  }

  Future<void> _openStaffHistory(dynamic staff) async {
    final uid = staff["uid"]?.toString();

    if (uid == null || uid.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerOvertimeDetails(
          staffId: uid,
          staffName: staff["staffName"]?.toString() ?? "Staff",
        ),
      ),
    );

    if (!mounted) return;

    await loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: searchOpen
            ? TextField(
                controller: searchController,
                autofocus: true,
                onChanged: _searchStaff,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.teal,
                decoration: const InputDecoration(
                  hintText: "Search staff",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              )
            : const Text("Overtime History"),

        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(searchOpen ? Icons.close : Icons.search),
          ),

          // if (!searchOpen)
          //   IconButton(onPressed: loadHistory, icon: const Icon(Icons.refresh)),
        ],
      ),

      body: loading
          ? const Center(child: RotatingFlower())
          : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(15),
            children: [
              if (filteredStaff.isEmpty)
                _buildEmptyState()
              else
                ...filteredStaff.map((staff) => _buildStaffCard(staff)),
            ],
          ),
    );
  }

  Widget _buildStaffCard(dynamic staff) {
    final staffName = staff["staffName"]?.toString() ?? "Unknown Staff";

    final count = int.tryParse(staff["count"]?.toString() ?? "") ?? 0;

    return Material(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openStaffHistory(staff),
        child: Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  staffName.isNotEmpty ? staffName[0].toUpperCase() : "?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
    
              const SizedBox(width: 15),
    
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
    
                    const SizedBox(height: 8),
    
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$count overtime "
                        "${count == 1 ? 'record' : 'records'}",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    
              const SizedBox(width: 8),
    
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 450,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.history,
              size: 60,
              color: Colors.grey.shade700,
            ),

            const SizedBox(height: 16),

            Text(
              searchQuery.isNotEmpty
                  ? "No staff found"
                  : "No overtime history found",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              searchQuery.isNotEmpty
                  ? "Try another staff name."
                  : "Overtime records will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

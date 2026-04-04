import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
// import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class Empgoals extends StatefulWidget {
  final String department;

  const Empgoals({super.key, required this.department});

  @override
  State<Empgoals> createState() => _EmpgoalsState();
}

class _EmpgoalsState extends State<Empgoals> {
  final TaskFilterModel taskFilter = TaskFilterModel();
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  bool showFilter = false;
  bool isLoading = true;
  List<dynamic> goals = [];
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  List<dynamic> applyGoalSearch(List<dynamic> goals) {
    List<dynamic> filtered = goals;

    // SEARCH
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();

      filtered = filtered.where((goal) {
        final title = (goal["title"] ?? "").toString().toLowerCase();
        final code = (goal["goalCode"] ?? "").toString().toLowerCase();
        final department = (goal["department"] ?? "").toString().toLowerCase();
        final status = (goal["status"] ?? "").toString().toLowerCase();
        final priority = (goal["priority"] ?? "").toString().toLowerCase();

        return title.contains(query) ||
            code.contains(query) ||
            department.contains(query) ||
            status.contains(query) ||
            priority.contains(query);
      }).toList();
    }

    // // STATUS FILTER
    // if (taskFilter.status != null && taskFilter.status!.isNotEmpty) {
    //   filtered = filtered.where((goal) {
    //     return (goal["status"] ?? "").toString().toLowerCase() ==
    //         taskFilter.status!.toLowerCase();
    //   }).toList();
    // }

    // // PRIORITY FILTER
    // if (taskFilter.priority != null && taskFilter.priority!.isNotEmpty) {
    //   filtered = filtered.where((goal) {
    //     return (goal["priority"] ?? "").toString().toLowerCase() ==
    //         taskFilter.priority!.toLowerCase();
    //   }).toList();
    // }

    // // DEPARTMENT FILTER
    // if (taskFilter.department != null && taskFilter.department!.isNotEmpty) {
    //   filtered = filtered.where((goal) {
    //     return (goal["department"] ?? "").toString().toLowerCase() ==
    //         taskFilter.department!.toLowerCase();
    //   }).toList();
    // }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      final result = await AdminService.getGoalsByDepartment(widget.department);

      setState(() {
        goals = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
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
      setState(() => _showTopMessage = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredGoals = applyGoalSearch(goals);

    return Scaffold(
      body: isLoading
          ? const Center(child: RotatingFlower())
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: isSearching
                                ? TextField(
                                    controller: searchController,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: "Search goals...",
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      setState(() => searchQuery = value);
                                    },
                                  )
                                : Text(
                                    "All Staff Goal List",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                          ),

                          /// 🔍 SEARCH ICON
                          IconButton(
                            icon: Icon(
                              isSearching ? Icons.close : Icons.search,
                            ),
                            onPressed: () {
                              setState(() {
                                isSearching = !isSearching;
                                searchController.clear();
                                searchQuery = "";
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// 📋 GOALS LIST
                      Expanded(
                        child: filteredGoals.isEmpty
                            ? const Center(child: Text("No Goals Found"))
                            : ListView.builder(
                                itemCount: filteredGoals.length,
                                itemBuilder: (context, index) {
                                  final goal = filteredGoals[index];
                                  return GoalCard(
                                    goal: goal,
                                    onDelete: (msg, isError) {
                                      showTopMessage(msg, isError: isError);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (_topMessage != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: _showTopMessage ? 40 : -120,
                    left: 16,
                    right: 16,
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
}

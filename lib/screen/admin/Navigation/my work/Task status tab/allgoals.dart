import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class Allgoals extends StatefulWidget {
  final String searchQuery;
  final TaskFilterModel? filter;
  final Function(String, bool)? onDelete;

  const Allgoals({
    super.key,
    required this.searchQuery,
    this.filter,
    this.onDelete,
  });

  @override
  State<Allgoals> createState() => _AllgoalsState();
}

class _AllgoalsState extends State<Allgoals> {
  List goals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      final data = await SuperAdminService.getGoals();

      setState(() {
        goals = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// FILTER LOGIC
  List get filteredGoals {
    String normalize(String value) {
      return value.toLowerCase().replaceAll(" ", "").replaceAll("_", "");
    }

    return goals.where((goal) {
      /// SEARCH
      if (widget.searchQuery.isNotEmpty &&
          !(goal["title"] ?? "").toString().toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          )) {
        return false;
      }

      /// STATUS FILTER
      if (widget.filter?.status != null && widget.filter!.status!.isNotEmpty) {
        final goalStatus = normalize((goal["status"] ?? "").toString());
        final filterStatus = normalize(widget.filter!.status!);

        if (goalStatus != filterStatus) return false;
      }

      /// PRIORITY FILTER
      if (widget.filter?.priority != null &&
          (goal["priority"] ?? "").toString().toLowerCase() !=
              widget.filter!.priority!.toLowerCase()) {
        return false;
      }

      /// DEPARTMENT FILTER
      if (widget.filter?.department != null &&
          (goal["department"] ?? "").toString().toLowerCase() !=
              widget.filter!.department!.toLowerCase()) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }

    if (filteredGoals.isEmpty) {
      return const Center(
        child: Text(
          "No goals found",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredGoals.length,
      itemBuilder: (context, index) {
        return GoalCard(
          goal: filteredGoals[index],
          onDelete: widget.onDelete,
          onRefresh: loadGoals,
        );
      },
    );
  }
}

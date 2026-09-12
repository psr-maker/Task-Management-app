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
  final Set<String> _removedGoalCodes = {};

  @override
  void initState() {
    super.initState();
    loadGoals(showLoader: true);
  }

  Future<void> loadGoals({bool showLoader = false}) async {
    try {
      if (showLoader && mounted) setState(() => isLoading = true);
      final data = await SuperAdminService.getGoals();
      if (!mounted) return;
      setState(() {
        goals = data.where((goal) {
          final code = (goal["goalCode"] ?? "").toString();
          return !_removedGoalCodes.contains(code);
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
        final goal = filteredGoals[index];
        final goalCode =
            (goal["goalCode"] ?? goal["GoalCode"] ?? "").toString().trim();
        return GoalCard(
          key: ValueKey(goalCode),
          goal: goal,
          onDelete: (msg, isError) {
            if (!isError) {
              setState(() {
                if (goalCode.isNotEmpty) _removedGoalCodes.add(goalCode);
                goals = goals
                    .where(
                      (item) =>
                          (item["goalCode"] ?? item["GoalCode"] ?? "")
                              .toString()
                              .trim() !=
                          goalCode,
                    )
                    .toList();
              });
            }
            widget.onDelete?.call(msg, isError);
          },
          onRefresh: () => loadGoals(),
        );
      },
    );
  }
}

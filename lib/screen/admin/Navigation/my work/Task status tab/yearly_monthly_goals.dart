import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/utils/goal_task_enrich.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/adaptive_goal_cards.dart';

class YearlyMonthlyGoalsPage extends StatefulWidget {
  final Map<String, dynamic> yearlyGoal;
  final List<Map<String, dynamic>> monthlyGoals;
  final Function(String, bool)? onDelete;
  final VoidCallback? onRefresh;

  const YearlyMonthlyGoalsPage({
    super.key,
    required this.yearlyGoal,
    required this.monthlyGoals,
    this.onDelete,
    this.onRefresh,
  });

  @override
  State<YearlyMonthlyGoalsPage> createState() => _YearlyMonthlyGoalsPageState();
}

class _YearlyMonthlyGoalsPageState extends State<YearlyMonthlyGoalsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _loadingProgress = true;
  late List<Map<String, dynamic>> _months;

  @override
  void initState() {
    super.initState();
    _months = widget.monthlyGoals.map(_prepareMonth).toList();
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant YearlyMonthlyGoalsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.monthlyGoals, widget.monthlyGoals)) {
      _months = widget.monthlyGoals.map(_prepareMonth).toList();
      _loadProgress();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _prepareMonth(Map<String, dynamic> month) {
    month["goalType"] = "Monthly";
    if (month["monthlyGoals"] is! List) {
      month["monthlyGoals"] = <Map<String, dynamic>>[];
    }
    if (month["tasks"] is! List) month["tasks"] = [];
    return month;
  }

  Future<void> _loadProgress() async {
    if (mounted) setState(() => _loadingProgress = true);
    await Future.wait(_months.map(enrichGoalTaskQuantities));
    syncGoalTreeProgress(widget.yearlyGoal);
    if (!mounted) return;
    setState(() => _loadingProgress = false);
  }

  bool _matchesSearch(Map<String, dynamic> month) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final title = (month["title"] ?? month["Title"] ?? "").toString();
    final code = (month["goalCode"] ?? month["GoalCode"] ?? "").toString();
    return title.toLowerCase().contains(query) ||
        code.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.yearlyGoal["title"] ?? "Yearly goal").toString();
    final isWeb = !AppLayout.isMobile(context);
    final months = _months.where(_matchesSearch).toList();

    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: "Search monthly goal",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: _isSearching ? "Close search" : "Search monthly goal",
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: widget.monthlyGoals.isEmpty
          ? const Center(
              child: Text(
                "No monthly goals under this yearly goal",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )
          : _loadingProgress
              ? const Center(child: RotatingFlower())
              : Padding(
                  padding: isWeb
                      ? AppLayout.pagePadding(context)
                      : const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Monthly goals (${months.length})",
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap a monthly goal to see its tasks",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: months.isEmpty
                            ? Center(
                                child: Text(
                                  "No monthly goal matches \"${_searchController.text.trim()}\"",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : AdaptiveGoalCards(
                                itemCount: months.length,
                                itemBuilder: (context, index) {
                                  final month = months[index];
                                  final code =
                                      (month["goalCode"] ?? month["GoalCode"] ?? "")
                                          .toString();
                                  return GoalCard(
                                    key: ValueKey(
                                      code.isEmpty ? 'month-$index' : code,
                                    ),
                                    goal: month,
                                    onDelete: widget.onDelete,
                                    onRefresh: () async {
                                      widget.onRefresh?.call();
                                      await _loadProgress();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

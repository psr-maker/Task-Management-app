import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> month) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final title = (month["title"] ?? month["Title"] ?? "").toString();
    final code = (month["goalCode"] ?? month["GoalCode"] ?? "").toString();
    return title.toLowerCase().contains(query) ||
        code.toLowerCase().contains(query);
  }

  Widget _quantityHeader(
    BuildContext context,
    GoalQuantityView quantity,
    int assigned,
  ) {
    final percentColor = quantity.percent >= 100
        ? const Color(0xFF1B7A3A)
        : const Color(0xFFB45309);
    final unassigned = quantity.target - assigned;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Achieved ${formatGoalQty(quantity.done)} of ${formatGoalQty(quantity.target)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            formatQuantityPercent(quantity.percent),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: percentColor,
            ),
          ),
          if (assigned > 0 && unassigned > 0) ...[
            const SizedBox(height: 2),
            Text(
              "${formatGoalQty(unassigned)} is not split into a month yet.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _figure("Target", formatGoalQty(quantity.target)),
              _figure("Achieved", formatGoalQty(quantity.done)),
              _figure(
                "Percent",
                formatQuantityPercent(quantity.percent),
                percentColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: quantity.fraction,
              backgroundColor: Colors.grey.shade300,
              color: percentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _figure(String label, String value, [Color? color]) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _monthlyCard(Map<String, dynamic> month) {
    final copy = Map<String, dynamic>.from(month);
    copy["goalType"] = "Monthly";
    copy["monthlyGoals"] = <Map<String, dynamic>>[];
    if (copy["tasks"] is! List) copy["tasks"] = [];
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.yearlyGoal["title"] ?? "Yearly goal").toString();
    final isWeb = !AppLayout.isMobile(context);
    final months = widget.monthlyGoals
        .where(_matchesSearch)
        .map(_monthlyCard)
        .toList();
    final quantity = goalQuantityView(
      widget.yearlyGoal,
      months: widget.monthlyGoals,
      preferMonthTotals: true,
    );
    final assigned = monthTargetTotal(widget.monthlyGoals);

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
          : Padding(
              padding: isWeb
                  ? AppLayout.pagePadding(context)
                  : const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // if (quantity != null) ...[
                  //   _quantityHeader(context, quantity, assigned),
                  //   const SizedBox(height: 16),
                  // ],
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
                              return GoalCard(
                                goal: month,
                                onDelete: widget.onDelete,
                                onRefresh: widget.onRefresh,
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

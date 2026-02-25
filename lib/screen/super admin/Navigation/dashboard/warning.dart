import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/overduetask.dart';

class Warning extends StatefulWidget {
  final List<Map<String, dynamic>> overdueTasks;
  const Warning({super.key, required this.overdueTasks});

  @override
  State<Warning> createState() => _WarningState();
}

class _WarningState extends State<Warning> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Overdue Tasks"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            widget.overdueTasks.isEmpty
                ? const Center(child: Text("No overdue tasks"))
                : OverdueTaskList(overdueTasks: widget.overdueTasks),
          ],
        ),
      ),
    );
  }
}

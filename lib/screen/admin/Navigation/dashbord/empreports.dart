// import 'package:flutter/material.dart';
// import 'package:staff_work_track/Models/table.dart';
// import 'package:staff_work_track/core/widgets/buttons.dart';
// import 'package:staff_work_track/core/widgets/loading.dart';
// import 'package:staff_work_track/services/reports_service.dart';
// import 'package:staff_work_track/utils/TaskUtils.dart';

// class empReportsTable extends StatefulWidget {
//   final int? userId;
//   final String? department;

//   const empReportsTable({super.key, this.userId, this.department});

//   @override
//   State<empReportsTable> createState() => _DeadlineReportsTabState();
// }

// class _DeadlineReportsTabState extends State<empReportsTable> {
//   final ReportsService _service = ReportsService();
//   bool _isLoading = false;
//   List<ReportTask> allTasks = [];
//   List<ReportTask> filteredTasks = [];

//   String? selectedStatus;
//   String? selectedPriority;
//   String? selectedOverdue;

//   DateTime? startDate;
//   DateTime? endDate;

//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchTasks();
//   }

//   Future<void> fetchTasks() async {
//     try {
//       final tasks = await _service.getFilteredTasks(
//         userId: widget.userId,
//         department: widget.department,
//       );

//       setState(() {
//         allTasks = tasks;
//         filteredTasks = tasks;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void applyFilters() {
//     setState(() {
//       filteredTasks = allTasks.where((task) {
//         if (selectedStatus != null &&
//             task.status.toLowerCase() != selectedStatus!.toLowerCase()) {
//           return false;
//         }

//         if (selectedPriority != null &&
//             task.priority.toLowerCase() != selectedPriority!.toLowerCase()) {
//           return false;
//         }

//         if (selectedOverdue != null) {
//           bool overdueValue = selectedOverdue == "Yes";
//           if (task.isOverdue != overdueValue) {
//             return false;
//           }
//         }

//         // 🔥 DATE FILTER
//         if (startDate != null && endDate != null) {

//           if (task.createdAt.isBefore(startDate!) ||
//               task.createdAt.isAfter(endDate!)) {
//             return false;
//           }
//         }

//         return true;
//       }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text("Reports Table"),

//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_alt),
//             onPressed: () {
//               showModalBottomSheet(
//                 context: context,
//                 isScrollControlled: true,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                 ),
//                 builder: (context) {
//                   return StatefulBuilder(
//                     builder: (context, modalSetState) {
//                       return buildFilterSheet(modalSetState);
//                     },
//                   );
//                 },
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.date_range_outlined),
//             onPressed: () async {
//               final picked = await showDateRangePicker(
//                 context: context,
//                 firstDate: DateTime(2020),
//                 lastDate: DateTime.now(),
//                 initialDateRange: startDate != null && endDate != null
//                     ? DateTimeRange(start: startDate!, end: endDate!)
//                     : null,
//               );

//               if (picked != null) {
//                 setState(() {
//                   startDate = picked.start;
//                   endDate = picked.end;
//                   applyFilters();
//                 });
//               }
//             },
//           ),

//           // ✅ SHOW CLEAR ICON ONLY WHEN DATE SELECTED
//           if (startDate != null && endDate != null)
//             IconButton(
//               icon: const Icon(Icons.clear),
//               onPressed: () {
//                 setState(() {
//                   startDate = null;
//                   endDate = null;
//                   applyFilters();
//                 });
//               },
//             ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: RotatingFlower())
//           : Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// 🔹 FILTER CHIPS SECTION
//                 if (selectedStatus != null ||
//                     selectedPriority != null ||
//                     selectedOverdue != null)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     child: Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: [
//                         if (selectedStatus != null)
//                           _buildFilterChip("Status: $selectedStatus", () {
//                             setState(() {
//                               selectedStatus = null;
//                               applyFilters();
//                             });
//                           }),

//                         if (selectedPriority != null)
//                           _buildFilterChip("Priority: $selectedPriority", () {
//                             setState(() {
//                               selectedPriority = null;
//                               applyFilters();
//                             });
//                           }),

//                         if (selectedOverdue != null)
//                           _buildFilterChip("Overdue: $selectedOverdue", () {
//                             setState(() {
//                               selectedOverdue = null;
//                               applyFilters();
//                             });
//                           }),
//                       ],
//                     ),
//                   ),

//                 /// 🔹 TABLE SECTION
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: filteredTasks.isEmpty
//                         ? Center(
//                             child: Text(
//                               "No data available",
//                               style: Theme.of(context).textTheme.displaySmall,
//                             ),
//                           )
//                         : Card(
//                             elevation: 4,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(16),
//                               child: SingleChildScrollView(
//                                 scrollDirection: Axis.horizontal,
//                                 child: SingleChildScrollView(
//                                   child: DataTable(
//                                     headingTextStyle: Theme.of(
//                                       context,
//                                     ).textTheme.labelLarge,

//                                     dataTextStyle: Theme.of(
//                                       context,
//                                     ).textTheme.headlineSmall,

//                                     headingRowHeight: 50,
//                                     dataRowMinHeight: 45,
//                                     headingRowColor: MaterialStateProperty.all(
//                                       Theme.of(context).colorScheme.primary,
//                                     ),
//                                     columns: const [
//                                       DataColumn(label: Text("User")),

//                                       DataColumn(label: Text("Task")),

//                                       DataColumn(label: Text("Status")),
//                                       DataColumn(label: Text("Priority")),

//                                       DataColumn(label: Text("Start Date")),
//                                       DataColumn(label: Text("Due Date")),
//                                     ],
//                                     rows: filteredTasks.map((task) {
//                                       return DataRow(
//                                         cells: [
//                                           DataCell(Text(task.name)),

//                                           DataCell(Text(task.task)),

//                                           DataCell(
//                                             Text(
//                                               task.status,
//                                               style: TextStyle(
//                                                 color: TaskUtils.getStatusColor(
//                                                   TaskUtils.parseStatus(
//                                                     task.status,
//                                                   ),
//                                                 ),
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),
//                                           DataCell(
//                                             Text(
//                                               task.priority,
//                                               style: TextStyle(
//                                                 color:
//                                                     TaskUtils.getPriorityColor(
//                                                       task.priority,
//                                                     ),
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),

//                                           DataCell(
//                                             Text(
//                                               task.createdAt.toString().split(
//                                                     " ",
//                                                   )[0],
//                                             ),
//                                           ),
//                                           DataCell(
//                                             Text(
//                                               task.dueDate.toString().split(
//                                                     " ",
//                                                   )[0],
//                                             ),
//                                           ),
//                                         ],
//                                       );
//                                     }).toList(),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }

//   Widget _buildFilterChip(String label, VoidCallback onDelete) {
//     return Chip(
//       label: Text(label),
//       deleteIcon: const Icon(Icons.close),
//       onDeleted: onDelete,
//     );
//   }

//   Widget buildFilterSheet(void Function(void Function()) modalSetState) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// 🔹 STATUS
//             _buildHeading("Status"),
//             const SizedBox(height: 12),
//             _buildChoiceChips(
//               values: [
//                 "Not Started",
//                 "InProgress",
//                 "Completed",
//                 "Pending",
//                 "Pause",
//               ],
//               selectedValue: selectedStatus,
//               activeColor: Colors.blue,
//               modalSetState: modalSetState,
//               onSelected: (value) {
//                 selectedStatus = selectedStatus == value ? null : value;
//                 applyFilters();
//               },
//             ),

//             const SizedBox(height: 24),

//             /// 🔹 PRIORITY
//             _buildHeading("Priority"),
//             const SizedBox(height: 12),
//             _buildChoiceChips(
//               values: ["Normal", "Medium", "High"],
//               selectedValue: selectedPriority,
//               activeColor: Colors.orange,
//               modalSetState: modalSetState,
//               onSelected: (value) {
//                 selectedPriority = selectedPriority == value ? null : value;
//                 applyFilters();
//               },
//             ),

//             const SizedBox(height: 24),

//             /// 🔹 OVERDUE
//             _buildHeading("Overdue"),
//             const SizedBox(height: 12),
//             _buildChoiceChips(
//               values: ["Yes", "No"],
//               selectedValue: selectedOverdue,
//               activeColor: Colors.red,
//               modalSetState: modalSetState,
//               onSelected: (value) {
//                 selectedOverdue = selectedOverdue == value ? null : value;
//                 applyFilters();
//               },
//             ),

//             const SizedBox(height: 30),

//             Center(
//               child: AppButton(
//                 text: "Clear Filters",
//                 isLoading: _isLoading,
//                 onPressed: () {
//                   modalSetState(() {
//                     selectedStatus = null;
//                     selectedPriority = null;
//                     selectedOverdue = null;
//                   });

//                   applyFilters();
//                 },
//                 color: Theme.of(context).colorScheme.secondary,
//                 txtcolor: Theme.of(context).colorScheme.onPrimary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeading(String title) {
//     return Text(title, style: Theme.of(context).textTheme.headlineMedium);
//   }

//   Widget _buildChoiceChips({
//     required List<String> values,
//     required String? selectedValue,
//     required Color activeColor,
//     required void Function(void Function()) modalSetState,
//     required Function(String) onSelected,
//   }) {
//     return Wrap(
//       spacing: 10,
//       runSpacing: 10,
//       children: values.map((value) {
//         final isSelected = selectedValue == value;

//         return ChoiceChip(
//           label: Text(value),
//           selected: isSelected,
//           onSelected: (_) {
//             modalSetState(() {
//               onSelected(value);
//             });
//           },
//           selectedColor: activeColor,
//           backgroundColor: Colors.grey.shade200,
//           labelStyle: TextStyle(
//             color: isSelected ? Colors.white : Colors.black87,
//             fontWeight: FontWeight.w600,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: isSelected ? 4 : 0,
//           shadowColor: activeColor.withOpacity(0.4),
//         );
//       }).toList(),
//     );
//   }
// }

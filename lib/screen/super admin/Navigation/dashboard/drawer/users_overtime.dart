import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';

class UsersOverTime extends StatefulWidget {
  const UsersOverTime({super.key});

  @override
  State<UsersOverTime> createState() => _UsersOverTimeState();
}

class _UsersOverTimeState extends State<UsersOverTime> {
  bool isLoading = true;

  String selectedDepartment = "All";
  DateTimeRange? selectedDateRange;

  List<dynamic> allOvertimes = [];
  List<dynamic> filteredOvertimes = [];
  List<String> departments = ["All"];

  double get totalRegularHours => 8.0;
  double get totalTime => totalRegularHours + totalOvertimeHours;
  bool isDownloading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadOvertimes();
  }

  Future<void> loadOvertimes() async {
    try {
      final data = await getApprovedOvertimes();

      allOvertimes = data;

      final depts = data.map((e) => e["dept"].toString()).toSet().toList();

      departments = ["All", ...depts];

      filteredOvertimes = data;

      setState(() {
        isLoading = false;
      });

      applyFilters();
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<dynamic>> getApprovedOvertimes() async {
    return await AdminService.getApprovedOvertimes();
  }

  void applyFilters() {
    List<dynamic> temp = List.from(allOvertimes);

    if (selectedDepartment != "All") {
      temp = temp.where((item) {
        return item["dept"] == selectedDepartment;
      }).toList();
    }

    if (selectedDateRange != null) {
      temp = temp.where((item) {
        final overtimeDate = DateTime.parse(item["date"].toString());

        return overtimeDate.isAfter(
              selectedDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            overtimeDate.isBefore(
              selectedDateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    setState(() {
      filteredOvertimes = temp;
    });
  }

  Future<void> selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });

      applyFilters();
    }
  }

  double get totalOvertimeHours {
    return filteredOvertimes.fold(0.0, (sum, item) => sum + item["totalHours"]);
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty) return "";

    try {
      final parsed = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("h:mm a").format(parsed);
    } catch (e) {
      return time;
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

  Future<void> _downloadPdfReport() async {
    try {
      setState(() => isDownloading = true);

      final pdf = pw.Document();

      final groupedDepartments = <String, List<dynamic>>{};

      for (var item in filteredOvertimes) {
        groupedDepartments
            .putIfAbsent(item["dept"].toString(), () => [])
            .add(item);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Text(
              "Overtime Summary Report",
              style: pw.TextStyle(fontSize: 22),
            ),

            pw.SizedBox(height: 10),

            pw.Text("Department : $selectedDepartment"),

            if (selectedDateRange != null)
              pw.Text(
                "${DateFormat('dd-MM-yyyy').format(selectedDateRange!.start)}"
                " to "
                "${DateFormat('dd-MM-yyyy').format(selectedDateRange!.end)}",
              ),

            pw.SizedBox(height: 20),

            ...groupedDepartments.entries.map((entry) {
              final department = entry.key;
              final employees = entry.value;

              final overtimeHours = employees.fold<double>(
                0,
                (sum, e) => sum + ((e["totalHours"] ?? 0).toDouble()),
              );

              const regularHours = 8.0;
              final totalHours = regularHours + overtimeHours;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.grey200,
                    child: pw.Text(
                      department,
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(border: pw.Border.all()),
                        child: pw.Text(
                          "Regular Time : ${regularHours.toStringAsFixed(1)} hrs",
                        ),
                      ),

                      pw.SizedBox(width: 10),

                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(border: pw.Border.all()),
                        child: pw.Text(
                          "Overtime : ${overtimeHours.toStringAsFixed(1)} hrs",
                        ),
                      ),

                      pw.SizedBox(width: 10),

                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(border: pw.Border.all()),
                        child: pw.Text(
                          "Total Time : ${totalHours.toStringAsFixed(1)} hrs",
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 12),

                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          _pdfCell("Name"),
                          _pdfCell("Date"),
                          _pdfCell("From - To"),
                          _pdfCell("Hours"),
                          _pdfCell("Reason"),
                        ],
                      ),

                      ...employees.map<pw.TableRow>((e) {
                        return pw.TableRow(
                          children: [
                            _pdfCell(e["name"]?.toString() ?? "-"),
                            _pdfCell(
                              DateFormat(
                                "dd-MM-yyyy",
                              ).format(DateTime.parse(e["date"].toString())),
                            ),
                            _pdfCell(
                              "${formatTime(e["fromTime"]?.toString())} - ${formatTime(e["toTime"]?.toString())}",
                            ),
                            _pdfCell("${e["totalHours"] ?? 0} hrs"),
                            _pdfCell(e["reason"]?.toString() ?? "-"),
                          ],
                        );
                      }),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      );

      final saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      final file = File(
        "${saveDir.path}/Overtime_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      showTopMessage("Download successfully", isError: false);
    } catch (e) {
      debugPrint("PDF Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedDepartments = <String, List<dynamic>>{};

    for (var item in filteredOvertimes) {
      groupedDepartments
          .putIfAbsent(item["dept"].toString(), () => [])
          .add(item);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("OverTime History"),
        actions: [
          isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _downloadPdfReport,
                ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              setState(() {
                selectedDepartment = value;
              });

              applyFilters();
            },
            itemBuilder: (context) {
              return departments.map((dept) {
                return PopupMenuItem<String>(
                  value: dept,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dept,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      if (selectedDepartment == dept)
                        Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 18,
                        ),
                    ],
                  ),
                );
              }).toList();
            },
          ),

          IconButton(
            onPressed: selectDateRange,
            icon: const Icon(Icons.calendar_month),
          ),

          if (selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  selectedDateRange = null;
                });

                applyFilters();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : Stack(
              children: [
                Column(
                  children: [
                    /// Filter Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Theme.of(context).colorScheme.background,
                      child: Text(
                        selectedDateRange == null
                            ? "Department : $selectedDepartment"
                            : "Department : $selectedDepartment\n\n"
                                  "${DateFormat('dd-MM-yyyy').format(selectedDateRange!.start)}"
                                  " to "
                                  "${DateFormat('dd-MM-yyyy').format(selectedDateRange!.end)}",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// Summary Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              "Regular Time",
                              "${totalRegularHours.toStringAsFixed(1)} hrs",
                              Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              "Overtime",
                              "${totalOvertimeHours.toStringAsFixed(1)} hrs",
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              "Total Time",
                              "${totalTime.toStringAsFixed(1)} hrs",
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: groupedDepartments.isEmpty
                          ? const Center(child: Text("No Overtime Records"))
                          : ListView.builder(
                              itemCount: groupedDepartments.length,
                              itemBuilder: (context, index) {
                                final department = groupedDepartments.keys
                                    .elementAt(index);

                                final employees =
                                    groupedDepartments[department]!;

                                return _buildDepartmentSection(
                                  department,
                                  employees,
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (_topMessage != null)
                  AnimatedPositioned(
                    top: _showTopMessage ? 0 : -120,
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

  Widget _buildDepartmentSection(String department, List<dynamic> employees) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(department, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),

          //const Divider(thickness: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18, // default is around 56
              horizontalMargin: 10,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              headingRowHeight: 42,
              headingRowColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.background,
              ),
              columns: [
                DataColumn(
                  label: Text(
                    "Name",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Date",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                DataColumn(
                  label: Text(
                    "From-To",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Hours",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Reason",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ],
              rows: employees.map<DataRow>((e) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        e["name"].toString(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat(
                          "dd-MM-yyyy",
                        ).format(DateTime.parse(e["date"].toString())),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        "${formatTime(e["fromTime"]?.toString())} - ${formatTime(e["toTime"]?.toString())}",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        "${e["totalHours"]} hrs",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          e["reason"] ?? "",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

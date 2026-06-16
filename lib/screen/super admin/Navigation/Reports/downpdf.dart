import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class EmployeeReportPdfGenerator {
  final int? userId;
  final String? username;
  final String? department;
  final int reportYear;

  final Map<String, dynamic> summaryData;
  final List<dynamic> monthlyData;
  final List<dynamic> warnings;

  final double completionPercentage;
  final double onTimePercentage;
  final double delayedGoalPercent;

  final Map<String, dynamic> reportData;

  // New fields for top and low performers
  final Map<String, dynamic>? topPerformer;
  final Map<String, dynamic>? lowPerformer;

  EmployeeReportPdfGenerator({
    this.userId,
    this.username,
    this.department,
    required this.reportYear,
    required this.summaryData,
    required this.monthlyData,
    required this.warnings,
    required this.completionPercentage,
    required this.onTimePercentage,
    required this.delayedGoalPercent,
    required this.reportData,
    this.topPerformer,
    this.lowPerformer,
  });

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  /// Build PDF Cell
  pw.Widget _buildCell(String text, pw.Font? font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );
  }

  pw.Widget _cell(String text, {pw.Font? font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );
  }

  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.storage.isGranted) return true;

    final status = await Permission.storage.request();
    if (status.isGranted) return true;

    final manageStatus = await Permission.manageExternalStorage.request();
    return manageStatus.isGranted;
  }

  Future<void> generateAndDownloadPDF() async {
    final pdf = pw.Document();

    final boldFont = await PdfGoogleFonts.notoSansBold();
    String reportTitle;
    final totalGoals = summaryData["totalGoals"] ?? 0;
    final totalTasks = summaryData["totalTasks"] ?? 0;
    if (username != null && username!.isNotEmpty) {
      reportTitle = "$username Reports - $reportYear";
    } else if (department != null && department!.isNotEmpty) {
      reportTitle = "$department Reports - $reportYear";
    } else {
      reportTitle = "Reports - $reportYear";
    }
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          /// TITLE
          pw.Text(
            reportTitle,
            style: pw.TextStyle(font: boldFont, fontSize: 22),
          ),
          pw.SizedBox(height: 20),

          /// SUMMARY TABLE
          pw.Text(
            "Goal & Task Summary",
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.Divider(),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              pw.TableRow(
                children: [
                  _cell("Total Goals", font: boldFont),
                  _cell("$totalGoals"),
                  _cell("Total Tasks", font: boldFont),
                  _cell("$totalTasks"),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell("Completed Goals", font: boldFont),
                  _cell("${summaryData["completedGoals"] ?? 0}"),
                  _cell("Completed Tasks", font: boldFont),
                  _cell("${summaryData["completedTasks"] ?? 0}"),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell("Pending Goals", font: boldFont),
                  _cell("${summaryData["pendingGoals"] ?? 0}"),
                  _cell("Pending Tasks", font: boldFont),
                  _cell("${summaryData["pendingTasks"] ?? 0}"),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell("Overdue Goals", font: boldFont),
                  _cell("${summaryData["overdueGoals"] ?? 0}"),
                  _cell("Overdue Tasks", font: boldFont),
                  _cell("${summaryData["overdueTasks"] ?? 0}"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          /// KPI
          pw.Text(
            "Performance",
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.Divider(),

          pw.Text("Completion: $completionPercentage%"),
          pw.Text("On-Time: $onTimePercentage%"),
          pw.Text("Delayed: $delayedGoalPercent%"),

          pw.SizedBox(height: 20),

          /// MONTHLY
          pw.Text(
            "Monthly Productivity",
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.Divider(),

          pw.Column(
            children: monthlyData.map<pw.Widget>((item) {
              final month = item["month"];
              final m = month is int
                  ? month
                  : int.tryParse(month.toString()) ?? 1;

              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_getMonthName(m)),
                  pw.Text("${item["productivity"] ?? 0}%"),
                ],
              );
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          /// PERFORMANCE METRICS (TOP & LOW PERFORMERS)
          if (topPerformer != null || lowPerformer != null) ...[
            pw.Text(
              "Performance Metrics",
              style: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            pw.Divider(),

            if (topPerformer != null) ...[
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Top Performer",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text("Name: ${topPerformer!["user"] ?? "-"}"),
                    pw.Text(
                      "Completed Tasks: ${topPerformer!["completedTasks"] ?? 0}",
                    ),
                    pw.Text("Total Tasks: ${topPerformer!["totalTasks"] ?? 0}"),
                    if (topPerformer!["totalTasks"] != null &&
                        topPerformer!["totalTasks"] > 0)
                      pw.Text(
                        "Completion Rate: ${((topPerformer!["completedTasks"] ?? 0) / topPerformer!["totalTasks"] * 100).round()}%",
                      ),
                  ],
                ),
              ),
            ],

            if (lowPerformer != null) ...[
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Low Performer",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
                        color: PdfColors.red,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text("Name: ${lowPerformer!["user"] ?? "-"}"),
                    pw.Text(
                      "Completed Tasks: ${lowPerformer!["completedTasks"] ?? 0}",
                    ),
                    pw.Text("Total Tasks: ${lowPerformer!["totalTasks"] ?? 0}"),
                    if (lowPerformer!["totalTasks"] != null &&
                        lowPerformer!["totalTasks"] > 0)
                      pw.Text(
                        "Completion Rate: ${((lowPerformer!["completedTasks"] ?? 0) / lowPerformer!["totalTasks"] * 100).round()}%",
                      ),
                  ],
                ),
              ),
            ],
          ],

          pw.SizedBox(height: 20),

          /// WARNINGS (FIXED FORMAT)
          if (warnings.isNotEmpty) ...[
            pw.Text(
              "Warnings",
              style: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            pw.Divider(),
            pw.Column(
              children: warnings.map((w) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      /// 🔴 TITLE + SEVERITY
                      pw.Text(
                        "${w.title} - ${w.severity}",
                        style: pw.TextStyle(font: boldFont, fontSize: 14),
                      ),
                      pw.SizedBox(height: 5),

                      /// 📝 DESCRIPTION
                      pw.Text(w.message),

                      pw.SizedBox(height: 5),

                      /// 📅 DATE (with leading zeros)
                      pw.Text(
                        "${w.createdDate.day.toString().padLeft(2, '0')}/"
                        "${w.createdDate.month.toString().padLeft(2, '0')}/"
                        "${w.createdDate.year}",
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    // 🔹 ADD GOALS TABLE PAGE
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            "GOALS REPORT",
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 15),

          pw.Table(
            border: pw.TableBorder.all(width: 1, color: PdfColors.black),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
              6: const pw.FlexColumnWidth(1),
              7: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildCell("Goal", boldFont),
                  _buildCell("Status", boldFont),
                  _buildCell("Priority", boldFont),
                  _buildCell("Due Date", boldFont),
                  _buildCell("Completed Date", boldFont),
                  _buildCell("Progress", boldFont),
                  _buildCell("Points", boldFont),
                  _buildCell("Overdue", boldFont),
                ],
              ),

              ...(reportData["goals"] as List? ?? []).map((goal) {
                return pw.TableRow(
                  children: [
                    _buildCell(goal["title"]?.toString() ?? "-", null),
                    _buildCell(goal["status"]?.toString() ?? "-", null),
                    _buildCell(goal["priority"]?.toString() ?? "-", null),

                    _buildCell(
                      AppHelpers.formatDate(goal["dueDate"]?.toString() ?? "-"),
                      null,
                    ),

                    _buildCell(
                      AppHelpers.formatDate(
                        goal["completed_Date"]?.toString() ?? "-",
                      ),
                      null,
                    ),

                    _buildCell("${goal["progress"] ?? 0}%", null),
                    _buildCell("${goal["points"] ?? 0}", null),

                    _buildCell(
                      (goal["isOverdue"] == true) ? "Yes" : "No",
                      null,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    // 🔹 ADD TASKS TABLE PAGE
    if ((reportData["tasks"] as List?)?.isNotEmpty ?? false) {
      pdf.addPage(
        pw.MultiPage(
          // ✅ CHANGE HERE
          build: (context) {
            return [
              pw.Text(
                "TASKS REPORT",
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(1),
                },
                children: [
                  /// HEADER
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildCell("Task", boldFont),
                      _buildCell("Status", boldFont),
                      _buildCell("Priority", boldFont),
                      _buildCell("Due Date", boldFont),
                      _buildCell("Completed Date", boldFont),
                      _buildCell("Points", boldFont),
                      _buildCell("Overdue", boldFont),
                    ],
                  ),

                  /// DATA
                  ...(reportData["tasks"] as List).map((task) {
                    return pw.TableRow(
                      children: [
                        _buildCell(task["task"]?.toString() ?? "-", null),
                        _buildCell(task["status"]?.toString() ?? "-", null),
                        _buildCell(task["priority"]?.toString() ?? "-", null),
                        _buildCell(
                          AppHelpers.formatDate(
                            task["due_Date"]?.toString() ?? "-",
                          ),
                          null,
                        ),
                        _buildCell(
                          AppHelpers.formatDate(
                            task["completed_Date"]?.toString() ?? "-",
                          ),
                          null,
                        ),
                        _buildCell((task["points"] ?? 0).toString(), null),
                        _buildCell(
                          (task["isOverdue"] == true) ? "Yes" : "No",
                          null,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );
    }

    if ((reportData["leaveList"] as List?)?.isNotEmpty ?? false) {
      pdf.addPage(
        pw.MultiPage(
          // ✅ CHANGE HERE
          build: (context) {
            return [
              pw.Text(
                "LEAVE REPORT",
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(1),
                  7: const pw.FlexColumnWidth(1),
                },
                children: [
                  /// HEADER
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildCell("Leave Type", boldFont),
                      _buildCell("Reason", boldFont),
                      _buildCell("Date", boldFont),
                      _buildCell("Submitted Date", boldFont),
                      _buildCell("Status", boldFont),
                      _buildCell("Reject Reason", boldFont),
                      _buildCell("Approved Date", boldFont),
                      _buildCell("Contact Number", boldFont),
                    ],
                  ),

                  /// DATA
                  ...(reportData["leaveList"] as List).map((leave) {
                    return pw.TableRow(
                      children: [
                        _buildCell(leave["type"]?.toString() ?? "-", null),
                        _buildCell(leave["reason"]?.toString() ?? "-", null),
                        _buildCell(
                          AppHelpers.formatDate(
                            leave["fromDate"]?.toString() ?? "-",
                          ),
                          null,
                        ),
                        _buildCell(
                          AppHelpers.formatDate(
                            leave["submdate"]?.toString() ?? "-",
                          ),
                          null,
                        ),
                        _buildCell((leave["status"] ?? "-").toString(), null),
                        _buildCell(
                          (leave["rejreason"] ?? "-").toString(),
                          null,
                        ),
                        _buildCell(
                          AppHelpers.formatDate(
                            leave["approvedate"]?.toString() ?? "-",
                          ),
                          null,
                        ),
                        _buildCell(leave["contactno"]?.toString() ?? "-", null),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );
    }
    if ((reportData["permissionList"] as List?)?.isNotEmpty ?? false) {
      pdf.addPage(
        pw.MultiPage(
          // ✅ CHANGE HERE
          build: (context) {
            return [
              pw.Text(
                "PERMISSION REPORT",
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(1),
                  7: const pw.FlexColumnWidth(1),
                  8: const pw.FlexColumnWidth(1),
                },
                children: [
                  /// HEADER
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildCell("Reason", boldFont),
                      _buildCell("Date", boldFont),
                      _buildCell("From Time", boldFont),
                      _buildCell("To Time", boldFont),
                      _buildCell("Total Hours", boldFont),
                      _buildCell("Submitted Date", boldFont),
                      _buildCell("Status", boldFont),
                    ],
                  ),

                  /// DATA
                  ...(reportData["permissionList"] as List).map((permission) {
                    return pw.TableRow(
                      children: [
                        _buildCell(
                          permission["reason"]?.toString() ?? "-",
                          null,
                        ),
                        _buildCell(
                          AppHelpers.formatDate(
                            permission["date"]?.toString() ?? "-",
                          ),
                          null,
                        ),
                        _buildCell(
                          (permission["fromTime"] ?? "-").toString(),
                          null,
                        ),
                        _buildCell(
                          (permission["toTime"] ?? "-").toString(),
                          null,
                        ),
                        _buildCell(
                          permission["totalhours"]?.toString() ?? "-",
                          null,
                        ),
                        _buildCell(
                          AppHelpers.formatDate(
                            permission["submdate"]?.toString() ?? "-",
                          ),
                          null,
                        ),
                        _buildCell(
                          (permission["status"] ?? "-").toString(),
                          null,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );
    }

    /// ✅ Save + Download
    final saveDir = await _getSaveDirectory();
    final file = File(
      "${saveDir.path}/employee_report_${userId ?? DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    try {
      await file.writeAsBytes(await pdf.save());
      print("PDF Saved at: ${file.path}");
    } catch (e) {
      final granted = await _ensureStoragePermission();
      if (!granted) {
        print("Permission Denied");
        return;
      }

      final retryDir = await _getSaveDirectory();
      final retryFile = File(
        "${retryDir.path}/employee_report_${userId ?? DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await retryFile.writeAsBytes(await pdf.save());
      print("PDF Saved at: ${retryFile.path}");
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

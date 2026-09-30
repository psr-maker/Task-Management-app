import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportExport {
  static Future<String> saveExcel({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final row in rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Excel file could not be created');
    }
    final name = _fileName(title, 'xlsx');
    final data = Uint8List.fromList(bytes);
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel',
        fileName: name,
        bytes: data,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (saved == null || saved.isEmpty) return '';
      return name;
    }

    final file = await _writeLocal(name, data);
    await OpenFile.open(
      file.path,
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    return file.path;
  }

  static Future<String> savePdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final name = _fileName(title, 'pdf');
    final file = await _writeLocal(name, bytes);
    await OpenFile.open(file.path, type: 'application/pdf');
    return file.path;
  }

  static Future<File> _writeLocal(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _fileName(String title, String extension) {
    final safe = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '${safe}_$stamp.$extension';
  }
}

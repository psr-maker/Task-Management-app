import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:excel/excel.dart' hide TextSpan;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' hide Border, BorderStyle;
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
    final widths = _excelColumnWidths(headers, rows);
    final grid = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('FFD1D5DB'),
    );
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('FF166534'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: grid,
      rightBorder: grid,
      topBorder: grid,
      bottomBorder: grid,
    );
    final bodyStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: grid,
      rightBorder: grid,
      topBorder: grid,
      bottomBorder: grid,
    );
    final shadedStyle = bodyStyle.copyWith(
      backgroundColorHexVal: ExcelColor.fromHexString('FFF3F4F6'),
    );

    _writeExcelRow(
      sheet,
      rowIndex: 0,
      values: headers,
      columnCount: headers.length,
      widths: widths,
      style: headerStyle,
    );
    for (var index = 0; index < rows.length; index++) {
      _writeExcelRow(
        sheet,
        rowIndex: index + 1,
        values: rows[index],
        columnCount: headers.length,
        widths: widths,
        style: index.isOdd ? shadedStyle : bodyStyle,
      );
    }
    for (var column = 0; column < widths.length; column++) {
      sheet.setColumnWidth(column, widths[column]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Excel file could not be created');
    }
    return _deliver(
      name: _fileName(title, 'xlsx'),
      data: Uint8List.fromList(bytes),
      dialogTitle: 'Save Excel',
      extensions: const ['xlsx'],
      openMime:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
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

    return _deliver(
      name: _fileName(title, 'pdf'),
      data: await pdf.save(),
      dialogTitle: 'Save PDF',
      extensions: const ['pdf'],
      openMime: 'application/pdf',
    );
  }

  static Future<String> saveImage({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    return _deliver(
      name: _fileName(title, 'png'),
      data: await _tablePng(title: title, headers: headers, rows: rows),
      dialogTitle: 'Save image',
      extensions: const ['png'],
      openMime: 'image/png',
    );
  }

  static Future<String> _deliver({
    required String name,
    required Uint8List data,
    required String dialogTitle,
    required List<String> extensions,
    required String openMime,
  }) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: name,
        bytes: data,
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (saved == null || saved.isEmpty) return '';
      return name;
    }

    final file = await _writeLocal(name, data);
    await OpenFile.open(file.path, type: openMime);
    return file.path;
  }

  static Future<Uint8List> _tablePng({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    const maxRows = 200;
    const scale = 2.0;
    const pad = 16.0;
    const cellPad = 8.0;
    const rowHeight = 36.0;
    final shown = rows.length > maxRows ? rows.take(maxRows).toList() : rows;
    final note = rows.length > maxRows
        ? 'Showing the first $maxRows of ${rows.length} records. Use PDF or Excel for the full list.'
        : '';

    double measure(String text, double size, FontWeight weight, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: weight),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: maxWidth);
      return painter.width;
    }

    final widths = <double>[];
    for (var column = 0; column < headers.length; column++) {
      var width = measure(headers[column], 12, FontWeight.w700, 240) + cellPad * 2;
      for (final row in shown) {
        final value = column < row.length ? row[column] : '';
        width = math.max(
          width,
          measure(value, 11, FontWeight.w500, 240) + cellPad * 2,
        );
      }
      widths.add(width.clamp(72, 220));
    }
    final tableWidth = widths.fold<double>(0, (sum, width) => sum + width);
    final width = math.max(tableWidth + pad * 2, 360.0);
    final height = pad + 28 + (note.isEmpty ? 0 : 22) + rowHeight * (shown.length + 1) + pad;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    void paintText(
      String text,
      Offset offset,
      double maxWidth, {
      required double size,
      required FontWeight weight,
      required Color color,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: weight, color: color),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      painter.paint(canvas, offset);
    }

    paintText(
      title,
      const Offset(pad, pad),
      width - pad * 2,
      size: 16,
      weight: FontWeight.w800,
      color: const Color(0xFF111827),
    );
    var top = pad + 28;
    if (note.isNotEmpty) {
      paintText(
        note,
        Offset(pad, top),
        width - pad * 2,
        size: 11,
        weight: FontWeight.w500,
        color: const Color(0xFF6B7280),
      );
      top += 22;
    }

    void paintRow(List<String> cells, double y, {required bool header, Color? fill}) {
      var x = pad;
      for (var column = 0; column < widths.length; column++) {
        final rect = Rect.fromLTWH(x, y, widths[column], rowHeight);
        canvas.drawRect(
          rect,
          Paint()
            ..color = header
                ? const Color(0xFF166534)
                : (fill ?? const Color(0xFFFFFFFF)),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6
            ..color = const Color(0xFFD1D5DB),
        );
        paintText(
          column < cells.length ? cells[column] : '',
          Offset(x + cellPad, y + 10),
          widths[column] - cellPad * 2,
          size: header ? 12 : 11,
          weight: header ? FontWeight.w700 : FontWeight.w500,
          color: header ? const Color(0xFFFFFFFF) : const Color(0xFF1F2937),
        );
        x += widths[column];
      }
    }

    paintRow(headers, top, header: true);
    for (var index = 0; index < shown.length; index++) {
      paintRow(
        shown[index],
        top + rowHeight * (index + 1),
        header: false,
        fill: index.isOdd ? const Color(0xFFF3F4F6) : const Color(0xFFFFFFFF),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (width * scale).ceil(),
      (height * scale).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw Exception('Image file could not be created');
    }
    return bytes.buffer.asUint8List();
  }

  static List<double> _excelColumnWidths(
    List<String> headers,
    List<List<String>> rows,
  ) {
    final widths = <double>[];
    for (var column = 0; column < headers.length; column++) {
      var longest = headers[column].trim().length;
      for (final row in rows) {
        if (column >= row.length) continue;
        for (final line in row[column].split('\n')) {
          final length = line.trim().length;
          if (length > longest) longest = length;
        }
      }
      // Excel width is in characters. Size the column to its text, the same
      // way the on-screen table does, instead of the default narrow width.
      widths.add((longest + 3).clamp(12, 48).toDouble());
    }
    return widths;
  }

  static void _writeExcelRow(
    Sheet sheet, {
    required int rowIndex,
    required List<String> values,
    required int columnCount,
    required List<double> widths,
    required CellStyle style,
  }) {
    var lines = 1;
    for (var column = 0; column < columnCount; column++) {
      final text = column < values.length ? values[column] : '';
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
        TextCellValue(text),
        cellStyle: style,
      );
      final fitted = math.max(8, widths[column].floor() - 2);
      final needed = text.trim().isEmpty ? 1 : (text.trim().length / fitted).ceil();
      if (needed > lines) lines = needed;
    }
    sheet.setRowHeight(rowIndex, (18.0 * lines).clamp(22, 96));
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

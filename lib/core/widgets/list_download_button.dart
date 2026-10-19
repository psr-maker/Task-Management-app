import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/report_export.dart';

class ListDownloadButton extends StatefulWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> Function() rows;
  final bool onAppBar;

  const ListDownloadButton({
    super.key,
    required this.title,
    required this.headers,
    required this.rows,
    this.onAppBar = false,
  });

  @override
  State<ListDownloadButton> createState() => _ListDownloadButtonState();
}

class _ListDownloadButtonState extends State<ListDownloadButton> {
  bool _busy = false;

  Future<void> _save(String kind) async {
    if (_busy) return;
    final rows = widget.rows();
    if (rows.isEmpty) {
      _message('No rows to download');
      return;
    }
    setState(() => _busy = true);
    try {
      final path = switch (kind) {
        'excel' => await ReportExport.saveExcel(
          title: widget.title,
          headers: widget.headers,
          rows: rows,
        ),
        'image' => await ReportExport.saveImage(
          title: widget.title,
          headers: widget.headers,
          rows: rows,
        ),
        _ => await ReportExport.savePdf(
          title: widget.title,
          headers: widget.headers,
          rows: rows,
        ),
      };
      if (!mounted || path.isEmpty) return;
      _message('Download saved');
    } catch (e) {
      if (!mounted) return;
      _message('Download failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Download',
      color: WebTheme.brand,
      onSelected: _save,
      icon: Icon(
        Icons.download_rounded,
        color: widget.onAppBar ? null : WebTheme.brand,
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'pdf',
          child: _Choice(icon: Icons.picture_as_pdf_rounded, label: 'PDF'),
        ),
        PopupMenuItem(
          value: 'excel',
          child: _Choice(icon: Icons.table_view_rounded, label: 'Excel'),
        ),
        PopupMenuItem(
          value: 'image',
          child: _Choice(icon: Icons.image_outlined, label: 'Image'),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Choice({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

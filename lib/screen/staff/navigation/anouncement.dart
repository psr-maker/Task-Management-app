import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/responsive_body.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Anouncestaff extends StatefulWidget {
  const Anouncestaff({super.key});

  @override
  State<Anouncestaff> createState() => _AnounceState();
}

class _AnounceState extends State<Anouncestaff> {
  late Future<List<Announcement>> futureAnnouncements;

  @override
  void initState() {
    super.initState();
    futureAnnouncements = AnnouncementService.fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: WebTheme.brand,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Official Notices",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<Announcement>>(
        future: futureAnnouncements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (snapshot.hasError) return const AppLoadError();
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'No announcements',
              message: 'New notices will appear here.',
            );
          }
          final announcements = snapshot.data ?? [];
          return ResponsiveWrapList(
            padding: AppLayout.pagePadding(context),
            columnsForWidth: _webColumns,
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return _announcementCard(announcements[index]);
            },
          );
        },
      ),
    );
  }

  static int _webColumns(double width) {
    if (width >= 1320) return 5;
    if (width >= 1040) return 4;
    return 3;
  }

  Widget _announcementCard(Announcement item) {
    final typeColor = WebTheme.brandOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: WebTheme.brandOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.fileType.toUpperCase(),
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${TimeUtils.formatDateValue(item.createdDate)}  •  ${item.createdBy}',
            style: TextStyle(
              fontSize: 12,
              color: WebTheme.mutedOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.description != null && item.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.description!,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: WebTheme.brandOf(context),
              ),
            ),
          ],
          if (_hasMedia(item)) ...[
            const SizedBox(height: 12),
            _buildMediaSection(item),
          ],
        ],
      ),
    );
  }

  Widget _buildExcelTable(String jsonData) {
    List<dynamic> rows = jsonDecode(jsonData);

    if (rows.isEmpty) {
      return const Text("No Data Available");
    }

    List<String> headers = (rows[0] as Map<String, dynamic>).keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(WebTheme.brand),

        dataRowColor: WidgetStateProperty.all(WebTheme.brandSoftOf(context)),

        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),

        dataTextStyle: TextStyle(
          color: WebTheme.brandOf(context),
          fontSize: 13,
        ),

        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),

        rows: rows.asMap().entries.map((entry) {
          int index = entry.key;
          var row = entry.value;

          return DataRow(
            color: WidgetStateProperty.all(
              index.isEven
                  ? WebTheme.surfaceOf(context)
                  : WebTheme.brandSoftOf(context),
            ),
            cells: headers
                .map((h) => DataCell(Text(row[h]?.toString() ?? "")))
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  bool _hasMedia(Announcement item) {
    final path = item.filePath?.trim() ?? '';
    final data = item.jsonData?.trim() ?? '';
    return path.isNotEmpty || data.isNotEmpty;
  }

  String _kind(Announcement item) {
    final hint =
        '${item.fileType} ${item.fileName ?? ''} ${item.filePath ?? ''}'
            .toLowerCase();
    if (hint.contains('image') ||
        hint.contains('.png') ||
        hint.contains('.jpg') ||
        hint.contains('.jpeg') ||
        hint.contains('.webp') ||
        hint.contains('.gif')) {
      return 'image';
    }
    if (hint.contains('pdf')) return 'pdf';
    if (hint.contains('excel') ||
        hint.contains('xls') ||
        hint.contains('csv') ||
        (item.jsonData?.trim().isNotEmpty ?? false)) {
      return 'excel';
    }
    return item.fileType.toLowerCase();
  }

  Widget _fileRow(Announcement item, {required IconData icon, required Color color}) {
    return GestureDetector(
      onTap: () async {
        final path = item.filePath;
        if (path == null || path.trim().isEmpty) return;
        final url = '${ApiConstants.Uploaded}$path';
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WebTheme.brandSoftOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.fileName ?? item.filePath!.split('/').last,
                style: TextStyle(
                  color: WebTheme.brandOf(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.open_in_new, color: WebTheme.brandOf(context), size: 18),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(Announcement item) {
    final kind = _kind(item);
    final path = item.filePath?.trim() ?? '';
    if (kind == 'image' && path.isNotEmpty) {
      final imageUrl = '${ApiConstants.Uploaded}$path';
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
            ),
          );
        },
        child: Hero(
          tag: imageUrl,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WebTheme.brandOf(context), width: 1.4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fileRow(
                item,
                icon: Icons.image_outlined,
                color: WebTheme.brandOf(context),
              ),
            ),
          ),
        ),
        ),
      );
    }

    if (kind == 'excel' && (item.jsonData?.trim().isNotEmpty ?? false)) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.28)),
        ),
        child: _buildExcelTable(item.jsonData!),
      );
    }

    if (path.isNotEmpty) {
      final icon = kind == 'pdf'
          ? Icons.picture_as_pdf
          : kind == 'excel'
              ? Icons.table_chart
              : Icons.insert_drive_file_outlined;
      return _fileRow(item, icon: icon, color: WebTheme.brandOf(context));
    }

    return const SizedBox.shrink();
  }
}

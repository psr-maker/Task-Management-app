import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
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
      appBar: AppBar(title: const Text("Official Notices")),
      body: FutureBuilder<List<Announcement>>(
        future: futureAnnouncements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }

          if (snapshot.hasError) {
            return const AppLoadError();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'No announcements',
              message: 'New notices will appear here.',
            );
          }

          final announcements = snapshot.data ?? [];

          return ListView.separated(
            padding: AppLayout.pagePadding(context),
            itemCount: announcements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _announcementCard(announcements[index]);
            },
          );
        },
      ),
    );
  }

  Widget _announcementCard(Announcement item) {
    final typeColor = _getTypeColor(item.fileType);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
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
                    color: WebTheme.inkOf(context),
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
                color: WebTheme.inkOf(context),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildMediaSection(item),
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
        headingRowColor: MaterialStateProperty.all(
          Theme.of(context).colorScheme.primary,
        ),

        dataRowColor: MaterialStateProperty.resolveWith<Color?>((
          Set<MaterialState> states,
        ) {
          return Colors.green.shade50;
        }),

        headingTextStyle: Theme.of(context).textTheme.labelLarge,

        dataTextStyle: Theme.of(context).textTheme.labelMedium,

        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),

        rows: rows.asMap().entries.map((entry) {
          int index = entry.key;
          var row = entry.value;

          return DataRow(
            color: MaterialStateProperty.all(
              index % 2 == 0
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.tertiary,
            ),
            cells: headers
                .map((h) => DataCell(Text(row[h]?.toString() ?? "")))
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaSection(Announcement item) {
    if (item.fileType == "image" && item.filePath != null) {
      final imageUrl = "${ApiConstants.Uploaded}${item.filePath}";

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    if (item.fileType == "pdf" && item.filePath != null) {
      return GestureDetector(
        onTap: () async {
          final url = "${ApiConstants.Uploaded}${item.filePath}";
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WebTheme.brandSoftOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: WebTheme.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.fileName ?? item.filePath!.split('/').last,
                  style: TextStyle(
                    color: WebTheme.inkOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(Icons.open_in_new, color: WebTheme.mutedOf(context)),
            ],
          ),
        ),
      );
    }

    if (item.fileType == "excel" && item.jsonData != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WebTheme.lineOf(context)),
        ),
        child: _buildExcelTable(item.jsonData!),
      );
    }

    return const SizedBox();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case "image":
        return Colors.blue;
      case "pdf":
        return Colors.red;
      case "excel":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

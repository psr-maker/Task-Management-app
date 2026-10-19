import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/responsive_body.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/postanounce.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Anounce extends StatefulWidget {
  const Anounce({super.key});

  @override
  State<Anounce> createState() => _AnounceState();
}

class _AnounceState extends State<Anounce> {
  late Future<List<Announcement>> futureAnnouncements;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    futureAnnouncements = AnnouncementService.fetchAnnouncements();
  }

  Future<void> deleteAnnouncement(int id) async {
    try {
      await AnnouncementService.deleteAnnouncement(id);
      showTopMessage("Announcement deleted", isError: false);

      setState(() {
        futureAnnouncements = AnnouncementService.fetchAnnouncements();
      });
    } catch (e) {
      showTopMessage("Delete failed", isError: true);
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

  Future<void> _openComposer() async {
    final result = await openFormPage(
      context,
      const PostAnnouncementPage(),
      maxWidth: 640,
    );
    if (result == true && mounted) {
      setState(() {
        futureAnnouncements = AnnouncementService.fetchAnnouncements();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final web = !AppLayout.isMobile(context);
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: WebTheme.brand,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: web
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          "Announcements",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _openComposer,
          ),
        ],
      ),

      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<Announcement>>(
                future: futureAnnouncements,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: RotatingFlower());
                  }
                  if (snapshot.hasError) {
                    return const Expanded(child: AppLoadError());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Expanded(
                      child: AppEmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'No announcements',
                        message: 'New notices will appear here.',
                      ),
                    );
                  }

                  final announcements = snapshot.data ?? [];

                  return Expanded(
                    child: ResponsiveWrapList(
                      padding: AppLayout.pagePadding(context),
                      columnsForWidth: _webColumns,
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final item = announcements[index];
                        return _announcementCard(
                          item,
                          onLongPress: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              "Delete",
                              "Anouncement",
                            );
                            if (confirmed == true) {
                              deleteAnnouncement(item.id);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 40 : -120,
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

  static int _webColumns(double width) {
    if (width >= 1320) return 5;
    if (width >= 1040) return 4;
    return 3;
  }

  Widget _announcementCard(
    Announcement item, {
    required VoidCallback onLongPress,
  }) {
    final typeColor = WebTheme.brandOf(context);
    final showDelete = !AppLayout.isMobile(context);
    return Material(
      color: WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                  if (showDelete)
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onLongPress,
                      icon: Icon(Icons.delete_outline, color: WebTheme.danger),
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
              if (item.description != null &&
                  item.description!.trim().isNotEmpty) ...[
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
        ),
      ),
    );
  }

  Widget _buildSimpleList(String jsonData) {
    List<dynamic> rows = jsonDecode(jsonData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            row.values.first.toString(),
            style: TextStyle(fontSize: 13, color: WebTheme.brandOf(context)),
          ),
        );
      }).toList(),
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

  Widget _fileRow(
    Announcement item, {
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () async {
        final path = item.filePath;
        if (path == null || path.trim().isEmpty) return;
        await launchUrl(
          Uri.parse('${ApiConstants.Uploaded}$path'),
          mode: LaunchMode.externalApplication,
        );
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
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(Announcement item) {
    final kind = _kind(item);
    final path = item.filePath?.trim() ?? '';
    final pieces = <Widget>[];
    if (kind == 'image' && path.isNotEmpty) {
      final imageUrl = '${ApiConstants.Uploaded}$path';
      pieces.add(
        GestureDetector(
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
        ),
      );
    } else if (path.isNotEmpty) {
      final icon = kind == 'pdf'
          ? Icons.picture_as_pdf
          : kind == 'excel'
              ? Icons.table_chart
              : Icons.insert_drive_file_outlined;
      pieces.add(_fileRow(item, icon: icon, color: WebTheme.brandOf(context)));
    }
    if (kind == 'excel' && (item.jsonData?.trim().isNotEmpty ?? false)) {
      pieces.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WebTheme.brandSoftOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.28)),
          ),
          child: _buildSimpleList(item.jsonData!),
        ),
      );
    }
    if (pieces.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < pieces.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          pieces[i],
        ],
      ],
    );
  }
}

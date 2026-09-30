import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Announcements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostAnnouncementPage()),
              );

              if (result == true) {
                setState(() {
                  futureAnnouncements =
                      AnnouncementService.fetchAnnouncements();
                });
              }
            },
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
                    child: ListView.separated(
                      padding: AppLayout.pagePadding(context),
                      itemCount: announcements.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
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

  Widget _announcementCard(
    Announcement item, {
    required VoidCallback onLongPress,
  }) {
    final typeColor = _getTypeColor(item.fileType);
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
              if (item.description != null &&
                  item.description!.trim().isNotEmpty) ...[
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
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMediaSection(Announcement item) {
    if (item.fileType == "image" && item.filePath != null) {
      final imageUrl =
        "${ApiConstants.Uploaded}${item.filePath}";
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
          final pdfurl =
              "${ApiConstants.Uploaded}${item.filePath.toString()}";
          await launchUrl(
            Uri.parse(pdfurl),
            mode: LaunchMode.externalApplication,
          );
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
          color: WebTheme.brandSoftOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WebTheme.lineOf(context)),
        ),
        child: _buildSimpleList(item.jsonData!),
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

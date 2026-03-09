import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/postanounce.dart';
import 'package:staff_work_track/services/announ_service.dart';
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

  Future<void> confirmDelete(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement"),
        content: const Text("Are you sure you want to delete this?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      deleteAnnouncement(id);
    }
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
            children: [
              FutureBuilder<List<Announcement>>(
                future: futureAnnouncements,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: RotatingFlower());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No Anouncement available"),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  final announcements = snapshot.data ?? [];

                  return Expanded(
                    child: ListView.builder(
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final item = announcements[index];

                        return GestureDetector(
                          onLongPress: () {
                            confirmDelete(item.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                            Theme.of(
                                              context,
                                            ).colorScheme.background,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 2,
                                      height: 120,
                                      color: Colors.grey.shade300,
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.headlineLarge,
                                              ),
                                            ),

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getTypeColor(
                                                  item.fileType,
                                                ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                item.fileType.toUpperCase(),
                                                style: TextStyle(
                                                  color: _getTypeColor(
                                                    item.fileType,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${item.createdDate.toLocal()}"
                                                  .split(' ')[0],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.person,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.createdBy,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        if (item.description != null)
                                          Text(
                                            item.description!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          ),

                                        const SizedBox(height: 14),

                                        _buildMediaSection(item),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                iconColor: Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
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
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.fileName ?? item.filePath!.split('/').last,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.open_in_new, color: Colors.red.shade600),
            ],
          ),
        ),
      );
    }

    if (item.fileType == "excel" && item.jsonData != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
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

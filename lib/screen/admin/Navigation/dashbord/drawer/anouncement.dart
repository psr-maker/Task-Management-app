import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
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

  @override
  void initState() {
    super.initState();
    futureAnnouncements = AnnouncementService.fetchAnnouncements();
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostAnnouncementPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Announcement>>(
        future: futureAnnouncements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final announcements = snapshot.data ?? [];

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.createdBy,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "${item.createdDate.toLocal()}".split(' ')[0],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 12),

                    if (item.description != null)
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),

                    const SizedBox(height: 12),

                    /// IMAGE DESIGN
                    if (item.fileType == "image" && item.filePath != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(backgroundColor: Colors.black),
                                body: Center(
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      "${ApiConstants.Uploaded}${item.filePath}",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.network(
                                "${ApiConstants.Uploaded}${item.filePath}",
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    /// PDF DESIGN
                    if (item.fileType == "pdf" && item.filePath != null)
                      GestureDetector(
                        onTap: () async {
                          final url =
                              "${ApiConstants.Uploaded}${item.filePath}";
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade400,
                                Colors.red.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.white,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.fileName ??
                                      item.filePath!.split('/').last,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),

                    /// EXCEL TABLE DESIGN
                    if (item.fileType == "excel" && item.jsonData != null)
                      Container(child: _buildExcelTable(item.jsonData!)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Dynamic Excel Table
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
}

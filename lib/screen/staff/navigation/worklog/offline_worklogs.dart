import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/services/local_worklog_db.dart';
import 'package:staff_work_track/services/worklog_sync_service.dart';

class OfflineWorkLogs extends StatefulWidget {
  const OfflineWorkLogs({super.key});

  @override
  State<OfflineWorkLogs> createState() =>
      _OfflineWorkLogsState();
}

class _OfflineWorkLogsState
    extends State<OfflineWorkLogs> {

  List<Map<String, dynamic>> pendingLogs = [];

  bool isLoading = true;
  bool isSyncingAll = false;

  // IDs currently syncing
  final Set<int> syncingIds = {};

  @override
  void initState() {
    super.initState();
    loadPendingLogs();
  }

  Future<void> loadPendingLogs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data =
          await LocalWorkLogDB.getPendingWorkLogs();

      if (!mounted) return;

      setState(() {
        pendingLogs = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        "Failed to load offline worklogs",
        isError: true,
      );
    }
  }

  Future<void> syncAll() async {

    if (pendingLogs.isEmpty) {
      _showMessage(
        "No pending worklogs",
        isError: false,
      );
      return;
    }

    setState(() {
      isSyncingAll = true;
    });

    try {

      await WorkLogSyncService.syncPendingWorkLogs();

      await loadPendingLogs();

      if (!mounted) return;

      _showMessage(
        "Pending worklogs synchronized",
        isError: false,
      );

    } catch (e) {

      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
        isError: true,
      );

    } finally {

      if (mounted) {
        setState(() {
          isSyncingAll = false;
        });
      }
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

    
      appBar: AppBar(

      

        title: const Text(
          "Offline Worklogs",
        
        ),

        actions: [

          IconButton(
            tooltip: "Sync All",
            onPressed:
                isSyncingAll
                    ? null
                    : syncAll,
            icon: isSyncingAll
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.sync,
                  ),
          ),

        ],
      ),

      body: _buildBody(),
    );
  }

  // =====================================================
  // BODY
  // =====================================================

  Widget _buildBody() {

    if (isLoading) {

      return const Center(
        child:
            CircularProgressIndicator(
          color: Color(0xff194d26),
        ),
      );
    }

    if (pendingLogs.isEmpty) {

      return Center(

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Icon(
              Icons.cloud_done_outlined,
              size: 70,
              color: Colors.green.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              "No Pending Worklogs",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "All offline worklogs are synced",
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(

      onRefresh: loadPendingLogs,

      child: ListView.builder(

        padding:
            const EdgeInsets.all(16),

        itemCount:
            pendingLogs.length,

        itemBuilder:
            (context, index) {

          final log =
              pendingLogs[index];

          return _buildWorkLogCard(
            log,
          );
        },
      ),
    );
  }

  // =====================================================
  // WORKLOG CARD
  // =====================================================

  Widget _buildWorkLogCard(
    Map<String, dynamic> log,
  ) {

    final int id = log['id'];

    final bool syncing =
        syncingIds.contains(id);

    final String workType =
        log['workType'] ?? "";

    final String title =
        log['title'] ?? "";

    final String description =
        log['description'] ?? "";

    final String location =
        log['locationName'] ?? "";

    final String imagePath =
        log['imagePath'] ?? "";

    DateTime? workDate;

    try {
      workDate =
          DateTime.parse(
        log['workDate'],
      );
    } catch (_) {}

    return Container(

      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              Colors.orange.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              .04,
            ),
            blurRadius: 8,
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ==========================================
          // HEADER
          // ==========================================

          Row(

            children: [

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      workType == "IN"
                          ? Colors.green.shade50
                          : Colors.red.shade50,

                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),

                child: Text(
                  workType,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        workType == "IN"
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // =====================================
              // SYNC BUTTON
              // =====================================

            ],
          ),

          const SizedBox(height: 8),

          // ==========================================
          // DATE
          // ==========================================

          if (workDate != null)
            Row(
              children: [

                const Icon(
                  Icons.calendar_today,
                  size: 15,
                  color: Colors.grey,
                ),

                const SizedBox(width: 6),

                Text(
                  "${workDate.day.toString().padLeft(2, '0')}/"
                  "${workDate.month.toString().padLeft(2, '0')}/"
                  "${workDate.year}",
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // ==========================================
          // DESCRIPTION
          // ==========================================

          if (description.isNotEmpty)
            Text(
              description,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),

          const SizedBox(height: 8),

          // ==========================================
          // LOCATION
          // ==========================================

          if (location.isNotEmpty)
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Icon(
                  Icons.location_on,
                  size: 17,
                  color: Colors.redAccent,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    location,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

          // ==========================================
          // IMAGE
          // ==========================================

          if (imagePath.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 10,
              ),

              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),

                child: kIsWeb
                    ? Image.network(
                        imagePath,
                        height: 150,
                        width:
                            double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(imagePath),
                        height: 150,
                        width:
                            double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Container(
                            height: 150,
                            color:
                                Colors.grey.shade100,
                            child:
                                const Icon(
                              Icons
                                  .broken_image,
                            ),
                          );
                        },
                      ),
              ),
            ),

          const SizedBox(height: 10),

          // ==========================================
          // PENDING STATUS
          // ==========================================

          Row(
            children: [

              Icon(
                Icons.cloud_off,
                size: 16,
                color:
                    Colors.orange.shade700,
              ),

              const SizedBox(width: 5),

              Text(
                syncing
                    ? "Syncing..."
                    : "Pending Sync",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/dept_compensation.dart/add_compen.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class ExtraWorkPage extends StatefulWidget {
  final String deptt;

  const ExtraWorkPage({super.key, required this.deptt});

  @override
  State<ExtraWorkPage> createState() => _ExtraWorkPageState();
}

class _ExtraWorkPageState extends State<ExtraWorkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoading = true;
  bool isRefreshing = false;

  int? processingId;

  List<Map<String, dynamic>> extraWorks = [];

  final List<String> tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExtraWorks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExtraWorks({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (refresh) {
        isRefreshing = true;
      } else {
        isLoading = true;
      }
    });

    try {
      final result = await OvertimeService.getDepartmentExtraWork();

      if (!mounted) return;

      setState(() {
        extraWorks = result
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });

      debugPrint('Department Extra Work Count: ${extraWorks.length}');
    } catch (e) {
      debugPrint('Department Extra Work Error: $e');

      if (!mounted) return;

      _showMessage(
        'Failed to load extra work: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  List<Map<String, dynamic>> getFilteredWorks(int index) {
    switch (index) {
      // ALL
      case 0:
        return extraWorks;

      case 1:
        return extraWorks.where((item) {
          final status = item['status']?.toString().trim() ?? '';

          return status == 'Accepted';
        }).toList();

      // APPROVED
      case 2:
        return extraWorks.where((item) {
          final status = item['status']?.toString().trim() ?? '';

          return status == 'Approved';
        }).toList();

      // REJECTED
      case 3:
        return extraWorks.where((item) {
          final status = item['status']?.toString().trim() ?? '';

          return status == 'StaffRejected' || status == 'ManagerRejected';
        }).toList();

      default:
        return extraWorks;
    }
  }

  Future<void> _approveExtraWork(Map<String, dynamic> item) async {
    final extraWorkId = _getExtraWorkId(item);

    if (extraWorkId == null) {
      _showMessage('Invalid extra work ID.', isError: true);
      return;
    }

    // Prevent multiple requests
    if (processingId != null) {
      return;
    }

    setState(() {
      processingId = extraWorkId;
    });

    try {
      await OvertimeService.updateManagerResponse(
        extraWorkId: extraWorkId,
        status: 'Approved',
        managerRemarks: null,
      );

      if (!mounted) return;

      _showMessage('Extra work approved successfully.');

      // Reload the list
      await _loadExtraWorks(refresh: true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to approve: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        processingId = null;
      });
    }
  }

  Future<void> _rejectExtraWork(Map<String, dynamic> item) async {
    final extraWorkId = _getExtraWorkId(item);

    if (extraWorkId == null) {
      _showMessage('Invalid extra work ID.', isError: true);
      return;
    }

    if (processingId != null) {
      return;
    }

    String reason = '';
    bool showError = false;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reject Extra Work'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please provide a reason for rejecting this extra work request.',
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      autofocus: true,
                      minLines: 3,
                      maxLines: 4,
                      onChanged: (value) {
                        reason = value;

                        if (showError && value.trim().isNotEmpty) {
                          setDialogState(() {
                            showError = false;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter rejection reason...',
                        errorText: showError
                            ? 'Rejection reason is required'
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (reason.trim().isEmpty) {
                      setDialogState(() {
                        showError = true;
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, reason.trim());
                  },
                  child: const Text('Reject'),
                ),
              ],
            );
          },
        );
      },
    );

    // User cancelled
    if (result == null || result.trim().isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      processingId = extraWorkId;
    });

    try {
      await OvertimeService.updateManagerResponse(
        extraWorkId: extraWorkId,
        status: 'ManagerRejected',
        managerRemarks: result.trim(),
      );

      if (!mounted) return;

      _showMessage('Extra work rejected successfully.');

      await _loadExtraWorks(refresh: true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to reject: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        processingId = null;
      });
    }
  }

  int? _getExtraWorkId(Map<String, dynamic> item) {
    final value = item['id'];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text('Compensation Work'),

        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateExtraWorkPage(department: widget.deptt),
                ),
              );

              if (result == true && mounted) {
                await _loadExtraWorks(refresh: true);
              }
            },
          ),

          const SizedBox(width: 8),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),

          child: Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),

            child: TabBar(
              controller: _tabController,
              indicatorColor: secondaryColor,
              indicatorWeight: 2.5,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Colors.white54,
              dividerColor: Colors.transparent,

              tabs: [
                Tab(text: 'All (${extraWorks.length})'),

                Tab(text: 'Pending (${getFilteredWorks(1).length})'),

                Tab(text: 'Approved (${getFilteredWorks(2).length})'),

                Tab(text: 'Rejected (${getFilteredWorks(3).length})'),
              ],
            ),
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: RotatingFlower())
          : TabBarView(
              controller: _tabController,

              children: List.generate(4, (index) {
                final works = getFilteredWorks(index);

                if (works.isEmpty) {
                  return _emptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => _loadExtraWorks(refresh: true),

                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.all(15),

                    itemCount: works.length,

                    itemBuilder: (context, i) {
                      return _extraWorkCard(works[i]);
                    },
                  ),
                );
              }),
            ),
    );
  }

  Widget _extraWorkCard(Map<String, dynamic> item) {
    final status = item['status']?.toString().trim() ?? 'Pending';

    final staffName = item['staffName']?.toString().trim();

    final taskName = item['taskName']?.toString().trim();

    final reason = item['reason']?.toString().trim();

    final workType = item['workType']?.toString().trim();

    final managerRemarks = item['managerRemarks']?.toString().trim();

    final staffRemarks = item['staffRemarks']?.toString().trim();

    final date = _formatDate(item['workDate']);

    final startTime = _formatTime(item['startTime']);

    final endTime = _formatTime(item['endTime']);

    final expectedHours = _formatHours(item['expectedHours']);

    final statusInfo = _getStatusInfo(status);

    final id = _getExtraWorkId(item);

    final isProcessing = id != null && processingId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.45),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(17),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.secondary,

                  child: Text(
                    staffName != null && staffName.isNotEmpty
                        ? staffName[0].toUpperCase()
                        : '?',

                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        staffName == null || staffName.isEmpty
                            ? 'Unknown Staff'
                            : staffName,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        taskName == null || taskName.isEmpty
                            ? 'No Task'
                            : taskName,

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _statusChip(
                  statusInfo['text'] as String,

                  statusInfo['color'] as Color,
                ),
              ],
            ),

            const SizedBox(height: 18),

            _infoRow(Icons.calendar_today_outlined, date),

            const SizedBox(height: 10),

            _infoRow(Icons.access_time_rounded, '$startTime - $endTime'),

            const SizedBox(height: 10),

            _infoRow(Icons.timer_outlined, '$expectedHours Hours'),

            const SizedBox(height: 10),

            _infoRow(
              Icons.work_outline_rounded,
              _formatWorkType(workType ?? ''),
            ),

            const SizedBox(height: 10),

            Divider(height: 1),

            const SizedBox(height: 12),

            Text('Reason', style: Theme.of(context).textTheme.headlineLarge),

            const SizedBox(height: 5),

            Text(
              reason == null || reason.isEmpty ? 'No reason provided' : reason,

              style: const TextStyle(fontSize: 13),
            ),

            if (staffRemarks != null && staffRemarks.isNotEmpty) ...[
              const SizedBox(height: 12),

              _remarksBox('Staff Remarks', staffRemarks),
            ],

            if (managerRemarks != null && managerRemarks.isNotEmpty) ...[
              const SizedBox(height: 12),

              _remarksBox('Manager Remarks', managerRemarks),
            ],

            if (status == 'Accepted') ...[
              const SizedBox(height: 18),

              _managerActionButtons(item),
            ],

            if (isProcessing) ...[
              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Processing...',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _managerActionButtons(Map<String, dynamic> item) {
    final id = _getExtraWorkId(item);

    final isProcessing = id != null && processingId == id;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isProcessing
                ? null
                : () {
                    _rejectExtraWork(item);
                  },

            icon: const Icon(Icons.close_rounded, size: 18),

            label: const Text('Reject'),

            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,

              side: BorderSide(color: Colors.redAccent.withOpacity(0.6)),

              padding: const EdgeInsets.symmetric(vertical: 13),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProcessing
                ? null
                : () {
                    _approveExtraWork(item);
                  },

            icon: isProcessing
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),

            label: Text(isProcessing ? 'Processing...' : 'Approve'),

            style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 25, 77, 38),

              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(vertical: 13),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Approved':
        return {'text': 'Approved', 'color': Colors.green};

      case 'StaffRejected':
        return {'text': 'Staff Rejected', 'color': Colors.redAccent};

      case 'ManagerRejected':
        return {'text': 'Manager Rejected', 'color': Colors.redAccent};

      case 'Accepted':
        return {'text': 'Staff Accepted', 'color': Colors.blueAccent};

      case 'Pending':
      default:
        return {'text': 'Waiting for Staff', 'color': Colors.amberAccent};
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final date = DateTime.parse(value.toString());

      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final parts = value.toString().split(':');

      if (parts.length < 2) {
        return value.toString();
      }

      final hour = int.parse(parts[0]);

      final minute = int.parse(parts[1]);

      final time = TimeOfDay(hour: hour, minute: minute);

      final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

      final period = time.period == DayPeriod.am ? 'AM' : 'PM';

      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatHours(dynamic value) {
    if (value == null) {
      return '0';
    }

    try {
      final number = double.parse(value.toString());

      if (number == number.roundToDouble()) {
        return number.toInt().toString();
      }

      return number.toStringAsFixed(2);
    } catch (_) {
      return value.toString();
    }
  }

  String _formatWorkType(String value) {
    switch (value) {
      case 'WeeklyOff':
        return 'Weekly Off';

      case 'PublicHoliday':
        return 'Public Holiday';

      case 'CompanyHoliday':
        return 'Company Holiday';

      default:
        return value.isEmpty ? 'Other' : value;
    }
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 125),

      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(0.10),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color.withOpacity(0.25)),
      ),

      child: Text(
        status,

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black87),

        const SizedBox(width: 10),

        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _remarksBox(String title, String remarks) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),

        border: Border.all( color: Colors.red),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),

          const SizedBox(height: 5),

          Text(remarks, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.60,

          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(
                  Icons.work_history_outlined,

                  size: 58,

                  color: Colors.white.withOpacity(0.18),
                ),

                const SizedBox(height: 14),

                Text(
                  'No extra work found',

                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),

                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Pull down to refresh',

                  style: TextStyle(
                    color: Colors.white.withOpacity(0.30),

                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor: isError ? Colors.redAccent : Colors.green,

          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

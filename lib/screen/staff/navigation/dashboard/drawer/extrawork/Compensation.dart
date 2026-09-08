import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class MyExtraWorkPage extends StatefulWidget {
  const MyExtraWorkPage({super.key});

  @override
  State<MyExtraWorkPage> createState() => _MyExtraWorkPageState();
}

class _MyExtraWorkPageState extends State<MyExtraWorkPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> extraWorks = [];

  bool isLoading = true;

  int? processingId;

  late TabController _tabController;

  final List<String> tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExtraWork();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExtraWork() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await OvertimeService.getMyExtraWork();

      debugPrint('==========================================');
      debugPrint('MY EXTRA WORK RESULT');
      debugPrint('Count: ${result.length}');
      debugPrint('Data: $result');
      debugPrint('==========================================');

      if (!mounted) return;

      setState(() {
        extraWorks = result
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (e) {
      debugPrint('MY EXTRA WORK ERROR: $e');

      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredWorks(String filter) {
    switch (filter) {
      case 'All':
        return extraWorks;

      case 'Pending':
        return extraWorks.where((work) {
          final status = _getStatus(work);
          return status == 'Pending' || status == 'Accepted';
        }).toList();

      case 'Approved':
        return extraWorks.where((work) {
          return _getStatus(work) == 'Approved';
        }).toList();

      case 'Rejected':
        return extraWorks.where((work) {
          final status = _getStatus(work);
          return status == 'StaffRejected' || status == 'ManagerRejected';
        }).toList();

      default:
        return extraWorks;
    }
  }

  String _getStatus(Map<String, dynamic> work) {
    return work['status']?.toString().trim() ?? '';
  }

  int? _getId(Map<String, dynamic> work) {
    final value = work['id'];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  Future<void> _acceptExtraWork(Map<String, dynamic> work) async {
    final id = _getId(work);

    if (id == null) {
      _showMessage('Invalid extra work ID.', isError: true);
      return;
    }

    setState(() {
      processingId = id;
    });

    try {
      await OvertimeService.updateStaffResponse(
        extraWorkId: id,
        status: 'Accepted',
        staffRemarks: null,
      );

      if (!mounted) return;

      _showMessage('Extra work accepted successfully.');

      await _loadExtraWork();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        processingId = null;
      });
    }
  }

  Future<void> _rejectExtraWork(Map<String, dynamic> work) async {
    final id = _getId(work);

    if (id == null) {
      _showMessage('Invalid extra work ID.', isError: true);
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const _RejectExtraWorkDialog();
      },
    );

    // User cancelled
    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      processingId = id;
    });

    try {
      await OvertimeService.updateStaffResponse(
        extraWorkId: id,
        status: 'StaffRejected',
        staffRemarks: reason.trim(),
      );

      if (!mounted) return;

      _showMessage('Extra work rejected successfully.');

      await _loadExtraWork();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        processingId = null;
      });
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'Pending':
        return 'Pending';

      case 'Accepted':
        return 'Accepted - Waiting';

      case 'Approved':
        return 'Approved';

      case 'Rejected':
        return 'Rejected';

      default:
        return status?.isNotEmpty == true ? status! : 'Unknown';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;

      case 'Accepted':
        return Colors.blueAccent;

      case 'Approved':
        return Colors.green;

      case 'Rejected':
        return Colors.redAccent;

      default:
        return Colors.white54;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(text);

      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return text;
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final parts = text.split(':');

      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);

        final minute = int.parse(parts[1]);

        final time = TimeOfDay(hour: hour, minute: minute);

        return time.format(context);
      }
    } catch (_) {}

    return text;
  }

  String _formatHours(dynamic value) {
    if (value == null) {
      return '-';
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

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compensation Work'),
   leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: secondaryColor,
         labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Colors.white54,
          tabs: tabs.map((tab) {
            return Tab(text: tab);
          }).toList(),
        ),
      ),

      body: isLoading
          ? const Center(child: RotatingFlower())
          : TabBarView(
              controller: _tabController,

              children: tabs.map((filter) {
                return _buildTabContent(filter);
              }).toList(),
            ),
    );
  }

  Widget _buildTabContent(String filter) {
    final works = _getFilteredWorks(filter);

    if (works.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadExtraWork,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          children: const [
            SizedBox(height: 140),

            Icon(Icons.work_off_outlined, size: 55, color: Colors.white24),

            SizedBox(height: 16),

            Center(
              child: Text(
                'No extra work found',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExtraWork,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),

        physics: const AlwaysScrollableScrollPhysics(),

        itemCount: works.length,

        itemBuilder: (context, index) {
          return _buildExtraWorkCard(works[index]);
        },
      ),
    );
  }

  Widget _buildExtraWorkCard(Map<String, dynamic> work) {
    final status = _getStatus(work);

    final staffAccepted = status == 'Accepted';

    final canRespond = status == 'Pending';

    final id = _getId(work);

    final isProcessing = id != null && processingId == id;

    final workType = work['workType']?.toString().trim();

    final reason = work['reason']?.toString().trim();

    final managerName = work['managerName']?.toString().trim();

    final staffName = work['staffName']?.toString().trim();

    final staffRemarks = work['staffRemarks']?.toString();

    final managerRemarks = work['managerRemarks']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.45),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        (workType == null || workType.isEmpty)
                            ? 'Extra Work'
                            : workType,

                       style: Theme.of(context).textTheme.headlineLarge,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        managerName != null && managerName.isNotEmpty
                            ? 'Requested by $managerName'
                            : 'Requested by Manager',

                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 18),

            _infoRow(
              Icons.calendar_today_outlined,
              'Work Date',
              _formatDate(work['workDate']),
            ),

            const SizedBox(height: 10),

            _infoRow(
              Icons.access_time_outlined,
              'Time',
              '${_formatTime(work['startTime'])} - '
                  '${_formatTime(work['endTime'])}',
            ),

            const SizedBox(height: 10),

            _infoRow(
              Icons.timer_outlined,
              'Expected Hours',
              '${_formatHours(work['expectedHours'])} hours',
            ),

            if (staffName != null && staffName.isNotEmpty) ...[
              const SizedBox(height: 14),

              _infoRow(Icons.person_outline, 'Staff', staffName),
            ],

            const SizedBox(height: 14),

             Text('Reason', style: Theme.of(context).textTheme.headlineLarge),

            const SizedBox(height: 5),

            Text(
              (reason == null || reason.isEmpty) ? '-' : reason,

              style: const TextStyle(fontSize: 13),
            ),

            if (staffAccepted) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.08),

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.20),
                  ),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.blueAccent,
                      size: 20,
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'You accepted this request. '
                        'Waiting for manager approval.',

                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (staffRemarks != null && staffRemarks.trim().isNotEmpty) ...[
              const SizedBox(height: 14),

              _remarksBox('Your Remarks', staffRemarks),
            ],

            if (managerRemarks != null && managerRemarks.trim().isNotEmpty) ...[
              const SizedBox(height: 14),

              _remarksBox('Manager Remarks', managerRemarks),
            ],

            if (canRespond) ...[
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _rejectExtraWork(work);
                            },

                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,

                        side: BorderSide(
                          color: Colors.redAccent.withOpacity(0.6),
                        ),

                        padding: const EdgeInsets.symmetric(vertical: 13),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      child: const Text('Reject'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _acceptExtraWork(work);
                            },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 25, 77, 38),

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(vertical: 13),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      child: isProcessing
                          ? const SizedBox(
                              height: 18,
                              width: 18,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final color = _statusColor(status);

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

        decoration: BoxDecoration(
          color: color.withOpacity(0.10),

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: color.withOpacity(0.30)),
        ),

        child: Text(
          _statusText(status),

          overflow: TextOverflow.ellipsis,

          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
          Icon(icon, size: 15, color: Colors.black54),


        const SizedBox(width: 10),

        Text(
          '$title:',

          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
}

class _RejectExtraWorkDialog extends StatefulWidget {
  const _RejectExtraWorkDialog();

  @override
  State<_RejectExtraWorkDialog> createState() => _RejectExtraWorkDialogState();
}

class _RejectExtraWorkDialogState extends State<_RejectExtraWorkDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a reason.')));

      return;
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),

      title: const Text(
        'Reject Extra Work',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Please provide a reason for rejecting this request.',

              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _reasonController,

              autofocus: true,

              minLines: 3,

              maxLines: 5,

              style: const TextStyle(color: Colors.white, fontSize: 14),

              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',

                hintStyle: const TextStyle(color: Colors.white38),

                filled: true,

                fillColor: Colors.white.withOpacity(0.05),

                contentPadding: const EdgeInsets.all(14),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },

          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _submit,

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,

            foregroundColor: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          child: const Text('Reject'),
        ),
      ],
    );
  }
}

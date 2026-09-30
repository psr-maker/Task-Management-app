import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/utils/time_utils.dart';

String? worklogImageUrl(dynamic path) {
  final value = path?.toString() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('http')) return value;
  final base = ApiConstants.Uploaded;
  if (value.startsWith('/')) return '$base$value';
  return '$base/$value';
}

String formatWorklogTime(dynamic value) {
  return TimeUtils.formatTime12(value, empty: '--:--');
}

/// Turns separate IN and OUT rows into one session.
/// Rows that already carry out fields are left as one session.
List<Map<String, dynamic>> pairWorkLogs(
  List logs, {
  bool singleUser = false,
}) {
  final sessions = <Map<String, dynamic>>[];
  final openIns = <String, List<Map<String, dynamic>>>{};

  final sorted = logs.map((raw) => Map<String, dynamic>.from(raw as Map)).toList()
    ..sort((a, b) => (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString()));

  String keyOf(Map<String, dynamic> log) {
    final date = (log['workDate'] ?? '').toString().split('T').first;
    if (singleUser) return date;
    final user = log['userId'] ?? log['name'] ?? log['userName'];
    if (user == null || user.toString().isEmpty) {
      return 'solo-${log['id']}';
    }
    return '$user|$date';
  }

  bool alreadyCheckedOut(Map<String, dynamic> log) {
    final image = (log['outImageUrl'] ?? '').toString();
    final time = (log['outTime'] ?? '').toString();
    return image.isNotEmpty || time.isNotEmpty;
  }

  for (final log in sorted) {
    if (alreadyCheckedOut(log)) {
      sessions.add(log);
      continue;
    }

    final type = (log['workType'] ?? 'IN').toString().toUpperCase();
    final key = keyOf(log);

    if (type == 'OUT') {
      final queue = openIns[key];
      if (queue != null && queue.isNotEmpty) {
        final open = queue.removeAt(0);
        open['outTime'] = log['time'];
        open['outImageUrl'] = log['imageUrl'];
        open['outLocationName'] = log['locationName'];
        open['outLatitude'] = log['latitude'];
        open['outLongitude'] = log['longitude'];
      } else {
        sessions.add({
          ...log,
          'outTime': log['time'],
          'outImageUrl': log['imageUrl'],
          'outLocationName': log['locationName'],
          'imageUrl': null,
          'locationName': null,
          'time': null,
        });
      }
    } else {
      sessions.add(log);
      openIns.putIfAbsent(key, () => []).add(log);
    }
  }

  return sessions;
}

class WorklogSessionTile extends StatelessWidget {
  const WorklogSessionTile({
    super.key,
    required this.log,
    this.onCheckOut,
  });

  final Map log;
  final VoidCallback? onCheckOut;

  @override
  Widget build(BuildContext context) {
    final name = (log['name'] ?? log['userName'] ?? '').toString();
    final title = (log['title'] ?? '').toString();
    final description = (log['description'] ?? '').toString();
    final department = (log['departmentName'] ?? '').toString();
    final status = (log['status'] ?? '').toString();
    final dateText = TimeUtils.formatDateValue(log['workDate'], empty: '');
    final inTime = formatWorklogTime(log['time']);
    final outTime = formatWorklogTime(log['outTime']);
    final hasOut = (log['outImageUrl'] ?? '').toString().isNotEmpty ||
        (log['outTime'] ?? '').toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: WebTheme.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty)
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: WebTheme.inkOf(context),
                        ),
                      ),
                    if (department.isNotEmpty)
                      Text(
                        department,
                        style: TextStyle(
                          fontSize: 12,
                          color: WebTheme.mutedOf(context),
                        ),
                      ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.inkOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status.isNotEmpty) _statusChip(context, status),
            ],
          ),
          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: WebTheme.mutedOf(context)),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.inkOf(context),
                  ),
                ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _evidence(
                  context,
                  label: 'IN',
                  time: inTime,
                  location: (log['locationName'] ?? '').toString(),
                  imagePath: log['imageUrl'],
                  color: const Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _evidence(
                  context,
                  label: 'OUT',
                  time: hasOut ? outTime : '--',
                  location: (log['outLocationName'] ?? '').toString(),
                  imagePath: log['outImageUrl'],
                  color: const Color(0xFFC2410C),
                ),
              ),
            ],
          ),
          if (!hasOut && onCheckOut != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Check Out',
                onPressed: onCheckOut,
                color: WebTheme.brand,
                txtcolor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final submitted = status.toLowerCase() == 'submitted';
    final color = submitted ? WebTheme.brand : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _evidence(
    BuildContext context, {
    required String label,
    required String time,
    required String location,
    required dynamic imagePath,
    required Color color,
  }) {
    final url = worklogImageUrl(imagePath);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label  $time',
          style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: url == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(imageUrl: url),
                    ),
                  );
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: url == null
                  ? Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: Text(
                        label == 'OUT' ? 'Not checked out' : 'No photo',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: RotatingFlower());
                      },
                      errorBuilder: (_, _, _) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          location.isEmpty ? 'No location' : location,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/services/version_service.dart';

class AppVersionCard extends StatefulWidget {
  const AppVersionCard({super.key});

  @override
  State<AppVersionCard> createState() => _AppVersionCardState();
}

class _AppVersionCardState extends State<AppVersionCard> {
  String _version = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await VersionService.getAppInfo();
      if (!mounted) return;
      setState(() {
        _version = (info['version'] ?? '').isEmpty
            ? 'Unavailable'
            : info['version']!;
        _buildNumber = info['buildNumber'] ?? '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _version = 'Unavailable';
        _buildNumber = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _buildNumber.isEmpty
        ? _version
        : '$_version (build $_buildNumber)';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.info_outline, size: 20),
        title: Text(
          'App Version',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          detail,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

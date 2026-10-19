import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class PendingApprovals extends StatefulWidget {
  final Widget? aside;

  const PendingApprovals({super.key, this.aside});

  @override
  State<PendingApprovals> createState() => _PendingApprovalsState();
}

class _PendingApprovalsState extends State<PendingApprovals> {
  late Future<List<UserModel>> pendingFuture;

  @override
  void initState() {
    super.initState();
    loadPendingUsers();
  }

  void loadPendingUsers() async {
    setState(() {
      pendingFuture = DashboardService.getPendingUsers();
    });
  }

  Widget _userCard(BuildContext context, UserModel user) {
    final initial = user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();
    final person = Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: WebTheme.brand,
          child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, color: WebTheme.inkOf(context)),
              ),
              const SizedBox(height: 2),
              Text(
                '${user.role} · ${user.department}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () async {
            final confirmed = await showConfirmDialog(context, 'Reject', 'user');
            if (confirmed == true) await handleAction(user.userId, false);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: WebTheme.danger,
            side: BorderSide(color: WebTheme.danger),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Reject'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            final confirmed = await showConfirmDialog(context, 'Approve', 'user');
            if (confirmed == true) await handleAction(user.userId, true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: WebTheme.brand,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Approve'),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebTheme.brandSoftOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [person, const SizedBox(height: 10), actions],
            );
          }
          return Row(children: [Expanded(child: person), actions]);
        },
      ),
    );
  }

  Future<void> handleAction(int userId, bool approve) async {
    await DashboardService.approveUser(userId, approve);
    loadPendingUsers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: pendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _pair(
            context,
            const SizedBox(
              height: 72,
              child: Center(child: RotatingFlower()),
            ),
            widget.aside,
          );
        }

        if (snapshot.hasError) {
          return _pair(
            context,
            const SizedBox(height: 180, child: AppLoadError()),
            widget.aside,
          );
        }

        final users = snapshot.data;
        if (users == null || users.isEmpty) {
          return widget.aside ?? const SizedBox();
        }

        return _pair(
          context,
          Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: WebTheme.card(context, radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: WebTheme.inkOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'New accounts waiting for a decision',
                          style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: WebTheme.brandSoftOf(context),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${users.length}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WebTheme.brand),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final user in users) ...[
                _userCard(context, user),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
          widget.aside,
        );
      },
    );
  }

  Widget _pair(BuildContext context, Widget left, Widget? right) {
    if (right == null) return left;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

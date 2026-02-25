import 'package:flutter/material.dart';

class TaskActionMenu extends StatelessWidget {
  final String currentUserId;
  final String currentUserRole;
  final String taskOwnerId;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskActionMenu({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
    required this.taskOwnerId,
    required this.onEdit,
    required this.onDelete,
  });

  bool get hasPermission {
    if (currentUserRole == 'Director') return true;

    if ((currentUserRole == 'Manager' || currentUserRole == 'Staff') &&
        currentUserId == taskOwnerId) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }
}

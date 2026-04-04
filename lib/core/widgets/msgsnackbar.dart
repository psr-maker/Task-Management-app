import 'package:flutter/material.dart';

class Msgsnackbar extends StatelessWidget {
  final String message;
  final bool isError;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  const Msgsnackbar(
    BuildContext _, {
    super.key,
    required this.message,
    required this.isError,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ??
        (isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary);

    final txtColor =
        textColor ??
        (isError
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimary);

    final icColor =
        iconColor ??
        (isError
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimary);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: icColor.withOpacity(0.2),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: icColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: txtColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showConfirmDialog(
  BuildContext context,
  String action,
  String entitytype,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Center(
          child: Text(
            "$action Confirmation",
            style: TextStyle(
              fontSize: 18,
              color: const Color.fromARGB(255, 25, 77, 38),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Text("Are you sure you want to $action this $entitytype?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action,
              style: TextStyle(
                color: action == "Approve"
                    ? const Color.fromARGB(255, 25, 77, 38)
                    : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> showPendingAlert(BuildContext context, String message) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        "Approval Pending",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

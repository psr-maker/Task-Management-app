import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';

Future<T?> openFormPage<T>(
  BuildContext context,
  Widget page, {
  double maxWidth = 720,
}) {
  if (AppLayout.isMobile(context)) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final tablet = AppLayout.isTablet(dialogContext);
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: tablet ? 16 : 28,
          vertical: tablet ? 16 : 20,
        ),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppLayout.dialogMaxWidth(
                dialogContext,
                preferred: maxWidth,
              ),
              maxHeight: size.height * 0.9,
              minWidth: tablet ? 0 : 420,
            ),
            child: Material(
              color: Theme.of(dialogContext).scaffoldBackgroundColor,
              child: page,
            ),
          ),
        ),
      );
    },
  );
}

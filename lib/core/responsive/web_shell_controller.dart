import 'package:flutter/material.dart';

class WebMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String group;

  const WebMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.group = '',
  });
}

class WebShellController extends ChangeNotifier {
  int overdueCount = 0;
  VoidCallback? onOverdue;
  VoidCallback? onReports;
  VoidCallback? onSettings;
  List<WebMenuItem> menuItems = const [];

  void update({
    int? overdueCount,
    VoidCallback? onOverdue,
    VoidCallback? onReports,
    VoidCallback? onSettings,
    List<WebMenuItem>? menuItems,
  }) {
    if (onOverdue != null) this.onOverdue = onOverdue;
    if (onReports != null) this.onReports = onReports;
    if (onSettings != null) this.onSettings = onSettings;

    var changed = false;
    if (overdueCount != null && overdueCount != this.overdueCount) {
      this.overdueCount = overdueCount;
      changed = true;
    }
    if (menuItems != null) {
      final labelsChanged = menuItems.length != this.menuItems.length ||
          List.generate(
            menuItems.length,
            (i) => menuItems[i].label != this.menuItems[i].label,
          ).any((v) => v);
      this.menuItems = menuItems;
      if (labelsChanged) changed = true;
    }
    if (changed) notifyListeners();
  }
}

class WebShellScope extends InheritedNotifier<WebShellController> {
  const WebShellScope({
    super.key,
    required WebShellController controller,
    required super.child,
  }) : super(notifier: controller);

  static WebShellController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WebShellScope>()?.notifier;
  }
}

void bindWebHeader(
  BuildContext context, {
  int overdueCount = 0,
  VoidCallback? onOverdue,
  VoidCallback? onReports,
  VoidCallback? onSettings,
  List<WebMenuItem> menuItems = const [],
}) {
  final controller = WebShellScope.maybeOf(context);
  if (controller == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    controller.update(
      overdueCount: overdueCount,
      onOverdue: onOverdue,
      onReports: onReports,
      onSettings: onSettings,
      menuItems: menuItems,
    );
  });
}

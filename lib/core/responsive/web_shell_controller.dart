import 'package:flutter/material.dart';

class WebMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String group;
  final bool selected;
  final int stamp;

  const WebMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.group = '',
    this.selected = false,
    this.stamp = 0,
  });
}

class WebShellController extends ChangeNotifier {
  int overdueCount = 0;
  VoidCallback? onOverdue;
  VoidCallback? onReports;
  VoidCallback? onSettings;
  List<WebMenuItem> menuItems = const [];
  String? selectedLabel;

  /// When set, a later page cannot replace the shell menu after it is filled.
  bool lockMenu = false;

  /// State that last installed [menuItems]. A new state must replace the
  /// menu even when the labels match, or a tap calls setState on a disposed page.
  Object? _menuOwner;

  void update({
    int? overdueCount,
    VoidCallback? onOverdue,
    VoidCallback? onReports,
    VoidCallback? onSettings,
    List<WebMenuItem>? menuItems,
    String? selectedLabel,
    bool clearSelection = false,
    bool forceMenu = false,
    Object? menuOwner,
  }) {
    if (onOverdue != null) this.onOverdue = onOverdue;
    if (onReports != null) this.onReports = onReports;
    if (onSettings != null) this.onSettings = onSettings;

    var changed = false;
    if (overdueCount != null && overdueCount != this.overdueCount) {
      this.overdueCount = overdueCount;
      changed = true;
    }
    final keepCurrentMenu =
        lockMenu && !forceMenu && this.menuItems.isNotEmpty;
    final ownerChanged = menuOwner != null && !identical(menuOwner, _menuOwner);
    if (menuItems != null &&
        !keepCurrentMenu &&
        (ownerChanged || !_sameMenu(this.menuItems, menuItems))) {
      this.menuItems = menuItems;
      if (menuOwner != null) _menuOwner = menuOwner;
      changed = true;
    }
    if (clearSelection) {
      if (this.selectedLabel != null) {
        this.selectedLabel = null;
        changed = true;
      }
    } else if (selectedLabel != null && selectedLabel != this.selectedLabel) {
      this.selectedLabel = selectedLabel;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  bool _sameMenu(List<WebMenuItem> current, List<WebMenuItem> next) {
    if (identical(current, next)) return true;
    if (current.length != next.length) return false;
    for (var i = 0; i < current.length; i++) {
      final a = current[i];
      final b = next[i];
      if (a.label != b.label ||
          a.group != b.group ||
          a.icon != b.icon ||
          a.selected != b.selected ||
          a.stamp != b.stamp) {
        return false;
      }
    }
    return true;
  }
}

class WebShellScope extends InheritedNotifier<WebShellController> {
  static final GlobalKey<NavigatorState> contentNavigator =
      GlobalKey<NavigatorState>();

  const WebShellScope({
    super.key,
    required WebShellController controller,
    required super.child,
  }) : super(notifier: controller);

  static void open(Widget page) {
    final nav = contentNavigator.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => page));
  }

  static WebShellController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WebShellScope>()?.notifier;
  }
}

void bindWebHeader(
  BuildContext context, {
  int? overdueCount,
  VoidCallback? onOverdue,
  VoidCallback? onReports,
  VoidCallback? onSettings,
  List<WebMenuItem>? menuItems,
  Object? menuOwner,
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
      menuOwner: menuOwner,
    );
  });
}

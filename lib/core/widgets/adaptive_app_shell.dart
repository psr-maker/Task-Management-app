import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/navrole.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/curved_bottom_nav.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/dahboard.dart';
import 'package:staff_work_track/utils/enum.dart';

class AdaptiveAppShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final UserRole role;
  final List<Widget> pages;
  final String brandTitle;

  const AdaptiveAppShell({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
    required this.pages,
    this.brandTitle = 'WorkPulse',
  });

  @override
  Widget build(BuildContext context) {
    if (AppLayout.isDesktop(context) || AppLayout.isTablet(context)) {
      return _WebShell(
        currentIndex: currentIndex,
        onTap: onTap,
        role: role,
        pages: pages,
        brandTitle: brandTitle,
      );
    }

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CurvedBottomNav(
          currentIndex: currentIndex,
          onTap: onTap,
          role: role,
        ),
      ),
    );
  }
}

class _WebShell extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final UserRole role;
  final List<Widget> pages;
  final String brandTitle;

  const _WebShell({
    required this.currentIndex,
    required this.onTap,
    required this.role,
    required this.pages,
    required this.brandTitle,
  });

  @override
  State<_WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<_WebShell> {
  final WebShellController controller = WebShellController();
  GlobalKey<NavigatorState> get _contentNavigator =>
      WebShellScope.contentNavigator;
  late final NavigatorObserver _popObserver = _ShellPopObserver(_returnedHome);
  bool _sidebarOpen = true;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    controller.lockMenu = widget.role == UserRole.superAdmin;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
  }

  void _returnedHome() {
    if (!mounted) return;
    controller.update(clearSelection: true);
    setState(() => _refreshTick++);
  }

  void _openTab(int index) {
    final nav = _contentNavigator.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    controller.update(clearSelection: true);
    widget.onTap(index);
  }

  void _openMenu(WebMenuItem item) {
    controller.update(selectedLabel: item.label);
    item.onTap();
  }

  double _openWidth(BuildContext context) {
    return AppLayout.isTablet(context) ? 200 : 220;
  }

  @override
  Widget build(BuildContext context) {
    final items = roleNavItems[widget.role]!;
    final theme = WebTheme.overlay(Theme.of(context));
    final openWidth = _openWidth(context);
    if (controller.lockMenu) {
      final menu = directorShellMenu(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.update(menuItems: menu, forceMenu: true);
      });
    }

    return WebShellScope(
      controller: controller,
      child: Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: _ShellTabScope(
            currentIndex: widget.currentIndex,
            refreshTick: _refreshTick,
            pages: widget.pages,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    width: _sidebarOpen ? openWidth : 0,
                    color: WebTheme.dark,
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: openWidth,
                      maxWidth: openWidth,
                      child: SizedBox(
                        width: openWidth,
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) {
                            return _BrandSidebar(
                              brandTitle: widget.brandTitle,
                              primaryItems: items,
                              currentIndex: widget.currentIndex,
                              selectedMenu: controller.selectedLabel,
                              onPrimaryTap: _openTab,
                              onMenuTap: _openMenu,
                              items: controller.menuItems,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                _SidebarArrow(
                  open: _sidebarOpen,
                  onPressed: _toggleSidebar,
                ),
                Expanded(
                  child: Navigator(
                    key: _contentNavigator,
                    observers: [_popObserver],
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) => const _ShellContent(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellTabScope extends InheritedWidget {
  final int currentIndex;
  final int refreshTick;
  final List<Widget> pages;

  const _ShellTabScope({
    required this.currentIndex,
    required this.refreshTick,
    required this.pages,
    required super.child,
  });

  static _ShellTabScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ShellTabScope>();
    assert(scope != null, 'Shell tabs are missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(_ShellTabScope oldWidget) {
    return currentIndex != oldWidget.currentIndex ||
        refreshTick != oldWidget.refreshTick ||
        pages != oldWidget.pages;
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent();

  @override
  Widget build(BuildContext context) {
    final scope = _ShellTabScope.of(context);
    return Padding(
      padding: AppLayout.shellInset(context),
      child: KeyedSubtree(
        key: ValueKey('${scope.currentIndex}-${scope.refreshTick}'),
        child: scope.pages[scope.currentIndex],
      ),
    );
  }
}

class _SidebarArrow extends StatelessWidget {
  final bool open;
  final VoidCallback onPressed;

  const _SidebarArrow({
    required this.open,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WebTheme.dark,
      child: SizedBox(
        width: 28,
        child: Column(
          children: [
            const SizedBox(height: 16),
            IconButton(
              tooltip: open ? 'Hide menu' : 'Show menu',
              onPressed: onPressed,
              icon: Icon(
                open ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellPopObserver extends NavigatorObserver {
  final VoidCallback onReturnHome;

  _ShellPopObserver(this.onReturnHome);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.isFirst != true) return;
    if (route is PopupRoute) return;
    onReturnHome();
  }
}

class _BrandSidebar extends StatelessWidget {
  final String brandTitle;
  final List<NavItem> primaryItems;
  final int currentIndex;
  final String? selectedMenu;
  final ValueChanged<int> onPrimaryTap;
  final ValueChanged<WebMenuItem> onMenuTap;
  final List<WebMenuItem> items;
  final bool compact;
  final VoidCallback? onToggle;

  const _BrandSidebar({
    required this.brandTitle,
    required this.primaryItems,
    required this.currentIndex,
    required this.selectedMenu,
    required this.onPrimaryTap,
    required this.onMenuTap,
    required this.items,
    this.compact = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<WebMenuItem>>{};
    for (final item in items) {
      final key = item.group.trim().isEmpty ? 'More' : item.group;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: compact ? 72 : (AppLayout.isTablet(context) ? 200 : 220),
      color: WebTheme.dark,
      child: Column(
        children: [
          SizedBox(height: compact ? 16 : 22),
          Image.asset(
            'assets/flower.png',
            width: compact ? 28 : 34,
            height: compact ? 28 : 34,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.bolt_rounded,
              color: WebTheme.brand,
              size: compact ? 28 : 34,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              brandTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Performance OS',
              style: TextStyle(
                color: Color(0xD9FFFFFF),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              children: [
                if (!compact) _groupLabel('Workspace'),
                for (var i = 0; i < primaryItems.length; i++)
                  _tile(
                    icon: primaryItems[i].icon,
                    label: primaryItems[i].label.trim(),
                    selected: selectedMenu == null && i == currentIndex,
                    onTap: () => onPrimaryTap(i),
                  ),
                for (final entry in grouped.entries) ...[
                  SizedBox(height: compact ? 12 : 22),
                  if (!compact) _groupLabel(entry.key),
                  for (final item in entry.value)
                    _tile(
                      icon: item.icon,
                      label: item.label,
                      selected: item.selected || item.label == selectedMenu,
                      onTap: () => onMenuTap(item),
                    ),
                ],
              ],
            ),
          ),
          if (onToggle != null)
            IconButton(
              tooltip: compact ? 'Expand menu' : 'Collapse menu',
              onPressed: onToggle,
              icon: Icon(
                compact ? Icons.chevron_right : Icons.chevron_left,
                color: Colors.white70,
              ),
            ),
          if (!compact)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 18),
              child: Text(
                'Poornasree Equipments',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _groupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          hoverColor: selected ? Colors.transparent : const Color(0x14FFFFFF),
          child: compact
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : const Color(0xFFF8F1E3),
                      size: 22,
                    ),
                  ),
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: selected
                      ? BoxDecoration(
                          color: WebTheme.brand,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: selected
                            ? Colors.white
                            : const Color(0xD9FFFFFF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xD9FFFFFF),
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
    if (!compact) return tile;
    return Tooltip(message: label, child: tile);
  }
}

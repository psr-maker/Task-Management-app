import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/Models/navrole.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/theme/theme_provider.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/curved_bottom_nav.dart';
import 'package:staff_work_track/core/widgets/greeting_header.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
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
        compact: AppLayout.isTablet(context),
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
  final bool compact;

  const _WebShell({
    required this.currentIndex,
    required this.onTap,
    required this.role,
    required this.pages,
    required this.brandTitle,
    required this.compact,
  });

  @override
  State<_WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<_WebShell> {
  final WebShellController controller = WebShellController();
  bool _sidebarExpanded = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = roleNavItems[widget.role]!;
    final theme = WebTheme.overlay(Theme.of(context));
    final railCompact = widget.compact && !_sidebarExpanded;

    return WebShellScope(
      controller: controller,
      child: Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return _BrandSidebar(
                    brandTitle: widget.brandTitle,
                    primaryItems: items,
                    currentIndex: widget.currentIndex,
                    onPrimaryTap: widget.onTap,
                    items: controller.menuItems,
                    compact: railCompact,
                    onToggle: widget.compact
                        ? () => setState(
                            () => _sidebarExpanded = !_sidebarExpanded,
                          )
                        : null,
                  );
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        return _TopBar(
                          compact: widget.compact,
                          overdueCount: controller.overdueCount,
                          onOverdue: controller.onOverdue,
                          onReports: controller.onReports ??
                              (widget.role == UserRole.superAdmin
                                  ? () => widget.onTap(3)
                                  : null),
                          onSettings: controller.onSettings ??
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Settings(),
                                  ),
                                );
                              },
                        );
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: AppLayout.shellInset(context),
                        child: IndexedStack(
                          index: widget.currentIndex,
                          children: widget.pages,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandSidebar extends StatelessWidget {
  final String brandTitle;
  final List<NavItem> primaryItems;
  final int currentIndex;
  final ValueChanged<int> onPrimaryTap;
  final List<WebMenuItem> items;
  final bool compact;
  final VoidCallback? onToggle;

  const _BrandSidebar({
    required this.brandTitle,
    required this.primaryItems,
    required this.currentIndex,
    required this.onPrimaryTap,
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
      width: compact ? 80 : (AppLayout.isTablet(context) ? 220 : 260),
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Performance OS',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 8 : 14,
                14,
                compact ? 8 : 14,
                12,
              ),
              children: [
                if (!compact) _groupLabel('Workspace'),
                for (var i = 0; i < primaryItems.length; i++)
                  _tile(
                    icon: primaryItems[i].icon,
                    label: primaryItems[i].label.trim(),
                    selected: i == currentIndex,
                    onTap: () => onPrimaryTap(i),
                  ),
                for (final entry in grouped.entries) ...[
                  SizedBox(height: compact ? 8 : 18),
                  if (!compact) _groupLabel(entry.key),
                  for (final item in entry.value)
                    _tile(
                      icon: item.icon,
                      label: item.label,
                      selected: false,
                      onTap: item.onTap,
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
              padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                'Poornasree Equipments',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
      padding: const EdgeInsets.fromLTRB(6, 0, 8, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
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
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: const Color(0x14FFFFFF),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 8,
              vertical: compact ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0x3322C55E) : const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0x6622C55E) : const Color(0x14FFFFFF),
              ),
            ),
            child: compact
                ? Center(
                    child: Icon(
                      icon,
                      color: selected ? WebTheme.brandSoft : Colors.white,
                      size: 20,
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0x3322C55E)
                              : const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          icon,
                          color: selected ? WebTheme.brandSoft : Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
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

class _TopBar extends StatelessWidget {
  final bool compact;
  final int overdueCount;
  final VoidCallback? onOverdue;
  final VoidCallback? onReports;
  final VoidCallback? onSettings;

  const _TopBar({
    required this.compact,
    required this.overdueCount,
    this.onOverdue,
    this.onReports,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WebTheme.headerOf(context),
      child: Container(
        height: compact ? 64 : 76,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: WebTheme.lineOf(context))),
        ),
        child: Row(
          children: [
            const Expanded(child: GreetingHeader()),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return _HeaderIcon(
                  icon: themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: themeProvider.isDarkMode
                      ? 'Light mode'
                      : 'Dark mode',
                  onTap: themeProvider.toggleTheme,
                );
              },
            ),
            _HeaderIcon(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              color: overdueCount > 0 ? WebTheme.danger : null,
              badge: overdueCount,
              onTap: onOverdue,
            ),
            _HeaderIcon(
              icon: Icons.bar_chart_rounded,
              tooltip: 'Reports',
              onTap: onReports,
            ),
            _HeaderIcon(
              icon: Icons.account_circle_outlined,
              tooltip: 'Profile & settings',
              onTap: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  final int badge;

  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color ?? WebTheme.inkOf(context), size: 22),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: const BoxDecoration(
                  color: WebTheme.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

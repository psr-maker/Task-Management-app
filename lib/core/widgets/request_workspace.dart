import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/list_download_button.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/status_badge.dart';

Widget workspaceAction(
  String label,
  VoidCallback? onPressed, {
  bool filled = false,
  Color? color,
}) {
  final tone = color ?? WebTheme.brand;
  if (filled) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: tone,
        foregroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: tone,
      side: BorderSide(color: tone),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    child: Text(label),
  );
}

class WorkspaceStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const WorkspaceStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class WorkspaceRecord {
  final List<String> values;
  final String status;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final Color? approvedColor;

  const WorkspaceRecord({
    required this.values,
    this.status = '',
    this.onTap,
    this.actions = const [],
    this.approvedColor,
  });
}

class RequestWorkspace extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<WorkspaceStat> stats;
  final List<String> columns;
  final List<WorkspaceRecord> records;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String>? onFilter;
  final Widget? trailing;
  final String? downloadTitle;
  final Widget? banner;
  final bool loading;
  final bool asCards;
  final bool scrollable;
  final bool plainStatus;
  final String emptyTitle;
  final String emptyMessage;

  const RequestWorkspace({
    super.key,
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.records,
    this.stats = const [],
    this.filters = const [],
    this.selectedFilter = 'All',
    this.onFilter,
    this.trailing,
    this.downloadTitle,
    this.banner,
    this.loading = false,
    this.asCards = false,
    this.scrollable = false,
    this.plainStatus = false,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage = 'New records will show up in this view.',
  });

  @override
  State<RequestWorkspace> createState() => _RequestWorkspaceState();
}

class _RequestWorkspaceState extends State<RequestWorkspace> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _search.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  bool get _hasStatus {
    return widget.records.any((record) => record.status.trim().isNotEmpty);
  }

  List<String> _downloadHeaders() {
    return [...widget.columns, if (_hasStatus) 'Status'];
  }

  List<List<String>> _downloadRows() {
    return [
      for (final record in _visible)
        [...record.values, if (_hasStatus) record.status],
    ];
  }

  List<WorkspaceRecord> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.records;
    return widget.records.where((record) {
      final haystack = [
        record.status,
        ...record.values,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final records = _visible;
    return Padding(
      padding: AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(Icons.arrow_back, color: WebTheme.inkOf(context)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppLayout.isDesktop(context) ? 24 : 20,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: WebTheme.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.downloadTitle != null) ...[
                const SizedBox(width: 8),
                ListDownloadButton(
                  title: widget.downloadTitle!,
                  headers: _downloadHeaders(),
                  rows: _downloadRows,
                ),
              ],
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
          if (widget.stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            _stats(),
          ],
          if (widget.banner != null) ...[
            const SizedBox(height: 12),
            widget.banner!,
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: WebTheme.surfaceOf(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: WebTheme.lineOf(context)),
                boxShadow: WebTheme.cardShadow(context),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _toolbar(),
                  Divider(height: 1, color: WebTheme.lineOf(context)),
                  Expanded(child: _body(records)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final cards = [
          for (final stat in widget.stats) _statCard(stat),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(width: (constraints.maxWidth - 10) / 2, child: card),
          ],
        );
      },
    );
  }

  Widget _statCard(WorkspaceStat stat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, size: 18, color: stat.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WebTheme.inkOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WebTheme.mutedOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search',
              hintStyle: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
              prefixIcon: Icon(Icons.search, size: 18, color: WebTheme.mutedOf(context)),
              filled: true,
              fillColor: WebTheme.canvasOf(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: WebTheme.brand),
              ),
            ),
          ),
          if (widget.filters.length > 1) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in widget.filters) ...[
                      _filterChip(filter),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String filter) {
    final selected = widget.selectedFilter == filter;
    return Material(
      color: selected ? WebTheme.brand : WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onFilter?.call(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? WebTheme.brand : WebTheme.lineOf(context),
            ),
          ),
          child: Text(
            filter,
            style: TextStyle(
              color: selected ? Colors.white : WebTheme.inkOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(List<WorkspaceRecord> records) {
    if (widget.loading) return const Center(child: RotatingFlower());
    if (records.isEmpty) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: widget.emptyTitle,
        message: widget.emptyMessage,
      );
    }
    final useCards = widget.asCards || !AppLayout.isDesktop(context);
    if (useCards) return _cardBoard(records);
    if (widget.scrollable) return _scrollTable(records);
    return _table(records);
  }

  Widget _table(List<WorkspaceRecord> records) {
    final hasStatus = records.any((record) => record.status.trim().isNotEmpty);
    final hasActions = records.any((record) => record.actions.isNotEmpty);
    return Column(
      children: [
        Container(
          color: WebTheme.brandSoftOf(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              for (final column in widget.columns)
                Expanded(child: _head(column)),
              if (hasStatus) const Expanded(child: _HeadLabel('Status')),
              if (hasActions) const SizedBox(width: 220),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: WebTheme.lineOf(context)),
            itemBuilder: (context, index) {
              final record = records[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: record.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        for (final value in record.values)
                          Expanded(child: _valueText(value)),
                        if (hasStatus)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _statusLabel(record),
                            ),
                          ),
                        if (hasActions)
                          SizedBox(
                            width: 220,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.end,
                              children: record.actions,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cardBoard(List<WorkspaceRecord> records) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (var i = 0; i < records.length; i += columns)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: 12),
                      Expanded(
                        child: i + column < records.length
                            ? _recordCard(records[i + column])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _recordCard(WorkspaceRecord record) {
    return Material(
      color: WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: record.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.values.isEmpty ? '—' : record.values.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebTheme.inkOf(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (record.status.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _statusLabel(record),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              for (var i = 1; i < record.values.length && i < widget.columns.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 88,
                        child: Text(
                          widget.columns[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: WebTheme.mutedOf(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: _valueText(record.values[i])),
                    ],
                  ),
                ),
              if (record.actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: record.actions),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scrollTable(List<WorkspaceRecord> records) {
    final hasStatus = records.any((record) => record.status.trim().isNotEmpty);
    final hasActions = records.any((record) => record.actions.isNotEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
          final widths = _columnWidths(records);
          final statusWidth = hasStatus ? _statusWidth(records) : 0.0;
          final actionWidth = hasActions ? 210.0 : 0.0;
          const rowPad = 32.0;
          final contentWidth =
              widths.fold<double>(0, (sum, width) => sum + width) +
              statusWidth +
              actionWidth +
              rowPad;
          final tableWidth = contentWidth < constraints.maxWidth
              ? constraints.maxWidth
              : contentWidth;
          final extra = tableWidth > contentWidth && widths.isNotEmpty
              ? (tableWidth - contentWidth) / widths.length
              : 0.0;
          return Scrollbar(
            controller: _horizontal,
            thumbVisibility: contentWidth > constraints.maxWidth,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Container(
                      color: WebTheme.brandSoftOf(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.columns.length; i++)
                            SizedBox(
                              width: widths[i] + extra,
                              child: _head(widget.columns[i]),
                            ),
                          if (hasStatus)
                            SizedBox(
                              width: statusWidth,
                              child: const _HeadLabel('Status'),
                            ),
                          if (hasActions) const SizedBox(width: 210),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: WebTheme.lineOf(context),
                        ),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: record.onTap,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    for (var i = 0; i < widget.columns.length; i++)
                                      SizedBox(
                                        width: widths[i] + extra,
                                        child: _valueText(
                                          i < record.values.length
                                              ? record.values[i]
                                              : '',
                                        ),
                                      ),
                                    if (hasStatus)
                                      SizedBox(
                                        width: statusWidth,
                                        child: _statusLabel(record),
                                      ),
                                    if (hasActions)
                                      SizedBox(
                                        width: 210,
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          alignment: WrapAlignment.end,
                                          children: record.actions,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
      },
    );
  }

  double _statusWidth(List<WorkspaceRecord> records) {
    double measure(String text) => (text.length * 8.2 + 28).clamp(120.0, 180.0);
    return records.fold<double>(measure('Status'), (width, record) {
      final need = measure(record.status);
      return need > width ? need : width;
    });
  }

  List<double> _columnWidths(List<WorkspaceRecord> records) {
    double measure(String text) {
      final longest = text
          .split('\n')
          .fold<int>(0, (max, line) => line.length > max ? line.length : max);
      return (longest * 7.2 + 28).clamp(110.0, 260.0);
    }

    return [
      for (var i = 0; i < widget.columns.length; i++)
        records.fold<double>(measure(widget.columns[i]), (width, record) {
          if (i >= record.values.length) return width;
          final need = measure(record.values[i]);
          return need > width ? need : width;
        }),
    ];
  }

  Widget _statusLabel(WorkspaceRecord record) {
    if (record.status.trim().isEmpty) return const SizedBox.shrink();
    if (!widget.plainStatus) {
      return StatusBadge(
        record.status,
        approvedColor: record.approvedColor,
      );
    }
    final color = record.approvedColor != null &&
            record.status.toLowerCase().contains('approv')
        ? record.approvedColor!
        : StatusBadge.foreground(record.status);
    return Text(
      record.status.trim(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _head(String label) => _HeadLabel(label);

  Widget _valueText(String value) {
    return Text(
      value.trim().isEmpty ? '—' : value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: WebTheme.inkOf(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _HeadLabel extends StatelessWidget {
  final String label;

  const _HeadLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: WebTheme.brandOf(context),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

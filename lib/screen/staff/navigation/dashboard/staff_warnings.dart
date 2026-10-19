import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class StaffWarningsPage extends StatefulWidget {
  final int userId;
  final bool departmentScope;
  final bool companyScope;
  final String department;
  final String personName;
  final String initialDepartment;
  final List<String> filterDepartments;

  const StaffWarningsPage({
    super.key,
    required this.userId,
    this.departmentScope = false,
    this.companyScope = false,
    this.department = '',
    this.personName = '',
    this.initialDepartment = '',
    this.filterDepartments = const [],
  });

  @override
  State<StaffWarningsPage> createState() => _StaffWarningsPageState();
}

class _StaffWarningsPageState extends State<StaffWarningsPage> {
  List<WarningModel> warnings = [];
  List<String> departments = [];
  String selectedDepartment = 'All';
  bool isLoading = true;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    final opening = widget.initialDepartment.trim();
    if (opening.isNotEmpty) selectedDepartment = opening;
    loadWarnings();
  }

  List<WarningModel> _forPerson(
    List<WarningModel> items, {
    required bool fromUserEndpoint,
  }) {
    final matched = items
        .where(
          (item) => item.belongsToUser(
            widget.userId,
            name: widget.personName,
          ),
        )
        .toList();
    if (matched.isNotEmpty) return matched;
    if (fromUserEndpoint &&
        items.isNotEmpty &&
        items.every((item) => item.receiverId == 0)) {
      return items;
    }
    return matched;
  }

  bool get _divisionScope =>
      widget.departmentScope && widget.filterDepartments.isNotEmpty;

  List<String> _uniqueDepartments(Iterable<String> values) {
    final names = <String>[];
    for (final value in values) {
      final name = value.trim();
      if (name.isEmpty) continue;
      if (names.any((item) => DivisionConfig.isAllowedDepartment(name, [item]))) {
        continue;
      }
      names.add(name);
    }
    return names;
  }

  List<WarningModel> _forDepartment(List<WarningModel> items) {
    final allowed = _uniqueDepartments([
      ...widget.filterDepartments,
      widget.department,
    ]);
    if (allowed.isEmpty) return items;
    return items
        .where(
          (item) => allowed.any((name) => item.belongsToDepartment(name)),
        )
        .toList();
  }

  List<WarningModel> get _visible {
    final canFilter = widget.companyScope || _divisionScope;
    if (!canFilter || selectedDepartment == 'All') return warnings;
    return warnings
        .where((item) => item.belongsToDepartment(selectedDepartment))
        .toList();
  }

  Future<List<String>> _divisionDepartments() async {
    final names = <String>[...widget.filterDepartments, widget.department];
    final head = widget.department.trim();
    try {
      names.addAll(
        await AdminService.getMySubDepartments(
          headDepartment: head.isEmpty ? null : head,
        ),
      );
    } catch (_) {}
    return names;
  }

  Future<List<String>> _companyDepartments() async {
    final names = <String>[...widget.filterDepartments];
    try {
      names.addAll(await ReportsService.getAllDepartments());
    } catch (_) {}
    return names;
  }

  List<String> _departmentNames(List<WarningModel> items, List<String> known) {
    final names = <String>[];
    void add(String value) {
      final name = value.trim();
      if (name.isEmpty) return;
      if (names.any((item) => DivisionConfig.isAllowedDepartment(name, [item]))) {
        return;
      }
      names.add(name);
    }

    for (final name in known) {
      add(name);
    }
    for (final item in items) {
      add(item.receiverDept);
    }
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  void _selectDepartment(String name) {
    final visible = name == 'All'
        ? warnings
        : warnings.where((item) => item.belongsToDepartment(name)).toList();
    setState(() {
      selectedDepartment = name;
      selectedIndex = !AppLayout.isMobile(context) && visible.isNotEmpty ? 0 : null;
    });
  }

  Future<void> loadWarnings() async {
    if (widget.companyScope) {
      try {
        final data = await AnnouncementService.getWarnings();
        final known = await _companyDepartments();
        if (!mounted) return;
        _apply(data, departments: _departmentNames(data, known));
      } catch (_) {
        if (!mounted) return;
        setState(() => isLoading = false);
        showAppMessage(context, 'Failed to load warnings');
      }
      return;
    }
    if (widget.departmentScope) {
      try {
        final data = await AnnouncementService.getWarnings();
        if (_divisionScope) {
          final known = _uniqueDepartments(await _divisionDepartments());
          final scoped = data
              .where(
                (item) => known.any((name) => item.belongsToDepartment(name)),
              )
              .toList();
          if (!mounted) return;
          _apply(scoped, departments: _departmentNames(scoped, known));
        } else {
          if (!mounted) return;
          _apply(_forDepartment(data));
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => isLoading = false);
        showAppMessage(context, 'Failed to load warnings');
      }
      return;
    }
    List<WarningModel> data = [];
    try {
      data = _forPerson(
        await AnnouncementService.getWarningsByUser(widget.userId),
        fromUserEndpoint: true,
      );
    } catch (_) {}
    if (data.isEmpty) {
      try {
        data = _forPerson(
          await AnnouncementService.getWarnings(),
          fromUserEndpoint: false,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => isLoading = false);
        showAppMessage(context, 'Failed to load warnings');
        return;
      }
    }
    if (!mounted) return;
    _apply(data);
  }

  void _apply(List<WarningModel> data, {List<String> departments = const []}) {
    final next = [...data]
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    var selected = selectedDepartment;
    if (selected != 'All') {
      for (final name in departments) {
        if (DivisionConfig.isAllowedDepartment(selected, [name])) {
          selected = name;
          break;
        }
      }
    }
    final visible = selected == 'All'
        ? next
        : next.where((item) => item.belongsToDepartment(selected)).toList();
    setState(() {
      warnings = next;
      this.departments = departments;
      selectedDepartment = selected;
      isLoading = false;
      if (!AppLayout.isMobile(context) && visible.isNotEmpty) {
        selectedIndex = 0;
      }
    });
  }

  String _shown(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _shortDepartment(String name) {
    final short = name
        .replaceAll(RegExp(r'\s+department$', caseSensitive: false), '')
        .trim();
    return short.isEmpty ? name : short;
  }

  Color _levelColor(String severity) {
    final value = severity.toLowerCase();
    if (value.contains('crit') || value.contains('high')) return WebTheme.danger;
    if (value.contains('med')) return const Color(0xFFD97706);
    if (value.contains('low')) {
      return WebTheme.isDark(context)
          ? const Color(0xFF86EFAC)
          : const Color(0xFF166534);
    }
    return WebTheme.brandOf(context);
  }

  void _open(int index) {
    if (AppLayout.isMobile(context)) {
      setState(() => selectedIndex = index);
      return;
    }
    setState(() => selectedIndex = index);
  }

  void _back() {
    if (AppLayout.isMobile(context) && selectedIndex != null) {
      setState(() => selectedIndex = null);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppLayout.isMobile(context);
    final visible = _visible;
    final showingDetail = mobile && selectedIndex != null && selectedIndex! < visible.length;
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      appBar: AppBar(
        backgroundColor: WebTheme.brand,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _back,
        ),
        title: Text(
          showingDetail ? 'Warning details' : 'Warnings',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : Column(
              children: [
                if ((widget.companyScope || _divisionScope) && !showingDetail)
                  _departmentFilter(),
                Expanded(
                  child: mobile
                      ? (visible.isEmpty
                            ? _empty()
                            : showingDetail
                            ? _detail(visible[selectedIndex!])
                            : _list(true, visible))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 360,
                              child: visible.isEmpty ? _empty() : _list(false, visible),
                            ),
                            VerticalDivider(width: 1, color: WebTheme.lineOf(context)),
                            Expanded(
                              child: selectedIndex == null || selectedIndex! >= visible.length
                                  ? const AppEmptyState(
                                      icon: Icons.warning_amber_rounded,
                                      title: 'Select a warning',
                                      message: 'Choose a warning to see the details.',
                                    )
                                  : _detail(visible[selectedIndex!]),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _empty() {
    final filtered = (widget.companyScope || _divisionScope) &&
        selectedDepartment != 'All';
    return AppEmptyState(
      icon: Icons.warning_amber_rounded,
      title: 'No warnings',
      message: filtered || widget.department.trim().isNotEmpty
          ? 'Warnings for this department will appear here.'
          : _divisionScope
          ? 'Warnings for your departments will appear here.'
          : widget.companyScope
          ? 'Company warnings will appear here.'
          : widget.departmentScope
          ? 'Warnings for your department will appear here.'
          : 'Warnings sent to this user will appear here.',
    );
  }

  Widget _departmentFilter() {
    final options = ['All', ...departments];
    final ink = WebTheme.inkOf(context);
    final surface = WebTheme.surfaceOf(context);
    return Material(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in options)
                _departmentChip(
                  label: name == 'All' ? 'All' : _shortDepartment(name),
                  count: name == 'All'
                      ? warnings.length
                      : warnings.where((item) => item.belongsToDepartment(name)).length,
                  selected: selectedDepartment == name,
                  ink: ink,
                  surface: surface,
                  onTap: () => _selectDepartment(name),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _departmentChip({
    required String label,
    required int count,
    required bool selected,
    required Color ink,
    required Color surface,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? ink : surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? ink : WebTheme.lineOf(context)),
          ),
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? surface : ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(bool mobile, List<WarningModel> items) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: WebTheme.lineOf(context)),
      itemBuilder: (context, index) {
        final warning = items[index];
        final selected = selectedIndex == index;
        final levelColor = _levelColor(warning.severity);
        return Material(
          color: selected
              ? levelColor.withValues(alpha: 0.12)
              : WebTheme.surfaceOf(context),
          child: InkWell(
            onTap: () => _open(index),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: selected ? levelColor : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: levelColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shown(warning.title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? levelColor : WebTheme.inkOf(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.companyScope || widget.departmentScope
                              ? '${_shown(warning.receiverName)}  •  ${_shown(warning.severity)}'
                              : '${_shown(warning.severity)}  •  ${_shown(warning.senderName)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mobile) Icon(Icons.chevron_right_rounded, color: levelColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detail(WarningModel warning) {
    final levelColor = _levelColor(warning.severity);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _shown(warning.title),
          style: TextStyle(
            color: levelColor,
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          TimeUtils.formatDate(warning.createdDate),
          style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 13),
        ),
        const SizedBox(height: 16),
        Text(
          _shown(warning.message),
          style: TextStyle(
            color: WebTheme.inkOf(context),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Divider(color: WebTheme.lineOf(context)),
        const SizedBox(height: 8),
        _row('Level', _shown(warning.severity), valueColor: levelColor),
        _row('Escalation count', '${warning.escalationLevel}', valueColor: levelColor),
        if (widget.departmentScope || widget.companyScope) ...[
          _row('Receiver name', _shown(warning.receiverName)),
          _row('Receiver department', _shown(warning.receiverDept)),
        ],
        _row('Sender name', _shown(warning.senderName)),
        _row('Sender department', _shown(warning.senderDept)),
      ],
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    final labelText = Text(
      label,
      style: TextStyle(
        color: WebTheme.mutedOf(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
    final valueText = Text(
      value,
      style: TextStyle(
        color: valueColor ?? WebTheme.inkOf(context),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
    if (AppLayout.isMobile(context)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelText,
            const SizedBox(height: 2),
            valueText,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: labelText),
          Expanded(child: valueText),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class HrWarningsPage extends StatefulWidget {
  const HrWarningsPage({super.key});

  @override
  State<HrWarningsPage> createState() => _HrWarningsPageState();
}

class _HrWarningsPageState extends State<HrWarningsPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _selected = <int>{};
  final _deptFilter = <String>{};

  List<UserModel> _users = [];
  List<WarningModel> _warnings = [];
  String _severity = 'High';
  String _query = '';
  String _senderName = 'HR';
  String? _historyDepartment;
  bool _issued = false;
  bool _loadingPeople = true;
  bool _loadingWarnings = true;
  bool _sending = false;
  String? _peopleError;
  String? _warningError;

  static const _levels = ['Low', 'Medium', 'High', 'Critical'];
  static const _messageLimit = 500;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessage);
    _loadSender();
    _loadPeople();
    _loadWarnings();
    _loadRoleNames();
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessage);
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMessage() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSender() async {
    final token = await AuthService.getToken();
    if (!mounted || token == null || token.isEmpty) return;
    final name = JwtHelper.displayName(token).trim();
    if (name.isEmpty || name == 'there' || int.tryParse(name) != null) return;
    setState(() => _senderName = name);
  }

  Future<void> _loadPeople() async {
    setState(() {
      _loadingPeople = true;
      _peopleError = null;
    });
    try {
      final people = await _fetchPeople();
      if (!mounted) return;
      setState(() {
        _users = people;
        _loadingPeople = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPeople = false;
        _peopleError = 'Could not load staff.';
      });
    }
  }

  Future<List<UserModel>> _fetchPeople() async {
    try {
      final all = await SuperAdminService.getAllUsers();
      if (all.isNotEmpty) return all;
    } catch (_) {}

    final departments = await SuperAdminService().getDepartments();
    final names = <String>{};
    for (final department in departments) {
      final name = department.departmentName.trim();
      if (name.isNotEmpty) names.add(name);
      final sub = (department.subDepartment ?? '').trim();
      if (sub.isNotEmpty) names.add(sub);
    }
    return AdminService.getEmployeesByDepartments(names.toList());
  }

  Future<void> _loadWarnings() async {
    setState(() {
      _loadingWarnings = true;
      _warningError = null;
    });
    try {
      final warnings = await AnnouncementService.getHrWarnings();
      if (!mounted) return;
      setState(() {
        _warnings = warnings;
        _loadingWarnings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingWarnings = false;
        _warningError = 'Could not load warnings.';
      });
    }
  }

  Map<String, List<UserModel>> get _usersByDepartment {
    final grouped = <String, List<UserModel>>{};
    for (final user in _users) {
      if (user.userId <= 0) continue;
      final department = user.department.trim().isEmpty
          ? 'Unassigned'
          : user.department.trim();
      grouped.putIfAbsent(department, () => []).add(user);
    }
    for (final people in grouped.values) {
      people.sort(
        (a, b) => _personName(a).toLowerCase().compareTo(
          _personName(b).toLowerCase(),
        ),
      );
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return Map.fromEntries(entries);
  }

  List<UserModel> get _visiblePeople {
    final query = _query.trim().toLowerCase();
    final people = <UserModel>[];
    for (final entry in _usersByDepartment.entries) {
      if (_deptFilter.isNotEmpty && !_deptFilter.contains(entry.key)) continue;
      for (final user in entry.value) {
        if (query.isEmpty) {
          people.add(user);
          continue;
        }
        final name = _personName(user).toLowerCase();
        final role = _roleLabel(user.role).toLowerCase();
        if (name.contains(query) || role.contains(query)) people.add(user);
      }
    }
    return people;
  }

  Map<int, UserModel> get _userById => {
    for (final user in _users) user.userId: user,
  };

  Map<String, List<WarningModel>> get _warningsByDepartment {
    final grouped = <String, List<WarningModel>>{};
    for (final warning in _warnings) {
      grouped.putIfAbsent(_departmentOf(warning), () => []).add(warning);
    }
    for (final items in grouped.values) {
      items.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map.fromEntries(entries);
  }

  List<MapEntry<String, int>> get _departmentCounts {
    final counts = <String, int>{
      for (final department in _usersByDepartment.keys) department: 0,
    };
    for (final entry in _warningsByDepartment.entries) {
      counts[entry.key] = entry.value.length;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return entries;
  }

  List<WarningModel> get _visibleWarnings {
    if (_historyDepartment == null) {
      return _warningsByDepartment.values.expand((items) => items).toList();
    }
    return List<WarningModel>.from(
      _warningsByDepartment[_historyDepartment] ?? const [],
    );
  }

  String _departmentOf(WarningModel warning) {
    final fromWarning = warning.receiverDept.trim();
    if (fromWarning.isNotEmpty) return fromWarning;
    final department = _userById[warning.receiverId]?.department.trim() ?? '';
    return department.isEmpty ? 'Unknown' : department;
  }

  String _personName(UserModel user) {
    final name = user.displayName.trim();
    if (name.isNotEmpty) return name;
    return 'Staff ${user.userId}';
  }

  Future<void> _loadRoleNames() async {
    await SuperAdminService.ensureRolesLoaded();
    if (mounted) setState(() {});
  }

  String _roleLabel(String role) {
    final name = AppRoles.displayName(role);
    if (name.isNotEmpty) return name;
    final value = role.trim();
    if (value.isEmpty || int.tryParse(value) != null) return 'Staff';
    return value;
  }

  String _shortDepartment(String name) {
    final short = name
        .replaceAll(RegExp(r'\s*department$', caseSensitive: false), '')
        .trim();
    return short.isEmpty ? name : short;
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  void _toggleUser(int userId) {
    setState(() {
      if (!_selected.remove(userId)) _selected.add(userId);
    });
  }

  void _toggleVisible(List<UserModel> people) {
    final ids = people.map((user) => user.userId).toSet();
    final allSelected = ids.isNotEmpty && ids.every(_selected.contains);
    setState(() {
      if (allSelected) {
        _selected.removeAll(ids);
      } else {
        _selected.addAll(ids);
      }
    });
  }

  void _toggleDepartmentFilter(String department) {
    setState(() {
      if (!_deptFilter.remove(department)) _deptFilter.add(department);
    });
  }

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    _searchController.clear();
    setState(() {
      _selected.clear();
      _deptFilter.clear();
      _query = '';
      _severity = 'High';
    });
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      showAppMessage(context, 'Enter a title and message.');
      return;
    }
    if (_selected.isEmpty) {
      showAppMessage(context, 'Select at least one staff member.');
      return;
    }

    setState(() => _sending = true);
    var failed = 0;
    for (final userId in _selected.toList()) {
      try {
        await AnnouncementService().sendWarning(
          receiverId: userId,
          title: title,
          message: message,
          severity: _severity,
        );
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() => _sending = false);

    final sent = _selected.length - failed;
    if (sent == 0) {
      showAppMessage(context, 'Warning could not be sent.');
      return;
    }

    _titleController.clear();
    _messageController.clear();
    setState(() => _selected.clear());
    showAppMessage(
      context,
      failed == 0
          ? 'Warning sent to $sent staff.'
          : 'Sent to $sent staff. $failed could not be sent.',
      isError: failed != 0,
    );
    await _loadWarnings();
    if (!mounted) return;
    setState(() => _issued = true);
  }

  Map<String, List<UserModel>> get _visibleGroups {
    final grouped = <String, List<UserModel>>{};
    for (final user in _visiblePeople) {
      final department = user.department.trim().isEmpty
          ? 'Unassigned'
          : user.department.trim();
      grouped.putIfAbsent(department, () => []).add(user);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final web = WebPushedChrome.isWeb(context);
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      appBar: web
          ? null
          : AppBar(
              elevation: 0,
              title: Text(_issued ? 'Warning history' : 'Send warning'),
              leading: BackButton(
                onPressed: () {
                  if (_issued) {
                    setState(() => _issued = false);
                    return;
                  }
                  Navigator.maybePop(context);
                },
              ),
              actions: [
                if (!_issued)
                  IconButton(
                    tooltip: 'History',
                    onPressed: () => setState(() => _issued = true),
                    icon: const Icon(Icons.history_rounded),
                  ),
              ],
            ),
      body: Padding(
        padding: web
            ? AppLayout.pagePadding(context)
            : const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (web) ...[
              _header(context),
              const SizedBox(height: 16),
            ],
            Expanded(child: _issued ? _history(context) : _workspace(context)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: _issued ? 'Back to send' : 'Back',
          onPressed: () {
            if (_issued) {
              setState(() => _issued = false);
              return;
            }
            Navigator.maybePop(context);
          },
          icon: Icon(Icons.arrow_back_rounded, color: WebTheme.inkOf(context)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _issued ? 'Warning history' : 'Send warning',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: WebTheme.inkOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _issued
                    ? 'Warning totals for every department'
                    : 'From $_senderName',
                style: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _issued = !_issued),
          style: OutlinedButton.styleFrom(
            foregroundColor: WebTheme.inkOf(context),
            side: BorderSide(color: WebTheme.lineOf(context)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            _issued ? 'New warning' : 'History',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _workspace(BuildContext context) {
    if (AppLayout.isMobile(context)) return _mobileSend(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final split = constraints.maxWidth >= 920;
        if (!split) {
          return ListView(
            children: [
              _recipients(context, scrollInside: false),
              const SizedBox(height: 12),
              _details(context, pinActions: false),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _recipients(context, scrollInside: true)),
            const SizedBox(width: 16),
            Expanded(child: _details(context, pinActions: true)),
          ],
        );
      },
    );
  }

  Future<void> _openUserPicker() async {
    final picked = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => _DeptUserPicker(
          users: _users,
          selected: Set<int>.of(_selected),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(picked);
    });
  }

  String get _selectedUsersLabel {
    final names = <String>[];
    for (final id in _selected) {
      final user = _userById[id];
      if (user != null) names.add(_personName(user));
    }
    if (names.isEmpty) return '';
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2}';
  }

  Widget _mobileSend(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        _surface(
          context,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, 'Select users'),
              const SizedBox(height: 6),
              _userField(context),
              const SizedBox(height: 14),
              _label(context, 'Warning title'),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 13, color: WebTheme.inkOf(context)),
                decoration: _field(context, 'Enter warning title'),
              ),
              const SizedBox(height: 14),
              _label(context, 'Severity'),
              const SizedBox(height: 6),
              for (final level in _levels) ...[
                _mobileSeverity(context, level),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _label(context, 'Message')),
                  Text(
                    '${_messageController.text.length} / $_messageLimit',
                    style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                minLines: 4,
                maxLines: 6,
                maxLength: _messageLimit,
                style: TextStyle(fontSize: 13, height: 1.4, color: WebTheme.inkOf(context)),
                decoration: _field(context, 'Enter warning message').copyWith(
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: WebTheme.brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: WebTheme.brand.withValues(alpha: 0.45),
                  minimumSize: const Size.fromHeight(44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send warning',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
              ),
              // TextButton.icon(
              //   onPressed: () => setState(() => _issued = true),
              //   icon: const Icon(Icons.history_rounded, size: 18),
              //   label: const Text('View history'),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _userField(BuildContext context) {
    final label = _selectedUsersLabel;
    return Material(
      color: WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _openUserPicker,
        child: InputDecorator(
          decoration: _field(context, 'Select users').copyWith(
            suffixIcon: IconButton(
              tooltip: 'Filter departments',
              onPressed: _openUserPicker,
              icon: Icon(
                Icons.filter_alt_outlined,
                color: WebTheme.inkOf(context),
              ),
            ),
          ),
          child: Text(
            label.isEmpty ? 'Select users' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: label.isEmpty
                  ? WebTheme.mutedOf(context)
                  : WebTheme.inkOf(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileSeverity(BuildContext context, String level) {
    final selected = _severity == level;
    final color = _severityColor(level);
    return Material(
      color: selected ? color.withValues(alpha: 0.08) : WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _severity = level),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : WebTheme.lineOf(context),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : WebTheme.inkOf(context),
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: selected ? color : WebTheme.lineOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipients(BuildContext context, {required bool scrollInside}) {
    return _surface(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  context,
                  'Recipients',
                  trailing: '$_selectedCount selected',
                ),
                const SizedBox(height: 14),
                _label(context, 'Department'),
                const SizedBox(height: 8),
                _departmentFilters(context),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  style: TextStyle(fontSize: 14, color: WebTheme.inkOf(context)),
                  decoration: _field(context, 'Search name or role').copyWith(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: WebTheme.mutedOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (scrollInside)
            Expanded(child: _directory(context))
          else
            SizedBox(height: 360, child: _directory(context)),
        ],
      ),
    );
  }

  int get _selectedCount => _selected.length;

  Widget _departmentFilters(BuildContext context) {
    final departments = _usersByDepartment;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _filter(
          context,
          label: 'All',
          count: _users.length,
          selected: _deptFilter.isEmpty,
          onTap: () => setState(_deptFilter.clear),
        ),
        for (final entry in departments.entries)
          _filter(
            context,
            label: _shortDepartment(entry.key),
            count: entry.value.length,
            selected: _deptFilter.contains(entry.key),
            onTap: () => _toggleDepartmentFilter(entry.key),
          ),
      ],
    );
  }

  Widget _filter(
    BuildContext context, {
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ink = WebTheme.inkOf(context);
    final surface = WebTheme.surfaceOf(context);
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

  Widget _directory(BuildContext context) {
    if (_loadingPeople) {
      return const Center(child: RotatingFlower(size: 32));
    }
    if (_peopleError != null) {
      return _status(context, _peopleError!, onRetry: _loadPeople);
    }
    final groups = _visibleGroups;
    if (groups.isEmpty) {
      return _status(
        context,
        _users.isEmpty ? 'No staff found.' : 'No matching staff.',
      );
    }
    final people = _visiblePeople;
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        _selectRow(context, people),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              _shortDepartment(entry.key).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: WebTheme.mutedOf(context),
              ),
            ),
          ),
          for (final user in entry.value) _person(context, user),
        ],
      ],
    );
  }

  Widget _selectRow(BuildContext context, List<UserModel> people) {
    final selected = people.where((user) => _selected.contains(user.userId)).length;
    final all = people.isNotEmpty && selected == people.length;
    return InkWell(
      onTap: people.isEmpty ? null : () => _toggleVisible(people),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
        child: Row(
          children: [
            _box(context, checked: all, partial: selected > 0 && !all),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select everyone shown',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: WebTheme.inkOf(context),
                ),
              ),
            ),
            Text(
              '$selected of ${people.length}',
              style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _person(BuildContext context, UserModel user) {
    final selected = _selected.contains(user.userId);
    final name = _personName(user);
    return Material(
      color: selected ? WebTheme.brandSoftOf(context) : Colors.transparent,
      child: InkWell(
        onTap: () => _toggleUser(user.userId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          child: Row(
            children: [
              _box(context, checked: selected),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 16,
                backgroundColor: selected
                    ? WebTheme.surfaceOf(context)
                    : WebTheme.brandSoftOf(context),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.brand,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                    Text(
                      _roleLabel(user.role),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.mutedOf(context),
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

  Widget _box(
    BuildContext context, {
    required bool checked,
    bool partial = false,
  }) {
    final color = checked || partial ? WebTheme.brand : WebTheme.lineOf(context);
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked || partial ? WebTheme.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Icon(
        partial ? Icons.remove_rounded : Icons.check_rounded,
        size: 14,
        color: checked || partial ? Colors.white : Colors.transparent,
      ),
    );
  }

  Widget _details(BuildContext context, {required bool pinActions}) {
    final fields = <Widget>[
      _sectionTitle(context, 'Warning'),
      const SizedBox(height: 16),
      _label(context, 'Title'),
      const SizedBox(height: 6),
      TextField(
        controller: _titleController,
        textInputAction: TextInputAction.next,
        style: TextStyle(fontSize: 14, color: WebTheme.inkOf(context)),
        decoration: _field(context, 'Short, specific title'),
      ),
      const SizedBox(height: 16),
      _label(context, 'Severity'),
      const SizedBox(height: 6),
      _severityControl(context),
      const SizedBox(height: 8),
      Text(
        _severityHelp(_severity),
        style: TextStyle(fontSize: 12, height: 1.35, color: WebTheme.mutedOf(context)),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _label(context, 'Message')),
          Text(
            '${_messageController.text.length} / $_messageLimit',
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _messageController,
        minLines: 6,
        maxLines: 8,
        maxLength: _messageLimit,
        style: TextStyle(fontSize: 14, height: 1.4, color: WebTheme.inkOf(context)),
        decoration: _field(context, 'What happened, and what should change.').copyWith(
          counterText: '',
          alignLabelWithHint: true,
        ),
      ),
    ];

    return _surface(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pinActions)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                children: fields,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: fields,
              ),
            ),
          _actions(context),
        ],
      ),
    );
  }

  Widget _severityControl(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < _levels.length; i++)
            Expanded(child: _severitySegment(context, _levels[i], i > 0)),
        ],
      ),
    );
  }

  Widget _severitySegment(BuildContext context, String level, bool divider) {
    final selected = _severity == level;
    final color = _severityColor(level);
    return InkWell(
      onTap: () => setState(() => _severity = level),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            left: divider
                ? BorderSide(color: WebTheme.lineOf(context))
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                level,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : WebTheme.inkOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final button = FilledButton(
      onPressed: _sending ? null : _send,
      style: FilledButton.styleFrom(
        backgroundColor: WebTheme.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: WebTheme.brand.withValues(alpha: 0.45),
        minimumSize: const Size(0, 42),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _sending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Send warning', style: TextStyle(fontWeight: FontWeight.w700)),
    );
    final clear = TextButton(
      onPressed: _sending ? null : _clearForm,
      child: Text(
        'Clear',
        style: TextStyle(fontWeight: FontWeight.w600, color: WebTheme.mutedOf(context)),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: WebTheme.lineOf(context))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summary = Text.rich(
            _summary(context),
            style: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
          );
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [clear, const SizedBox(width: 4), button],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: summary),
              clear,
              const SizedBox(width: 4),
              button,
            ],
          );
        },
      ),
    );
  }

  TextSpan _summary(BuildContext context) {
    final count = _selected.length;
    final strong = TextStyle(color: WebTheme.inkOf(context), fontWeight: FontWeight.w700);
    if (count == 0) return const TextSpan(text: 'No recipients selected');
    final departments = <String>{};
    for (final id in _selected) {
      final user = _userById[id];
      if (user == null) continue;
      final name = user.department.trim().isEmpty ? 'Unassigned' : user.department;
      departments.add(_shortDepartment(name));
    }
    final names = departments.toList()..sort();
    final people = count == 1 ? '1 person' : '$count people';
    return TextSpan(
      children: [
        const TextSpan(text: 'Sending to '),
        TextSpan(text: people, style: strong),
        if (names.isNotEmpty) TextSpan(text: ' in ${_join(names)}'),
      ],
    );
  }

  String _join(List<String> names) {
    if (names.length <= 1) return names.join();
    if (names.length == 2) return '${names[0]} and ${names[1]}';
    return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }

  Widget _history(BuildContext context) {
    if (_loadingWarnings || (_loadingPeople && _warnings.isNotEmpty)) {
      return const Center(child: RotatingFlower(size: 32));
    }
    if (_warningError != null) {
      return _status(context, _warningError!, onRetry: _loadWarnings);
    }
    final warnings = _visibleWarnings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _countGrid(context),
        const SizedBox(height: 12),
        Expanded(
          child: warnings.isEmpty
              ? _surface(
                  context,
                  child: _status(
                    context,
                    _historyDepartment == null
                        ? 'No warnings have been sent.'
                        : 'No warnings in this department.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: warnings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => _record(context, warnings[index]),
                ),
        ),
      ],
    );
  }

  Widget _countGrid(BuildContext context) {
    final tiles = <Widget>[
      _countTile(
        context,
        label: 'All departments',
        count: _warnings.length,
        selected: _historyDepartment == null,
        onTap: () => setState(() => _historyDepartment = null),
      ),
      for (final entry in _departmentCounts)
        _countTile(
          context,
          label: _shortDepartment(entry.key),
          count: entry.value,
          selected: _historyDepartment == entry.key,
          onTap: () => setState(() => _historyDepartment = entry.key),
        ),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) => tiles[index],
      ),
    );
  }

  Widget _countTile(
    BuildContext context, {
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? WebTheme.brandSoftOf(context) : WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? WebTheme.brand : WebTheme.lineOf(context),
            ),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.inkOf(context),
                  ),
                ),
                TextSpan(
                  text: '  $count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: count == 0
                        ? WebTheme.mutedOf(context)
                        : WebTheme.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _record(BuildContext context, WarningModel warning) {
    final severity = warning.severity.trim().isEmpty ? 'Low' : warning.severity;
    final color = _severityColor(severity);
    final department = _shortDepartment(_departmentOf(warning));
    final name = warning.receiverName.trim().isEmpty
        ? 'Staff'
        : warning.receiverName.trim();
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              severity,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              department,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WebTheme.mutedOf(context),
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(warning.createdDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: WebTheme.mutedOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        warning.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: WebTheme.inkOf(context),
                        ),
                      ),
                      if (warning.message.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          warning.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: WebTheme.inkOf(context),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.mutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _surface(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(0),
  }) {
    return Container(
      padding: padding,
      decoration: WebTheme.card(context, radius: 16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: WebTheme.inkOf(context),
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WebTheme.brand,
            ),
          ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: WebTheme.mutedOf(context),
      ),
    );
  }

  InputDecoration _field(BuildContext context, String hint) {
    final line = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
      isDense: true,
      filled: true,
      fillColor: WebTheme.canvasOf(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: line,
      enabledBorder: line,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: WebTheme.brand, width: 1.3),
      ),
    );
  }

  Widget _status(BuildContext context, String text, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: WebTheme.mutedOf(context)),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  String _severityHelp(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'Critical. Immediate follow-up is required.';
      case 'high':
        return 'High. Formal warning, kept on the employee record.';
      case 'medium':
        return 'Medium. The staff member needs to correct this.';
      default:
        return 'Low. A notice, with no further action unless it repeats.';
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB91C1C);
      case 'high':
        return const Color(0xFFC2410C);
      case 'medium':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} $hour:$minute $period';
  }
}

class _DeptUserPicker extends StatefulWidget {
  final List<UserModel> users;
  final Set<int> selected;

  const _DeptUserPicker({
    required this.users,
    required this.selected,
  });

  @override
  State<_DeptUserPicker> createState() => _DeptUserPickerState();
}

class _DeptUserPickerState extends State<_DeptUserPicker> {
  late final Set<int> _selected = Set<int>.of(widget.selected);
  final _search = TextEditingController();
  final _departments = <String>{};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, List<UserModel>> get _grouped {
    final grouped = <String, List<UserModel>>{};
    final query = _query.trim().toLowerCase();
    for (final user in widget.users) {
      if (user.userId <= 0) continue;
      final department = user.department.trim().isEmpty
          ? 'Unassigned'
          : user.department.trim();
      if (_departments.isNotEmpty && !_departments.contains(department)) {
        continue;
      }
      final name = _name(user).toLowerCase();
      if (query.isNotEmpty && !name.contains(query)) continue;
      grouped.putIfAbsent(department, () => []).add(user);
    }
    for (final people in grouped.values) {
      people.sort(
        (a, b) => _name(a).toLowerCase().compareTo(_name(b).toLowerCase()),
      );
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return Map.fromEntries(entries);
  }

  Map<String, int> get _counts {
    final counts = <String, int>{};
    for (final user in widget.users) {
      if (user.userId <= 0) continue;
      final department = user.department.trim().isEmpty
          ? 'Unassigned'
          : user.department.trim();
      counts[department] = (counts[department] ?? 0) + 1;
    }
    return counts;
  }

  String _name(UserModel user) {
    final name = user.displayName.trim();
    if (name.isNotEmpty) return name;
    return 'Staff ${user.userId}';
  }

  String _short(String name) {
    final short = name
        .replaceAll(RegExp(r'\s*department$', caseSensitive: false), '')
        .trim();
    return short.isEmpty ? name : short;
  }

  void _toggle(int id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    final people = groups.values.expand((items) => items).toList();
    final shownSelected = people.where((user) => _selected.contains(user.userId)).length;
    final allShown = people.isNotEmpty && shownSelected == people.length;
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      appBar: AppBar(
        title: const Text('Select users'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('All', widget.users.length, _departments.isEmpty, () {
                        setState(_departments.clear);
                      }),
                      for (final entry in _counts.entries) ...[
                        const SizedBox(width: 6),
                        _chip(
                          _short(entry.key),
                          entry.value,
                          _departments.contains(entry.key),
                          () => setState(() {
                            if (!_departments.remove(entry.key)) {
                              _departments.add(entry.key);
                            }
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  style: TextStyle(fontSize: 13, color: WebTheme.inkOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Search name',
                    hintStyle: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
                    isDense: true,
                    filled: true,
                    fillColor: WebTheme.surfaceOf(context),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: WebTheme.mutedOf(context),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: WebTheme.lineOf(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: WebTheme.lineOf(context)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: people.isEmpty
                ? null
                : () => setState(() {
                    final ids = people.map((user) => user.userId);
                    if (allShown) {
                      _selected.removeAll(ids);
                    } else {
                      _selected.addAll(ids);
                    }
                  }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Icon(
                    allShown ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 20,
                    color: allShown ? WebTheme.brand : WebTheme.mutedOf(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select everyone shown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                  ),
                  Text(
                    '$_selectedCount selected',
                    style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Text(
                      'No staff found.',
                      style: TextStyle(color: WebTheme.mutedOf(context)),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                          child: Text(
                            _short(entry.key).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w700,
                              color: WebTheme.mutedOf(context),
                            ),
                          ),
                        ),
                        for (final user in entry.value) _row(user),
                      ],
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: FilledButton.styleFrom(
                  backgroundColor: WebTheme.brand,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Done · $_selectedCount',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _selectedCount => _selected.length;

  Widget _chip(String label, int count, bool selected, VoidCallback onTap) {
    final ink = WebTheme.inkOf(context);
    final surface = WebTheme.surfaceOf(context);
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

  Widget _row(UserModel user) {
    final selected = _selected.contains(user.userId);
    return Material(
      color: selected ? WebTheme.brandSoftOf(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _toggle(user.userId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: selected ? WebTheme.brand : WebTheme.mutedOf(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _name(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.inkOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

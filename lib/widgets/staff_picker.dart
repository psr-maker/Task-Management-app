import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

class StaffPicker extends StatefulWidget {
  final List<UserModel> users;
  final Set<int> selectedIds;
  final Map<int, String> namesById;
  final String title;
  final void Function(Set<int> ids)? onDone;

  const StaffPicker({
    super.key,
    required this.users,
    required this.selectedIds,
    this.namesById = const {},
    required this.title,
    this.onDone,
  });

  @override
  State<StaffPicker> createState() => _StaffPickerState();
}

class _StaffPickerState extends State<StaffPicker> {
  late final Set<int> _selected;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedIds};
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  UserModel? _userById(int id) {
    for (final user in widget.users) {
      if (user.userId == id) return user;
    }
    return null;
  }

  void _finish() {
    if (widget.onDone != null) {
      widget.onDone!(_selected);
      return;
    }
    Navigator.pop(context, _selected);
  }

  String _personLabel(UserModel user) {
    final saved = widget.namesById[user.userId]?.trim() ?? '';
    if (saved.isNotEmpty && saved != '${user.userId}') return saved;
    final display = user.displayName.trim();
    if (display.isNotEmpty && display != '${user.userId}') return display;
    final raw = user.name.trim();
    if (raw.isEmpty || raw == '${user.userId}') return 'Staff';
    return raw;
  }

  Map<String, List<UserModel>> _grouped(List<UserModel> users) {
    final groups = <String, List<UserModel>>{};
    for (final user in users) {
      final name = user.department.trim().isEmpty
          ? 'Other'
          : user.department.trim();
      groups.putIfAbsent(name, () => []).add(user);
    }
    final names = groups.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final name in names) name: groups[name]!};
  }

  Widget _userTile(UserModel user, Color brand) {
    final checked = _selected.contains(user.userId);
    final label = _personLabel(user);
    final ink = Theme.of(context).colorScheme.onSurface;
    return Card(
      color: checked
          ? brand.withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surface,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: checked ? brand : Colors.transparent,
          width: checked ? 1.4 : 0,
        ),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            if (checked) {
              _selected.remove(user.userId);
            } else {
              _selected.add(user.userId);
            }
          });
        },
        leading: CircleAvatar(
          backgroundColor: brand,
          child: Text(
            label.isNotEmpty ? label[0].toUpperCase() : '?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          user.department.trim().isEmpty ? 'Staff' : user.department.trim(),
          style: TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          checked ? Icons.check_circle : Icons.circle_outlined,
          color: checked ? brand : Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.users.where((user) {
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.department.toLowerCase().contains(query);
    }).toList();
    final brand = Theme.of(context).colorScheme.secondary;
    const fieldBorder = Color.fromARGB(255, 25, 77, 38);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            _selected.isEmpty
                ? 'Select the people to assign'
                : '${_selected.length} selected',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: 'Search name',
              hintStyle: Theme.of(context).textTheme.headlineSmall,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: fieldBorder),
              ),
            ),
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected.map((id) {
                final person = _userById(id);
                final saved = widget.namesById[id]?.trim() ?? '';
                final label = person == null
                    ? (saved.isNotEmpty && saved != '$id' ? saved : 'User $id')
                    : _personLabel(person);
                return InputChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDeleted: () => setState(() => _selected.remove(id)),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.users.isEmpty
                          ? 'No staff you can assign'
                          : 'No matching staff',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView(
                    children: [
                      for (final entry in _grouped(filtered).entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: brand,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        for (final user in entry.value) _userTile(user, brand),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: AppButton(
              text: "Done",
              onPressed: _finish,
              color: Theme.of(context).colorScheme.secondary,
              txtcolor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

String staffInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  final last = parts.last.isEmpty ? parts.first[0] : parts.last[0];
  return (parts.first[0] + last).toUpperCase();
}

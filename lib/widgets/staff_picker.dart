import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

class StaffPicker extends StatefulWidget {
  final List<UserModel> users;
  final Set<int> selectedIds;
  final String title;
  final void Function(Set<int> ids)? onDone;

  const StaffPicker({
    super.key,
    required this.users,
    required this.selectedIds,
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
                final name = _userById(id)?.name ?? 'User $id';
                return InputChip(
                  label: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDeleted: () => setState(() => _selected.remove(id)),
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black54,
                  ),
                  backgroundColor: brand.withValues(alpha: 0.08),
                  side: BorderSide(color: brand.withValues(alpha: 0.3)),
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
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final checked = _selected.contains(user.userId);
                      return Material(
                        color: checked
                            ? brand.withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (checked) {
                                _selected.remove(user.userId);
                              } else {
                                _selected.add(user.userId);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: checked ? brand : fieldBorder,
                                width: checked ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: brand.withValues(alpha: 0.12),
                                  child: Text(
                                    staffInitials(user.name),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(
                                  checked
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: checked ? brand : Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          AppButton(
            text: "Done",
            onPressed: _finish,
            color: Theme.of(context).colorScheme.secondary,
            txtcolor: Theme.of(context).colorScheme.onPrimary,
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

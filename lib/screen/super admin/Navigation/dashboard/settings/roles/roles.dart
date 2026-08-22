import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class RolesList extends StatefulWidget {
  const RolesList({super.key});

  @override
  State<RolesList> createState() => _RolesListState();
}

class _RolesListState extends State<RolesList> {
  final TextEditingController _searchController = TextEditingController();

  List<Role> _roles = [];
  List<Role> _filteredRoles = [];

  bool _isLoading = false;
  String _statusFilter = 'All';
  String? _topMessage;

  bool _isErrorMessage = true;

  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _searchController.addListener(_filterRoles);
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roles = await SuperAdminService.getRoles();

      if (!mounted) return;

      setState(() {
        _roles = roles;
        _filteredRoles = roles;
        _isLoading = false;
      });

      _filterRoles();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showTopMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _filterRoles() {
    final searchText = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredRoles = _roles.where((role) {
        final matchesSearch = role.name.toLowerCase().contains(searchText);

        final matchesStatus =
            _statusFilter == 'All' ||
            (_statusFilter == 'Active' && role.status) ||
            (_statusFilter == 'Inactive' && !role.status);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        _showTopMessage = false;
      });
    });
  }

  void _showRoleDialog({Role? role}) {
    final bool isEditing = role != null;

    final TextEditingController nameController = TextEditingController(
      text: role?.name ?? '',
    );

    final TextEditingController positionController = TextEditingController(
      text: role?.position.toString() ?? '',
    );

    bool status = role?.status ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Role' : 'Add New Role',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              content: SizedBox(
                width: 450,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      // ROLE NAME
                      TextField(
                        controller: nameController,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          labelText: 'Role Name',
                          hintText: 'e.g. Team Leader',
                          helperStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // POSITION
                      TextField(
                        controller: positionController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Position',
                          hintText: 'e.g. 4',
                          helperStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(
                            Icons.format_list_numbered,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lower position number = higher role',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // STATUS
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,

                        title: Text(status ? 'Active' : 'Inactive'),

                        value: status,

                        onChanged: isSaving
                            ? null
                            : (value) {
                                setDialogState(() {
                                  status = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                // CANCEL
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                AppButton(
                  text: isEditing ? 'Update' : 'Save',
                  isLoading: _isLoading,
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          final positionText = positionController.text.trim();

                          // Validate role name
                          if (name.isEmpty) {
                            showTopMessage(
                              'Role name is required',
                              isError: true,
                            );
                            return;
                          }

                          // Validate position
                          final position = int.tryParse(positionText);

                          if (position == null || position < 1) {
                            showTopMessage(
                              'Enter a valid position',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            if (isEditing) {
                              await SuperAdminService.updateRole(
                                id: role.id,
                                name: name,
                                position: position,
                                status: status,
                              );
                            } else {
                              await SuperAdminService.addRole(
                                name: name,
                                position: position,
                                status: status,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await _loadRoles();

                            showTopMessage(
                              isEditing
                                  ? 'Role updated successfully'
                                  : 'Role added successfully',
                                  isError: false
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            if (!mounted) return;

                            showTopMessage(
                              e.toString().replaceFirst('Exception: ', ''),
                              isError: true,
                            );
                          }
                        },
                  color: Color.fromARGB(255, 25, 77, 38),
                  txtcolor: Colors.white,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRole(Role role) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Role'),
          content: Text('Are you sure you want to delete "${role.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await SuperAdminService.deleteRole(role.id);

      if (!mounted) return;

      await _loadRoles();

      showTopMessage('Role deleted successfully');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showTopMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadRoles,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              _showRoleDialog();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),

        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Role Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,

                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Manage system roles and access levels',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Container(
                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: Colors.grey.shade200),
                    ),

                    child: _isLoading
                        ? const Center(child: RotatingFlower())
                        : _filteredRoles.isEmpty
                        ? const Center(
                            child: Text(
                              'No roles found',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,

                              child: DataTable(
                                columnSpacing: 50,

                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF8F9FA),
                                ),

                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'POSITION',
                                     style: Theme.of(context).textTheme.headlineLarge,
                                    ),
                                  ),

                                   DataColumn(
                                    label: Text(
                                      'ROLE',
                                     style: Theme.of(context).textTheme.headlineLarge,
                                    ),
                                  ),

                                   DataColumn(
                                    label: Text(
                                      'STATUS',
                                       style: Theme.of(context).textTheme.headlineLarge,
                                    ),
                                  ),

                                   DataColumn(
                                    label: Text(
                                      'ACTION',
                                       style: Theme.of(context).textTheme.headlineLarge,
                                    ),
                                  ),
                                ],

                                rows: _filteredRoles.map((role) {
                                  return DataRow(
                                    cells: [
                                      // POSITION
                                      DataCell(
                                        Text(
                                          role.position.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13
                                          ),
                                        ),
                                      ),

                                      // ROLE
                                      DataCell(
                                        Text(
                                          role.name,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13
                                          ),
                                        ),
                                      ),

                                      // STATUS
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: role.status
                                                ? Colors.green.shade50
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            role.status ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: role.status
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade700,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ACTION
                                      DataCell(
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showRoleDialog(role: role);
                                            }

                                            if (value == 'delete') {
                                              _deleteRole(role);
                                            }
                                          },

                                          itemBuilder: (context) {
                                            return const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined),
                                                    SizedBox(width: 10),
                                                    Text('Edit Role'),
                                                  ],
                                                ),
                                              ),

                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'Delete Role',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ];
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (_topMessage != null)
              AnimatedPositioned(
                top: _showTopMessage ? 0 : -120,

                left: 16,

                right: 16,

                duration: const Duration(milliseconds: 300),

                child: Msgsnackbar(
                  context,

                  message: _topMessage!,

                  isError: _isErrorMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/department.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class AddDepartmentPage extends StatefulWidget {
  const AddDepartmentPage({super.key});

  @override
  State<AddDepartmentPage> createState() => _AddDepartmentPageState();
}

class _AddDepartmentPageState extends State<AddDepartmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _departmentController = TextEditingController();
  final _subDepartmentController = TextEditingController();
  String? _selectedZone;

  final SuperAdminService _departmentService = SuperAdminService();
  bool _isLoading = false;

  List<String> _allDepartments = [];
  List<String> _allSubDepartments = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  void _fetchDepartments() async {
    try {
      List<Department> depts = await _departmentService.getDepartments();
      setState(() {
        _allDepartments = depts.map((e) => e.departmentName).toSet().toList();
        _allSubDepartments = depts
            .map((e) => e.subDepartment ?? "")
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      });
    } catch (e) {
      debugPrint("Failed to load departments: $e");
    }
  }

  void _submitDepartment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Department newDept = Department(
        departmentName: _departmentController.text.trim(),
        subDepartment: _subDepartmentController.text.trim(),
        zone: _selectedZone ?? "",
      );

      try {
        Department created = await _departmentService.addDepartment(newDept);
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Department "${created.departmentName}" added successfully!',
            ),
          ),
        );

        _formKey.currentState!.reset();
        _selectedZone = null;
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add department: $e')));
      }
    }
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _subDepartmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Department"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Department Autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  return _allDepartments.where(
                    (dept) => dept.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      _departmentController.text = controller.text;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Department name is required';
                          }
                          return null;
                        },
                      );
                    },
                onSelected: (selection) {
                  _departmentController.text = selection;
                },
              ),
              const SizedBox(height: 16),

              // Sub Department Autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  return _allSubDepartments.where(
                    (sub) => sub.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      _subDepartmentController.text = controller.text;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Sub Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment),
                        ),
                      );
                    },
                onSelected: (selection) {
                  _subDepartmentController.text = selection;
                },
              ),
              const SizedBox(height: 16),

              // Zone Dropdown
              DropdownButtonFormField<String>(
                value: _selectedZone,
                decoration: const InputDecoration(
                  labelText: 'Zone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                style: Theme.of(context).textTheme.labelMedium,
                items: ['North', 'South', 'East', 'West'].map((zone) {
                  return DropdownMenuItem(
                    value: zone,
                    child: Text(
                      zone,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedZone = value);
                },
                validator: (value) =>
                    value == null ? 'Please select a zone' : null,
              ),
              const SizedBox(height: 24),
              Center(
                child: AppButton(
                  text: "Add Department",
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submitDepartment,
                  color: Theme.of(context).colorScheme.secondary,
                  txtcolor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/department.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
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
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
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
        showTopMessage(
          '"${created.departmentName}" added successfully',
          isError: false,
        );

        _formKey.currentState!.reset();
        _selectedZone = null;
      } catch (e) {
        setState(() => _isLoading = false);
        showTopMessage('Failed to add department: $e', isError: true);
      }
    }
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTopMessage = false);
    });
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon,color: Theme.of(context).colorScheme.secondary,size: 18,),
      labelStyle: Theme.of(context).textTheme.labelMedium,

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
    );
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),

                    // ✅ Department
                    _buildAutocomplete(
                      data: _allDepartments,
                      mainController: _departmentController,
                      label: "Department",
                      icon: Icons.business,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Department required" : null,
                    ),

                    const SizedBox(height: 16),

                    // ✅ Sub Department
                    _buildAutocomplete(
                      data: _allSubDepartments,
                      mainController: _subDepartmentController,
                      label: "Sub Department",
                      icon: Icons.apartment,
                    ),

                    const SizedBox(height: 16),

                    // ✅ Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedZone,
                      decoration: _decoration("Zone", Icons.map),
                      style: Theme.of(context).textTheme.labelMedium,

                      items: ['North', 'South', 'East', 'West']
                          .map(
                            (z) => DropdownMenuItem(
                              value: z,
                              child: Text(
                                z,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          )
                          .toList(),

                      onChanged: (v) => setState(() => _selectedZone = v),
                      validator: (v) => v == null ? "Select zone" : null,
                    ),

                    const SizedBox(height: 80),

                    AppButton(
                      text: "Add Department",
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submitDepartment,
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
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
        ),
      ),
    );
  }

  Widget _buildAutocomplete({
    required List<String> data,
    required TextEditingController mainController,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (text) {
        return data.where(
          (item) => item.toLowerCase().contains(text.text.toLowerCase()),
        );
      },

      onSelected: (val) => mainController.text = val,

      fieldViewBuilder: (context, controller, focusNode, _) {
        controller.addListener(() {
          mainController.text = controller.text;
        });

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: Theme.of(context).textTheme.labelMedium,
          decoration: _decoration(label, icon),
          validator: validator,
        );
      },

      // ✅ Short & clean dropdown style
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: options.map((e) {
              return ListTile(
                title: Text(e, style: Theme.of(context).textTheme.labelMedium),
                onTap: () => onSelected(e),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

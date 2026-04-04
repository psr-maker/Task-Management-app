import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class Warrentypoints extends StatefulWidget {
  const Warrentypoints({super.key});

  @override
  State<Warrentypoints> createState() => _WarrentypointsState();
}

class _WarrentypointsState extends State<Warrentypoints> {
  List<UserModel> users = [];
  UserModel? selectedUser;

  final totalWorkController = TextEditingController();
  final complaintsController = TextEditingController();
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await SuperAdminService.getAllUsers();
    setState(() {
      users = data;
    });
  }

  Future<void> submit() async {
    if (selectedUser == null ||
        totalWorkController.text.isEmpty ||
        complaintsController.text.isEmpty) {
      showTopMessage("Please fill all fields", isError: true);
      return;
    }

    setState(() => isLoading = true);

    final success = await AdminService.addWarranty(
      staffId: selectedUser!.userId,
      totalWork: int.parse(totalWorkController.text),
      complaints: int.parse(complaintsController.text),
    );

    setState(() => isLoading = false);

    if (success) {
      showTopMessage("Warranty points added successfully", isError: false);

      totalWorkController.clear();
      complaintsController.clear();
      setState(() => selectedUser = null);
    }
  }

  void openUserPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<UserModel> filtered = List.from(users);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                height: 500,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 🔍 SEARCH
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search staff...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filtered = users
                              .where(
                                (u) => u.name.toLowerCase().contains(
                                  value.toLowerCase(),
                                ),
                              )
                              .toList();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // 👤 USER LIST
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final user = filtered[index];

                          return ListTile(
                            leading: CircleAvatar(child: Text(user.name[0])),
                            title: Text(user.name, style: Theme.of(context).textTheme.labelMedium),
                            subtitle: Text(user.role, style: Theme.of(context).textTheme.titleLarge),
                            onTap: () {
                              setState(() => selectedUser = user);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Warranty Points"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔷 HEADER
                Text(
                  "Warranty Entry",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  "Warranty Points Allocation...⭐",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                SizedBox(height: 30),
                buildUserSelector(),
                SizedBox(height: 15),
                buildInputNew(
                  "Total Work",
                  totalWorkController,
                  Icons.work_outline,
                ),
                SizedBox(height: 15),
                buildInputNew(
                  "Complaints",
                  complaintsController,
                  Icons.warning,
                ),
                const SizedBox(height: 30),
                Center(
                  child: AppButton(
                    text: "Save",
                    isLoading: isLoading,
                    onPressed: submit,
                    color: Theme.of(context).colorScheme.secondary,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            if (_topMessage != null)
              AnimatedPositioned(
                top: _showTopMessage ? 20 : -120,
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

  Widget buildInputNew(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: Theme.of(context).textTheme.headlineLarge,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: Theme.of(context).textTheme.titleLarge,
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
          size: 18,
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget buildUserSelector() {
    return GestureDetector(
      onTap: openUserPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.secondary),
        ),
        child: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedUser == null ? "Select Staff" : selectedUser!.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

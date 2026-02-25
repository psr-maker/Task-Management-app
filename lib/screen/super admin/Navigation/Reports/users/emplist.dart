import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'emp.dart';

class EmployeeReportsList extends StatefulWidget {
  final String role;

  const EmployeeReportsList({super.key, required this.role});

  @override
  State<EmployeeReportsList> createState() => _EmployeeReportsListState();
}

class _EmployeeReportsListState extends State<EmployeeReportsList> {
  late Future<List<UserModel>> usersFuture;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    usersFuture = SuperAdminService.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No Users Found"));
        }

        // ✅ FILTER BY ROLE
        final filteredByRole = snapshot.data!
            .where(
              (user) => user.role.toLowerCase() == widget.role.toLowerCase(),
            )
            .toList();

        final query = searchController.text.toLowerCase();

        final finalList = filteredByRole.where((user) {
          if (query.isEmpty) return true;
          return user.name.toLowerCase().contains(query) ||
              user.department.toLowerCase().contains(query);
        }).toList();

        if (finalList.isEmpty) {
          return Center(child: Text("No ${widget.role}s Found"));
        }

        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search ${widget.role}...",
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                  border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
          
              Expanded(
                child: ListView.builder(
                  itemCount: finalList.length,
                  itemBuilder: (context, index) {
                    final user = finalList[index];
          
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color.fromARGB(255, 134, 170, 136),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            // ✅ Existing UI
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color.fromARGB(
                                255,
                                50,
                                99,
                                49,
                              ),
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user.department,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EmployeeReportPage(
                                      userid: user.userId,
                                      username: user.name,
                                      role: user.role,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color.fromARGB(255, 25, 77, 38),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

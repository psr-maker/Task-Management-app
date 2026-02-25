import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class PendingApprovals extends StatefulWidget {
  const PendingApprovals({super.key});

  @override
  State<PendingApprovals> createState() => _PendingApprovalsState();
}

class _PendingApprovalsState extends State<PendingApprovals> {
  late Future<List<UserModel>> pendingFuture;

  @override
  void initState() {
    super.initState();
    loadPendingUsers();
  }

  void loadPendingUsers() async {
    setState(() {
      pendingFuture = DashboardService.getPendingUsers();
    });
  }

  Future<void> handleAction(int userId, bool approve) async {
    await DashboardService.approveUser(userId, approve);
    loadPendingUsers();
  }

  @override
  Widget build(BuildContext context) {
    return
    // Scaffold(
    //   body:
    FutureBuilder<List<UserModel>>(
      future: pendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final users = snapshot.data;
        if (users == null || users.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Approvals",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:Theme.of(context).colorScheme.onPrimary,
                    border: Border.all(color:Theme.of(context).colorScheme.primary ,width: 1),
                  
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: Theme.of(context).textTheme.headlineLarge
                                  ),
                                  const SizedBox(height: 5),

                                  Text(
                                    user.department,
                                      style: Theme.of(context).textTheme.headlineMedium
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    user.email,
                                    style: Theme.of(context).textTheme.headlineSmall
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(70, 30),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),

                              onPressed: () async {
                                bool? confirmed = await showConfirmDialog(
                                  context,
                                  "Reject",
                                  "user"
                                );
                                if (confirmed != null && confirmed) {
                                  await handleAction(user.userId, false);
                                }
                              },
                              child: const Text(
                                "Reject",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(70, 30),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                side: BorderSide(color: Colors.green.shade400),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),

                              onPressed: () async {
                                bool? confirmed = await showConfirmDialog(
                                  context,
                                  "Approve",
                                  "user"
                                );
                                if (confirmed != null && confirmed) {
                                  await handleAction(user.userId, true);
                                }
                              },
                              child: const Text(
                                "Approve",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      // ),
    );
  }
}

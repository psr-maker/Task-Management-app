import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/allgoals.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/completedtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/pendingtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/progresstask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/create_task.dart';
import 'package:staff_work_track/services/auth_service.dart';

class Mywork extends StatefulWidget {
  const Mywork({super.key});

  @override
  State<Mywork> createState() => _MyworkState();
}

class _MyworkState extends State<Mywork> {
  int? adminId;
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAdminId();
  }

  Future<void> loadAdminId() async {
    try {
      final id = await getAdminIdFromToken();

      if (!mounted) return;

      setState(() {
        adminId = id;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      isLoading = false;
    }
  }

  Future<int> getAdminIdFromToken() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final decodedToken = JwtDecoder.decode(token);

    return int.parse(decodedToken['UserId'].toString());
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || adminId == null) {
      return const Center(child: RotatingFlower());
    }
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          SizedBox(height: 50),
          TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(10),
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(30),
            ),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.secondary,
            labelStyle: Theme.of(context).textTheme.headlineMedium,
            tabs: const [
              Tab(text: 'ALL'),
              Tab(text: 'Pending/Pause'),
              Tab(text: 'In Process'),
              Tab(text: 'Completed'),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15,right: 15,top: 10),
                  child: Column(
                    children: [
                      // Top Row: Search + Add Task
                      Row(
                        children: [
                          Expanded(
                            child: isSearching
                                ? TextField(
                                    controller: searchController,
                                    decoration: InputDecoration(
                                      hintText: "Search Goal",
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  )
                                : Text(
                                    "My Goals",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              isSearching ? Icons.close : Icons.search,
                            ),
                            onPressed: () {
                              setState(() {
                                isSearching = !isSearching;
                                searchController.clear();
                              });
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      Createtask(assignedToIds: [adminId!]),
                                ),
                              );
                            },
                            child: Chip(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              label: Text(
                                "Add Goal/Task",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Allgoals(searchQuery: searchController.text),
                      ),
                    ],
                  ),
                ),

                PendingTab(adminId: adminId!),
                InProcessTab(adminId: adminId!),
                CompletedTab(adminId: adminId!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

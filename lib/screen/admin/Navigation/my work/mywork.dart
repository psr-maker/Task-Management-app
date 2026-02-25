import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/admintask_list.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/completedtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/pendingtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/progresstask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/create_task.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

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
      return const Center(child: RotatingFlower(size: 30));
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
              color: const Color.fromARGB(255, 25, 77, 38),
              borderRadius: BorderRadius.circular(30),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.all(15),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(height: 5),
                            if (isSearching)
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    hintText: "Search employee...",
                                    // prefixIcon: Icon(Icons.search),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                    
                            IconButton(
                              icon: Icon(
                                isSearching ? Icons.close : Icons.search,
                                color: const Color.fromARGB(255, 25, 77, 38),
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
                                    builder: (context) =>
                                        Createtask(assignedToIds: [adminId!]),
                                  ),
                                );
                              },
                              child: const Chip(
                                backgroundColor: Color.fromARGB(255, 25, 77, 38),
                                label: Text(
                                  "Add Task",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Alltasklist(adminId: adminId!, searchQuery: searchController.text),
                      ],
                    ),
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

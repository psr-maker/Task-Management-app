import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/allgoals.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/completedtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/pendingtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/progresstask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/services/auth_service.dart';

class Mywork extends StatefulWidget {
  const Mywork({super.key});

  @override
  State<Mywork> createState() => _MyworkState();
}

class _MyworkState extends State<Mywork> {
  int _goalsRefreshKey = 0;
  int? adminId;
  bool isLoading = true;
  bool isSearching = false;
  bool _filterOpen = false;
  String _goalType = "All";
  final TextEditingController searchController = TextEditingController();
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
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
      if (!mounted) return;
      setState(() => isLoading = false);
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

  Widget _goalTypeChip(String label) {
    final selected = _goalType == label;
    final brand = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: selected ? brand : brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _goalType = label;
            _filterOpen = false;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : brand,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showTopMessage(String message, {bool isError = true}) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading || adminId == null) {
      return const Center(child: RotatingFlower());
    }

    final isWeb = !AppLayout.isMobile(context);

    return DefaultTabController(
      length: 4,
      child: Stack(
        children: [
          Padding(
            padding: isWeb ? AppLayout.pagePadding(context) : EdgeInsets.zero,
            child: Column(
              children: [
                if (isWeb) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: WebPageHeader(
                      title: 'My Works',
                      subtitle: 'Goals and tasks by status',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.secondary,
                child: SafeArea(
                  bottom: false,
                  top: !isWeb,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(color: Colors.white, width: 3),
                    ),
                    indicatorColor: Colors.white,
                    dividerColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    unselectedLabelStyle:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.12),
                    ),
                    tabs: const [
                      Tab(text: 'ALL'),
                      Tab(text: 'Pending/Pause'),
                      Tab(text: 'In Process'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isWeb ? 20 : 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: isSearching
                                    ? TextField(
                                        controller: searchController,
                                        decoration: const InputDecoration(
                                          hintText: "Search Goal",
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      )
                                    : Text(
                                        "My Goals",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.displaySmall,
                                      ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
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
                              IconButton(
                                tooltip: _filterOpen
                                    ? "Close filter"
                                    : "Filter: $_goalType",
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  _filterOpen ? Icons.close : Icons.filter_list,
                                ),
                                onPressed: () {
                                  setState(() => _filterOpen = !_filterOpen);
                                },
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final result = await openFormPage(
                                    context,
                                    Createtask(assignedToIds: [adminId!]),
                                    maxWidth: 880,
                                  );
                                  if (result == true) {
                                    if (!mounted) return;
                                    setState(() {
                                      _goalsRefreshKey++;
                                    });
                                  }
                                },
                                child: Chip(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  label: const Text(
                                    "Add Goal/Task",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_filterOpen)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _goalTypeChip("All"),
                                  _goalTypeChip("Yearly"),
                                  _goalTypeChip("Monthly"),
                                ],
                              ),
                            ),
                          Expanded(
                            child: Allgoals(
                              key: ValueKey(_goalsRefreshKey),
                              searchQuery: searchController.text,
                              goalType: _goalType,
                              onlyMine: true,
                              onDelete: (msg, isError) {
                                showTopMessage(msg, isError: isError);
                              },
                            ),
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
          ),

          /// ✅ GLOBAL TOP MESSAGE (FIXED)
          if (_topMessage != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showTopMessage ? 40 : -120,
              left: 16,
              right: 16,
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
              ),
            ),
        ],
      ),
    );
  }
}

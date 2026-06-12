import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/theme/theme_provider.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/settings/users_edit_pro.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _SettingsState();
}

class _SettingsState extends State<Profile> {
  @override
  void initState() {
    super.initState();
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    return "${ApiConstants.Uploaded}$path";
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Profile"),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserEditProfile()),
                );

                if (result == true) {
                  setState(() {}); // rebuilds FutureBuilder
                }
              },
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: AuthService.getMyProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: RotatingFlower());
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Error loading profile"));
            }

            final data = snapshot.data ?? {};

            String getValue(String key) {
              final value = data[key];
              if (value == null || value.toString().isEmpty) return "-";
              return value.toString();
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final fullUrl = getImageUrl(data["profileImage"]);

                          if (fullUrl.isEmpty) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenImageViewer(imageUrl: fullUrl),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey.shade300,

                          backgroundImage:
                              (data["profileImage"] != null &&
                                  data["profileImage"].toString().isNotEmpty)
                              ? NetworkImage(
                                  getImageUrl(data["profileImage"].toString()),
                                )
                              : null,

                          child:
                              (data["profileImage"] == null ||
                                  data["profileImage"].toString().isEmpty)
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        getValue("email"),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Theme.of(context).colorScheme.primary,
                  labelStyle: Theme.of(context).textTheme.headlineLarge,
                  tabs: const [
                    Tab(text: "Personal Details"),
                    Tab(text: "Employment Details"),
                  ],
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _infoTile(context, "Name", getValue("name")),
                          _infoTile(context, "Email", getValue("email")),
                          _infoTile(
                            context,
                            "Blood Group",
                            getValue("bloodGroup"),
                          ),
                          _infoTile(
                            context,
                            "D.O.B",
                            AppHelpers.formatDate(getValue("dateOfBirth")),
                          ),
                          _infoTile(context, "Gender", getValue("gender")),
                          _infoTile(
                            context,
                            "Contact Number",
                            getValue("contactNumber"),
                          ),
                          _infoTile(
                            context,
                            "Emergency Contact",
                            getValue("emergencyContact"),
                          ),
                          _infoTile(context, "Address", getValue("address")),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _infoTile(
                            context,
                            "Employee ID",
                            getValue("employeeId"),
                          ),
                          _infoTile(
                            context,
                            "Designation",
                            getValue("designation"),
                          ),
                          _infoTile(
                            context,
                            "Department",
                            getValue("department"),
                          ),
                          _infoTile(
                            context,
                            "Date of Joining",
                            AppHelpers.formatDate(getValue("dateOfJoining")),
                          ),
                          _infoTile(
                            context,
                            "Reporting Manager",
                            getValue("reportingManager"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _infoTile(BuildContext context, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.labelMedium),
        subtitle: Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/notification_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<dynamic>> notifications;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    notifications = NotificationService.getMyNotifications();
      NotificationService.markAllRead();
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

  Future<void> clearall() async {
    try {
      setState(() {
        _isLoading = true;
      });

      bool success = await NotificationService.deleteAllNotifications();

      if (success) {
        setState(() {
          notifications = NotificationService.getMyNotifications();
        });

        showTopMessage("All notifications cleared", isError: false);
      } else {
        showTopMessage("Failed to clear notifications", isError: true);
      }
    } catch (e) {
      showTopMessage("Failed to clear notifications", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Notifications"),
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : clearall,
                      child: const Text("CLEAR ALL"),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: notifications,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: RotatingFlower());
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading notifications"),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("No notifications found"),
                        );
                      }

                      final data = snapshot.data!;

                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final String title = item["title"] ?? "";
                          final String message = item["message"] ?? "";
                          final String type = title.toLowerCase();
                          final bool isDelete = type.contains("delete");

                          final Color accentColor = isDelete
                              ? Colors.red
                              : Colors.orange;
                          return Dismissible(
                            key: Key(item["id"].toString()),
                            direction: DismissDirection.endToStart,

                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: const Color.fromARGB(255, 231, 112, 103),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),

                            onDismissed: (direction) async {
                              int id = item["id"];

                              bool success =
                                  await NotificationService.deleteNotification(
                                    id,
                                  );

                              if (success) {
                                setState(() {
                                  data.removeAt(index);
                                });
                                showTopMessage(
                                  "Notification deleted successfully",
                                  isError: false,
                                );
                              } else {
                                showTopMessage(
                                  "Failed to delete notification",
                                  isError: true,
                                );
                                setState(() {
                                  notifications =
                                      NotificationService.getMyNotifications();
                                });
                              }
                            },

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 2,
                                      height: 25,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: accentColor,
                                      child: Icon(Icons.notifications_none),
                                    ),
                                    Container(
                                      width: 2,
                                      height: 25,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 15),

                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              title,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelMedium,
                                            ),
                                            Text(
                                              AppHelpers.formatDate(
                                                item["createdAt"] ?? "",
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        Text(
                                          message,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
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
    );
  }
}

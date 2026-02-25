import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/halfcircle_helper.dart';

class TaskPointDetail extends StatefulWidget {
  final String taskName;
  final String assignedTo;
  final String taskId;

  const TaskPointDetail({
    super.key,
    required this.taskName,
    required this.assignedTo,
    required this.taskId,
  });

  @override
  State<TaskPointDetail> createState() => _TaskPointDetailState();
}

class _TaskPointDetailState extends State<TaskPointDetail> {
  double progress = 0.0;
  int points = 0;
  bool isReviewed = false;
  bool isLoading = true;

  final TextEditingController commentController = TextEditingController();

  @override
void initState() {
  super.initState();
  loadReview();
}

  void updateProgress(double value) {
    setState(() {
      progress = value.clamp(0.0, 1.0);
      points = (progress * 100).toInt();
    });
  }

  Future<void> loadReview() async {
    try {
      final review = await AdminService.getReview(widget.taskId);

      if (review != null) {
        setState(() {
          isReviewed = true;
          points = review['points'];
          progress = points / 100;
          commentController.text = review['comment'];
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfff7f9f8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(220, 110),
            painter: HalfCirclePainter(progress),
            child: SizedBox(
              width: 220,
              height: 110,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.assignedTo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color.fromARGB(255, 25, 77, 38),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$points Points",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xfff2b705),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 35),

          GestureDetector(
            onHorizontalDragUpdate: isReviewed
                ? null
                : (details) {
                    double screenWidth = MediaQuery.of(context).size.width - 90;
                    double delta = details.localPosition.dx / screenWidth;
                    updateProgress(delta);
                  },

            child: Container(
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey.shade200,
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: (MediaQuery.of(context).size.width - 60) * progress,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xfff2b705), Color(0xffffd84d)],
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Swipe to Add Points",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          TextField(
            controller: commentController,
            enabled: !isReviewed,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your review...",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 25),

          AppButton(
            text: isReviewed ? "Already Reviewed" : "Done",
            onPressed: () async {
              if (points == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please swipe to add points")),
                );
                return;
              }

              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a comment")),
                );
                return;
              }

              try {
                await AdminService.submitReview(
                  taskCode: widget.taskId,
                  points: points,
                  comment: commentController.text,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Review submitted successfully 🎉"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },

            txtcolor: Colors.white,
            color: const Color.fromARGB(255, 25, 77, 38),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

class AddWorklogPage extends StatefulWidget {
  const AddWorklogPage({super.key});

  @override
  State<AddWorklogPage> createState() => _AddWorklogPageState();
}

class _AddWorklogPageState extends State<AddWorklogPage> {
  bool _isLoading = false;
  final TextEditingController worklogController = TextEditingController();

  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    worklogController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final result = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );

    if (result != null) {
      setState(() {
        isStart ? startTime = result : endTime = result;
      });
    }
  }

  void _submit() {
    if (worklogController.text.trim().isEmpty) return;

    Navigator.pop(context, {
      "description": worklogController.text,
      "start": startTime,
      "end": endTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 64, 108, 66),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            Text(
              "Add Work Log",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 80),
            Card(
              color: Colors.transparent,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                 
                    const Text(
                      "Work Description",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: worklogController,
                      maxLines: 10,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Describe your work",
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),

                    const SizedBox(height: 24),

                 
                    const Text(
                      "Work Duration",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: Row(
                        children: [
                        
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickTime(true),
                              child: _timeCard(
                                label: "Start Time",

                                time: startTime.format(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                         
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickTime(false),
                              child: _timeCard(
                                label: "End Time",
                                time: endTime.format(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

         
            Center(
              child: AppButton(
                text: "Add",
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCard({required String label, required String time}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

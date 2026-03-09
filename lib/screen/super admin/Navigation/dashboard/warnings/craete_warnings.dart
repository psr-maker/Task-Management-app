import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/announ_service.dart';

class SendWarningPage extends StatefulWidget {
  final int receiverId;
  final String receivername;

  const SendWarningPage({
    super.key,
    required this.receiverId,
    required this.receivername,
  });

  @override
  State<SendWarningPage> createState() => _SendWarningPageState();
}

class _SendWarningPageState extends State<SendWarningPage> {
  final AnnouncementService _warningService = AnnouncementService();

  final titleController = TextEditingController();
  final messageController = TextEditingController();

  String selectedSeverity = "Low";
  bool isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  Color severityColor(String severity) {
    switch (severity) {
      case "High":
        return const Color(0xffE53935);
      case "Medium":
        return const Color(0xffFB8C00);
      default:
        return const Color(0xff43A047);
    }
  }

  Future<void> sendWarning() async {
    if (titleController.text.isEmpty || messageController.text.isEmpty) {
      showTopMessage("All fields are required", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await _warningService.sendWarning(
        receiverId: widget.receiverId,
        title: titleController.text.trim(),
        message: messageController.text.trim(),
        severity: selectedSeverity,
      );

      showTopMessage("Warning sent successfully", isError: false);

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showTopMessage("Failed to send warning", isError: true);
    }

    setState(() => isLoading = false);
  }

  Widget severityCard(String severity, IconData icon) {
    final bool isSelected = selectedSeverity == severity;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSeverity = severity;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected
                ? severityColor(severity).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? severityColor(severity)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: severityColor(severity)),
              const SizedBox(height: 6),
              Text(
                severity,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: severityColor(severity),
                ),
              ),
            ],
          ),
        ),
      ),
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
      setState(() => _showTopMessage = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Send Warning"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 244, 208, 213),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.red,
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Send official warning to ${widget.receivername}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Warning Title",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: "Enter warning title",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Message
                const Text(
                  "Message",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Explain the reason clearly...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                /// Severity
                const Text(
                  "Severity Level",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    severityCard("Low", Icons.info_outline),
                    const SizedBox(width: 10),
                    severityCard("Medium", Icons.error_outline),
                    const SizedBox(width: 10),
                    severityCard("High", Icons.warning_amber_rounded),
                  ],
                ),

                const SizedBox(height: 40),
                Center(
                  child: AppButton(
                    text: "Send",
                    isLoading: isLoading,
                    onPressed: isLoading ? null : sendWarning,
                    color: Theme.of(context).colorScheme.error,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            if (_topMessage != null)
              AnimatedPositioned(
                top: _showTopMessage ? 0 : -120,
                left: 16,
                right: 16,
                duration: const Duration(milliseconds: 300),
                child: Msgsnackbar(
                  context,
                  message: _topMessage!,
                  isError: _isErrorMessage,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  iconColor: Theme.of(context).colorScheme.onPrimary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class PostAnnouncementPage extends StatefulWidget {
  const PostAnnouncementPage({super.key});

  @override
  State<PostAnnouncementPage> createState() => _PostAnnouncementPageState();
}

class _PostAnnouncementPageState extends State<PostAnnouncementPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  String? targetRole;
  bool _isLoading = false;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  File? selectedFile;

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

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadAnnouncement() async {
    if (titleController.text.isEmpty || targetRole == null) {
      showTopMessage("Please fill all required fields");
      return;
    }

    setState(() => _isLoading = true);

    bool success = await AnnouncementService.postAnnouncement(
      title: titleController.text,
      description: descController.text,
      targetRole: targetRole!,
      createdBy: "Director",
      file: selectedFile,
    );

    setState(() => _isLoading = false);

    if (success) {
      showTopMessage("Uploaded Successfully", isError: false);
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context, true);
    } else {
      showTopMessage("Upload Failed");
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
        title: const Text("New Announcement"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  CustomFormWidgets.label(context, "Title Name"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.textField(
                    context,
                    titleController,
                    hint: "Enter Title",
                  ),

                  const SizedBox(height: 20),

                  CustomFormWidgets.label(context, "Description"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.textField(
                    context,
                    descController,
                    hint: "Enter description",
                    maxLines: 4,
                  ),

                  const SizedBox(height: 20),

                  CustomFormWidgets.label(context, "To"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.dropdown(
                    context: context,
                    value: targetRole,
                    items: const ["All", "Manager", "Staff"],
                    onChanged: (v) => setState(() => targetRole = v),
                    hint: "Select target",
                  ),

                  const SizedBox(height: 15),

                  TextButton(onPressed: pickFile, child: Text("Select File")),
                  if (selectedFile != null) _buildFilePreview(),

                  const SizedBox(height: 30),

                  Center(
                    child: AppButton(
                      text: "Upload",
                      isLoading: _isLoading,
                      onPressed: uploadAnnouncement,
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 40 : -120,
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

  Widget _buildFilePreview() {
    final fileName = selectedFile!.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    if (["jpg", "jpeg", "png"].contains(extension)) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(selectedFile!, height: 150, fit: BoxFit.cover),
        ),
      );
    }

    IconData icon;
    Color color;

    if (extension == "pdf") {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (["doc", "docx"].contains(extension)) {
      icon = Icons.description;
      color = Colors.blue;
    } else if (["xls", "xlsx", "csv"].contains(extension)) {
      icon = Icons.table_chart;
      color = Colors.green;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Text(fileName, overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => selectedFile = null),
          ),
        ],
      ),
    );
  }
}

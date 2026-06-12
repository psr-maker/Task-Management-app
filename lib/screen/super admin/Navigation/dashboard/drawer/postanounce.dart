import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
  Uint8List? selectedBytes;
  String? selectedFileName;

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

  // ---------------- PICK FILE ----------------
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'csv',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final ext = file.extension?.toLowerCase() ?? '';

    selectedFileName = file.name;

    if (kIsWeb) {
      // WEB
      selectedBytes = file.bytes;
      selectedFile = null;
    } else {
      // MOBILE
      final f = File(file.path!);

      if (['jpg', 'jpeg', 'png'].contains(ext)) {
        final compressed = await FlutterImageCompress.compressAndGetFile(
          f.path,
          "${f.path}_compressed.jpg",
          quality: 50,
        );

        if (compressed != null) {
          selectedFile = File(compressed.path);
        }
      } else {
        selectedFile = f;
      }

      selectedBytes = null;
    }

    setState(() {});
  }

  Future<void> uploadAnnouncement() async {
    if (titleController.text.trim().isEmpty || targetRole == null) {
      showTopMessage("Please fill required fields");
      return;
    }

    setState(() => _isLoading = true);

    bool success = await AnnouncementService.postAnnouncement(
      title: titleController.text.trim(),
      description: descController.text.trim(),
      targetRole: targetRole!,
      file: selectedFile,
      fileBytes: selectedBytes,
      fileName: selectedFileName,
    );

    setState(() => _isLoading = false);

    if (success) {
      showTopMessage("Uploaded Successfully", isError: false);
      context.read<DataRefreshNotifier>().refreshAnnouncements();
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
                  if (selectedFileName != null) _buildFilePreview(),

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

  // ---------------- FILE PREVIEW ----------------
  Widget _buildFilePreview() {
    final fileName = selectedFileName ?? "file";
    final ext = fileName.split('.').last.toLowerCase();

    final isImage = ext == "jpg" || ext == "jpeg" || ext == "png";

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: kIsWeb
              ? Image.memory(
                  selectedBytes ?? Uint8List(0),
                  height: 150,
                  fit: BoxFit.cover,
                )
              : Image.file(selectedFile!, height: 150, fit: BoxFit.cover),
        ),
      );
    }

    IconData icon;
    Color color;

    if (ext == "pdf") {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (["doc", "docx"].contains(ext)) {
      icon = Icons.description;
      color = Colors.blue;
    } else if (["xls", "xlsx", "csv"].contains(ext)) {
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
            onPressed: () {
              setState(() {
                selectedFile = null;
                selectedBytes = null;
                selectedFileName = null;
              });
            },
          ),
        ],
      ),
    );
  }
}

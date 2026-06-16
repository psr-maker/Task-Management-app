import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class AddWorklogPage extends StatefulWidget {
  const AddWorklogPage({super.key});

  @override
  State<AddWorklogPage> createState() => _AddWorklogPageState();
}

class _AddWorklogPageState extends State<AddWorklogPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool _isLoading = false;
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  File? _image;
  bool _isImageLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTopMessage = false;
      });
    });
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (result != null) {
      setState(() => selectedDate = result);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final result = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.secondary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        isStart ? startTime = result : endTime = result;
      });
    }
  }

  Future<void> _submit(bool isSubmit) async {
    if (titleController.text.trim().isEmpty &&
        descriptionController.text.trim().isEmpty) {
      showTopMessage("Please enter Title or Description", isError: true);
      return;
    }

    if (_image == null) {
      showTopMessage("Please capture an image", isError: true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Location permission required");
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Please enable location services");
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      String fullAddress = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
      String currentDateTime = DateFormat(
        'dd MMM yyyy - hh:mm a',
      ).format(DateTime.now());

      String locationName =
          "${fullAddress.isNotEmpty ? fullAddress : "Unknown Location"} | $currentDateTime";
      await AnnouncementService.addWorkLog(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        workDate: selectedDate,
        startTime: startTime,
        endTime: endTime,
        isSubmit: isSubmit,
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
        image: _image,
      );

      if (!mounted) return;
      showTopMessage("Worklog added  successfully", isError: false);
      context.read<DataRefreshNotifier>().refreshWorklogs();
      Navigator.pop(context, true);
    } catch (e) {
      showTopMessage(e.toString(), isError: true);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    setState(() {
      _isImageLoading = true;
    });

    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      await precacheImage(FileImage(_image!), context);
    }

    setState(() {
      _isImageLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add WorkLog"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomFormWidgets.label(context, "Work Title"),
                const SizedBox(height: 10),
                CustomFormWidgets.textField(
                  context,
                  titleController,
                  hint: "Enter Work Title",
                ),
                const SizedBox(height: 15),
                CustomFormWidgets.label(context, "Work Description"),
                const SizedBox(height: 10),
                CustomFormWidgets.textField(
                  context,
                  descriptionController,
                  hint: "Enter Work Description",
                ),

                /// Date Picker
                ListTile(
                  title: Text(
                    "Work Date",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(true),
                        child: _timeCard(
                          "Start Time",
                          startTime.format(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(false),
                        child: _timeCard("End Time", endTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt, size: 30),
                      onPressed: _pickImage,
                    ),
                    const SizedBox(width: 10),

                    if (_isImageLoading)
                      const SizedBox(
                        width: 80,
                        height: 80,
                        child: Center(child: RotatingFlower()),
                      )
                    else if (_image != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenImageViewer(imageFile: _image!),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _image!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: AppButton(
                    text: "Save Draft",
                    isLoading: _isLoading,
                    onPressed: () => _submit(false),
                    color: Theme.of(context).colorScheme.secondary,
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeCard(String label, String time) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(time, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

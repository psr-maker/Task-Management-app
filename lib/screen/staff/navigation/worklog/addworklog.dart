import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/worklog_repository.dart';
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

  String workType = "IN";

  XFile? _image;

  bool _isImageLoading = false;

  String? _topMessage;

  bool _isErrorMessage = true;

  bool _showTopMessage = false;

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
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 40,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
      }
    } catch (e) {
      showTopMessage("Failed to capture image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission required");
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Please enable location services");
    }

    if (kIsWeb) {
      return {"latitude": 0.0, "longitude": 0.0, "locationName": "Web Upload"};
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double latitude = position.latitude;
    double longitude = position.longitude;

    String locationName = "Unknown Location";

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final fullAddress = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        locationName = fullAddress.isNotEmpty
            ? fullAddress
            : "Unknown Location";
      }
    } catch (_) {}

    return {
      "latitude": latitude,
      "longitude": longitude,
      "locationName": locationName,
    };
  }

  Future<void> _submit(bool isSubmit) async {
    if (titleController.text.trim().isEmpty) {
      showTopMessage("Please enter Work Title");

      return;
    }

    if (_image == null) {
      showTopMessage("Please capture ${workType} photo");

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final location = await _getLocation();

      final latitude = location["latitude"] as double;

      final longitude = location["longitude"] as double;

      final locationName = location["locationName"] as String;

      print("WORK TYPE: $workType");
      print("LATITUDE: $latitude");
      print("LONGITUDE: $longitude");
      print("LOCATION: $locationName");

      await WorkLogRepository.saveWorkLog(
        title: titleController.text.trim(),

        // IN / OUT
        workType: workType,

        description: descriptionController.text.trim(),

        workDate: selectedDate,

        isSubmit: !isSubmit,

        latitude: latitude,

        longitude: longitude,

        locationName: locationName,

        image: _image!,
      );

      if (!mounted) return;

      showTopMessage("$workType worklog added successfully", isError: false);

      context.read<DataRefreshNotifier>().refreshWorklogs();

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      showTopMessage(e.toString().replaceFirst("Exception: ", ""));
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

                const SizedBox(height: 15),
                Text(
                  "Work Date",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(selectedDate),

                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    IconButton(
                      onPressed: _pickDate,
                      icon: Icon(Icons.calendar_today),
                    ),
                  ],
                ),

                // ListTile(
                //   contentPadding: EdgeInsets.zero,

                //   title: Text(
                //     "Work Date",
                //     style: Theme.of(context).textTheme.headlineMedium,
                //   ),

                //   subtitle: Text(
                //     DateFormat('yyyy-MM-dd').format(selectedDate),

                //     style: Theme.of(context).textTheme.headlineSmall,
                //   ),

                //   trailing: const Icon(Icons.calendar_today),

                //   onTap: _pickDate,
                // ),
                const SizedBox(height: 15),

                Text(
                  "Work Type",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: _workTypeButton("IN", Icons.login)),

                    const SizedBox(width: 12),

                    Expanded(child: _workTypeButton("OUT", Icons.logout)),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),

                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),

                  child: Column(
                    children: [
                      Icon(
                        workType == "IN" ? Icons.login : Icons.logout,

                        size: 45,

                        color: Theme.of(context).colorScheme.secondary,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "$workType Evidence",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Capture photo for $workType",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // IMAGE
                      if (_isImageLoading)
                        const SizedBox(
                          width: 100,
                          height: 100,
                          child: Center(child: RotatingFlower()),
                        )
                      else if (_image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),

                          child: kIsWeb
                              ? Image.network(
                                  _image!.path,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_image!.path),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 150,

                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,

                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: const Icon(
                            Icons.photo_camera_outlined,
                            size: 55,
                            color: Colors.grey,
                          ),
                        ),

                      const SizedBox(height: 15),

                      // CAPTURE BUTTON
                      SizedBox(
                        width: 200,

                        child: ElevatedButton.icon(
                          onPressed: _isImageLoading ? null : _pickImage,

                          icon: const Icon(Icons.camera_alt),

                          label: Text(
                            _image == null
                                ? "Capture $workType Photo"
                                : "Retake $workType Photo",
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,

                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,

                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: AppButton(
                    text: "Save $workType",

                    isLoading: _isLoading,

                    onPressed: () => _submit(true),

                    color: Theme.of(context).colorScheme.secondary,

                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),

                const SizedBox(height: 20),
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

  Widget _workTypeButton(String type, IconData icon) {
    final selected = workType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          workType = type;

          _image = null;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        padding: const EdgeInsets.symmetric(vertical: 10),

        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.secondary
              : Colors.grey.shade100,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey.shade300,
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.grey.shade700,
            ),

            const SizedBox(width: 8),

            Text(
              type,

              style: TextStyle(
                fontWeight: FontWeight.bold,

                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

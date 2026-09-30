import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/worklog_repository.dart';
import 'package:staff_work_track/utils/time_utils.dart';
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

  static const String workType = "IN";

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

  Future<Map<String, dynamic>> _getLocationCoordinates() async {
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
      return {"latitude": 0.0, "longitude": 0.0};
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
    };
  }

  Future<String> _getLocationName(double latitude, double longitude) async {
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
    } catch (e) {
      print("Location name fetch error: $e");
    }

    return locationName;
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
      // Get coordinates only (fast, works offline)
      final coordinates = await _getLocationCoordinates();

      final latitude = coordinates["latitude"] as double;

      final longitude = coordinates["longitude"] as double;

      // Try to get location name (may fail if offline)
      String? locationName;
      try {
        locationName = await _getLocationName(latitude, longitude);
        if (locationName.trim().toLowerCase() == 'unknown location') {
          locationName = null;
        }
      } catch (e) {
        print("⚠️ Failed to get location name: $e");
        // Continue without location name, will be fetched during sync
        locationName = null;
      }

      print("WORK TYPE: $workType");
      print("LATITUDE: $latitude");
      print("LONGITUDE: $longitude");
      print("LOCATION: $locationName");

      final savedLocally = await WorkLogRepository.saveWorkLog(
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

      context.read<DataRefreshNotifier>().refreshWorklogs();

      Navigator.pop(context, savedLocally ? "local" : "cloud");
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
    final isWeb = !AppLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add WorkLog"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 960 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 28 : 15),
            child: Stack(
              children: [
                isWeb ? _webForm(context) : _mobileForm(context),
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
        ),
      ),
    );
  }

  Widget _mobileForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._titleFields(context),
        const SizedBox(height: 15),
        ..._dateAndType(context),
        const SizedBox(height: 20),
        _photoCard(context),
        const SizedBox(height: 15),
        Center(child: _saveButton(context)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _webForm(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: WebTheme.lineOf(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New worklog',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Save the check-in. Check out later from the worklog with a photo.',
              style: TextStyle(
                fontSize: 13,
                color: WebTheme.mutedOf(context),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._titleFields(context),
                      const SizedBox(height: 18),
                      ..._dateAndType(context),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    children: [
                      _photoCard(context),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _saveButton(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _titleFields(BuildContext context) {
    return [
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
    ];
  }

  List<Widget> _dateAndType(BuildContext context) {
    return [
      Text(
        "Work Date",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              Text(
                TimeUtils.formatDate(selectedDate),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _photoCard(BuildContext context) {
    return Container(
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
            Icons.login,
            size: 45,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          Text(
            "Check In Photo",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 5),
          Text(
            kIsWeb
                ? "Upload a photo for check in"
                : "Capture photo for check in",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 15),
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 55,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 15),
          SizedBox(
            width: 220,
            child: ElevatedButton.icon(
              onPressed: _isImageLoading ? null : _pickImage,
              icon: Icon(kIsWeb ? Icons.upload_file : Icons.camera_alt),
              label: Text(
                _image == null
                    ? (kIsWeb ? "Upload Check In Photo" : "Capture Check In Photo")
                    : "Retake Check In Photo",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton(BuildContext context) {
    return AppButton(
      text: "Save Check In",
      isLoading: _isLoading,
      onPressed: () => _submit(true),
      color: Theme.of(context).colorScheme.secondary,
      txtcolor: Theme.of(context).colorScheme.onPrimary,
    );
  }

}

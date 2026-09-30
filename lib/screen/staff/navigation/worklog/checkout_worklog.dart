import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/network_service.dart';
import 'package:staff_work_track/services/worklog_repository.dart';

class CheckoutWorklogPage extends StatefulWidget {
  const CheckoutWorklogPage({
    super.key,
    this.workLogId,
    this.localId,
    required this.title,
  });

  final int? workLogId;
  final int? localId;
  final String title;

  @override
  State<CheckoutWorklogPage> createState() => _CheckoutWorklogPageState();
}

class _CheckoutWorklogPageState extends State<CheckoutWorklogPage> {
  XFile? _image;
  bool _isImageLoading = false;
  bool _isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

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

  Future<void> _pickImage() async {
    setState(() => _isImageLoading = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 40,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      if (picked != null) {
        setState(() => _image = picked);
      }
    } catch (e) {
      showTopMessage('Failed to capture image: $e');
    } finally {
      if (mounted) setState(() => _isImageLoading = false);
    }
  }

  Future<Map<String, double>> _getCoordinates() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission required');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Please enable location services');
    }
    if (kIsWeb) {
      return {'latitude': 0.0, 'longitude': 0.0};
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return {'latitude': position.latitude, 'longitude': position.longitude};
  }

  Future<String> _locationName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return 'Unknown Location';
      final place = placemarks.first;
      final address = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
      return address.isEmpty ? 'Unknown Location' : address;
    } catch (_) {
      return 'Unknown Location';
    }
  }

  Future<void> _submit() async {
    if (_image == null) {
      showTopMessage('Please capture the OUT photo');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final coordinates = await _getCoordinates();
      final latitude = coordinates['latitude']!;
      final longitude = coordinates['longitude']!;
      final lookedUp = await _locationName(latitude, longitude);
      final locationName =
          lookedUp.trim().toLowerCase() == 'unknown location' ? '' : lookedUp;

      if (widget.localId != null) {
        await WorkLogRepository.saveLocalCheckOut(
          localId: widget.localId!,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
          image: _image!,
        );
        if (!mounted) return;
        Navigator.pop(context, 'local');
        return;
      }

      final serverId = widget.workLogId;
      if (serverId == null) {
        throw Exception('Worklog not found');
      }

      final online = await NetworkService.hasInternet();
      if (online) {
        try {
          await WorkLogRepository.checkOutWorkLog(
            workLogId: serverId,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            image: _image!,
          );
          if (!mounted) return;
          context.read<DataRefreshNotifier>().refreshWorklogs();
          Navigator.pop(context, true);
          return;
        } catch (_) {}
      }

      await WorkLogRepository.queueServerCheckOut(
        serverWorkLogId: serverId,
        title: widget.title,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        image: _image!,
      );
      if (!mounted) return;
      Navigator.pop(context, 'local');
    } catch (e) {
      if (!mounted) return;
      showTopMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Out'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.title.isEmpty ? 'Worklog' : widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take the OUT photo. Without internet it stays on this phone until you sync.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 16),
              if (_isImageLoading)
                const SizedBox(height: 220, child: Center(child: RotatingFlower()))
              else if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(_image!.path, height: 220, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), height: 220, width: double.infinity, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey.shade100,
                  ),
                  child: const Icon(Icons.photo_camera_outlined, size: 56, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              AppButton(
                text: _image == null ? 'Capture OUT Photo' : 'Retake OUT Photo',
                onPressed: _isImageLoading ? null : _pickImage,
                color: Theme.of(context).colorScheme.secondary,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Save Check Out',
                isLoading: _isLoading,
                onPressed: _submit,
                color: Theme.of(context).colorScheme.secondary,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 8 : -120,
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

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;

  const FullScreenImageViewer({super.key, this.imageUrl, this.imageFile});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  bool _isDownloading = false;

  bool _isDownloaded = false;

  Future<void> downloadImage(String imageUrl) async {
    setState(() {
      _isDownloading = true;
      _isDownloaded = false;
    });

    try {
      final tempPath =
          '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Dio().download(imageUrl, tempPath);

      await Gal.putImage(tempPath);

      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isDownloaded = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// FULL SCREEN ZOOM IMAGE
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: widget.imageFile != null
                    ? Image.file(widget.imageFile!)
                    : Image.network(widget.imageUrl!),
              ),
            ),
          ),

          /// CLOSE BUTTON (FLOATING)
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),

          Positioned(
            top: 40,
            right: 70,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                onPressed: _isDownloading
                    ? null
                    : () {
                        if (widget.imageUrl != null) {
                          downloadImage(widget.imageUrl!);
                        }
                      },
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : _isDownloaded
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.download, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

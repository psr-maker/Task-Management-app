import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class AppButton extends StatefulWidget {
  final String text;
  final Color? txtcolor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
     this.txtcolor,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      ),
      onPressed: widget.isLoading ? null : widget.onPressed,
      child: widget.isLoading
          ? RotatingFlower()
          : Text(
              widget.text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.txtcolor,
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

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
        backgroundColor: widget.color ?? WebTheme.brand,
        foregroundColor: widget.txtcolor ?? Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

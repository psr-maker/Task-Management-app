import 'package:flutter/material.dart';

class RotatingFlower extends StatefulWidget {
  final double size;

  const RotatingFlower({
    super.key,
    this.size = 24.0,
  });

  @override
  State<RotatingFlower> createState() => _RotatingFlowerState();
}

class _RotatingFlowerState extends State<RotatingFlower>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Image.asset(
        'assets/flower.png',
        height: widget.size,
        width: widget.size,
      ),
    );
  }
}

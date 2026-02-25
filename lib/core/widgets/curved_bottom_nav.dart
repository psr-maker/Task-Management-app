import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/navrole.dart';
import 'package:staff_work_track/utils/enum.dart';

class CurvedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final UserRole role;

  const CurvedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final items = roleNavItems[role]!;

    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 60),
            painter: CurvedNavPainter(currentIndex),
          ),

          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isActive = currentIndex == index;

                return GestureDetector(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Color.fromARGB(255, 30, 45, 38)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          items[index].icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.transparent : Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedNavPainter extends CustomPainter {
  final int index;

  CurvedNavPainter(this.index);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(255, 30, 45, 38)
      ..style = PaintingStyle.fill;

    final path = Path();
    final double width = size.width;
    final double height = size.height;
    final double notchRadius = 30;

    final double centerX = (width / 4) * index + (width / 8);

    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius * 1.2, 0);

    path.quadraticBezierTo(centerX - notchRadius, 0, centerX - notchRadius, 20);

    path.arcToPoint(
      Offset(centerX + notchRadius, 20),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.quadraticBezierTo(
      centerX + notchRadius,
      0,
      centerX + notchRadius * 1.2,
      0,
    );

    path.lineTo(width, 0);
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

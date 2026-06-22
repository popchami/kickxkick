import 'package:flutter/material.dart';

import '../screens/shoe_form_screen.dart';

class AppFab extends StatelessWidget {
  const AppFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'スニーカーを登録',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShoeFormScreen()),
        );
      },
      child: const _SneakerPlusIcon(),
    );
  }
}

class _SneakerPlusIcon extends StatelessWidget {
  const _SneakerPlusIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return SizedBox(
      width: 34,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(34, 24),
            painter: _SneakerPainter(color),
          ),
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).floatingActionButtonTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, size: 15, color: color),
          ),
        ],
      ),
    );
  }
}

class _SneakerPainter extends CustomPainter {
  final Color color;

  const _SneakerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.48,
        size.width * 0.28,
        size.height * 0.18,
      )
      ..lineTo(size.width * 0.48, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.5,
        size.width * 0.9,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width,
        size.height * 0.63,
        size.width * 0.96,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.1, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.02,
        size.height * 0.75,
        size.width * 0.05,
        size.height * 0.62,
      )
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.12),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SneakerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

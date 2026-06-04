import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 80.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              primaryColor,
              secondaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: size * 0.4,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background radar lines
            Positioned.fill(
              child: CustomPaint(
                painter: _LogoBackgroundPainter(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Central Wallet / Graph / Brain Icon combination
            Icon(
              Icons.query_stats_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
            // Floating mini-sparkle representing AI
            Positioned(
              top: size * 0.22,
              right: size * 0.22,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.22,
                color: const Color(0xFFFCD34D), // Soft Amber Glow
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoBackgroundPainter extends CustomPainter {
  final Color color;

  _LogoBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw decorative circular tech orbits
    canvas.drawCircle(center, size.width * 0.35, paint);
    
    // Draw crosshair indicator lines (representing analytical grids)
    canvas.drawLine(
      Offset(size.width * 0.1, size.height / 2),
      Offset(size.width * 0.2, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height / 2),
      Offset(size.width * 0.9, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.1),
      Offset(size.width / 2, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.8),
      Offset(size.width / 2, size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

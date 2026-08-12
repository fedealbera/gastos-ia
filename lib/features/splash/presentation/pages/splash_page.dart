import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/database/hive_database.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/app_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  String _versionString = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _controller.forward();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Warm up Hive & DI
      await HiveDatabase.init();
      await configureDependencies();

      // Fetch app version info
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionString = 'v${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
      
      // Let splash sit for a minimum of 2 seconds for superior visual branding feeling
      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (mounted) {
        final userName = HiveDatabase.settingsBox.get('userName') as String?;
        if (userName == null || userName.trim().isEmpty) {
          context.go(AppRouter.onboarding);
        } else {
          context.go(AppRouter.dashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de inicialización: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Teal Neon Graphic
                    AppLogo(size: 130.0),
                    const SizedBox(height: 32.0),
                    Text(
                      'Gastos',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Arquitectura Financiera Inteligente',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: _versionString.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  _versionString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/hive_database.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSyncing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() == true) {
      final name = _nameController.text.trim();
      HiveDatabase.settingsBox.put('userName', name);
      context.go(AppRouter.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        final messenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);
        
        if (state is AuthLoading) {
          setState(() {
            _isSyncing = true;
          });
        } else if (state is Authenticated) {
          setState(() {
            _isSyncing = true;
          });
          try {
            // Sincronizar datos históricos
            final syncService = getIt<SyncService>();
            await syncService.syncOnLogin(state.user.uid);

            // Guardar nombre y navegar
            final displayName = state.user.displayName ?? 'Usuario Google';
            await HiveDatabase.settingsBox.put('userName', displayName);

            if (mounted) {
              setState(() {
                _isSyncing = false;
              });
              router.go(AppRouter.dashboard);
            }
          } catch (e) {
            setState(() {
              _isSyncing = false;
            });
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Error al sincronizar datos: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        } else if (state is AuthError) {
          setState(() {
            _isSyncing = false;
          });
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state is Unauthenticated) {
          setState(() {
            _isSyncing = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),
                                
                                // App Logo
                                const AppLogo(size: 100.0),
                                const SizedBox(height: 32.0),
                                
                                // Title and Subtitle
                                Text(
                                  '¡Te damos la bienvenida!',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  'Administra tus finanzas de forma profesional y segura con sincronización en la nube.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 40.0),
                                
                                // Iniciar sesión con Google Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56.0,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      context.read<AuthCubit>().loginWithGoogle();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.0),
                                      ),
                                      side: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.network(
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                                          height: 24.0,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.g_mobiledata_rounded, size: 28.0),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Text(
                                          'Continuar con Google',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24.0),
                                
                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        'o bien',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                                  ],
                                ),
                                
                                const SizedBox(height: 24.0),
                                
                                // Input Field
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Tu Nombre (Modo Local)',
                                    hintText: 'Ej. Federico, Sofía...',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 18.0,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Por favor ingresa tu nombre';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                
                                const Spacer(flex: 2),
                                
                                // Continue Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56.0,
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.0),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Continuar como Invitado',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8.0),
                                        Icon(Icons.arrow_forward_rounded, size: 18.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_isSyncing)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 32.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 24.0),
                            Text(
                              'Sincronizando tus finanzas...',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Estamos conectando con la nube para asegurar tu información.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

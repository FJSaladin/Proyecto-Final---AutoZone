import 'package:autozone/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _matriculaCtrl  = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _verClave        = false;
  bool _cargando        = false;

  @override
  void dispose() {
    _matriculaCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  // ── Login ─────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(
      _matriculaCtrl.text.trim(),
      _contrasenaCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (ok) {
      showSuccess(context, '¡Bienvenido, ${auth.usuario?.nombre}!');
      Navigator.pop(context); // vuelve al Dashboard
    } else {
      showError(context, auth.error ?? 'Credenciales incorrectas');
    }
  }

  // ── Olvidar contraseña ────────────────────────────────────

  Future<void> _olvidarClave() async {
    final matricula = _matriculaCtrl.text.trim();
    if (matricula.isEmpty) {
      showError(context, 'Escribe tu matrícula primero');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Text(
          'Se restablecerá la contraseña de "$matricula" '
          'a la clave temporal 123456.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _cargando = true);
    try {
      final authRepo = AuthRepository();
      await authRepo.olvidarClave(matricula);
      if (!mounted) return;
      showSuccess(
        context,
        'Contraseña restablecida a 123456. Cámbiala al iniciar sesión.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Logo ───────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'AutoZone ITLA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Ingresa con tu matrícula y contraseña',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Matrícula ──────────────────────────────
                TextFormField(
                  controller:   _matriculaCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    hintText:  'Ej: 20001001',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'La matrícula es requerida';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Contraseña ─────────────────────────────
                TextFormField(
                  controller:      _contrasenaCtrl,
                  obscureText:     !_verClave,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText:  'Contraseña',
                    hintText:   'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _verClave
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _verClave = !_verClave),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (v.trim().length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // ── Olvidé mi contraseña ───────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cargando ? null : _olvidarClave,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Botón login ────────────────────────────
                _cargando
                    ? buildLoader()
                    : ElevatedButton.icon(
                        onPressed: _login,
                        icon: const Icon(Icons.login, size: 20),
                        label: const Text('Iniciar sesión'),
                      ),

                const SizedBox(height: 32),

                // ── Ir a registro ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistroScreen(),
                          ),
                        );
                      },
                      child: const Text('Regístrate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
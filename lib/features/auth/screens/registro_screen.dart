import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Paso 1: matrícula
  final _matriculaCtrl = TextEditingController();
  // Paso 2: activación
  final _contrasenaCtrl  = TextEditingController();
  final _confirmarCtrl   = TextEditingController();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  bool _cargando   = false;
  bool _verClave   = false;
  bool _verConfirm = false;
  int  _paso       = 1; // 1 = matrícula, 2 = activar

  String? _tokenTemporal;
  String? _nombreUsuario;

  final _auth = AuthRepository();

  @override
  void dispose() {
    _matriculaCtrl.dispose();
    _contrasenaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  // ── Paso 1: Registro ──────────────────────────────────────

  Future<void> _registrar() async {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final res  = await _auth.registro(_matriculaCtrl.text.trim());
      final data = res['data'] as Map<String, dynamic>;

      _tokenTemporal = data['token'] as String;
      _nombreUsuario = '${data['nombre']} ${data['apellido']}';

      if (!mounted) return;
      setState(() {
        _cargando = false;
        _paso     = 2;
      });

      showSuccess(context, '¡Hola $_nombreUsuario! Ahora establece tu contraseña.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      showError(context, e.message);
    }
  }

  // ── Paso 2: Activar ───────────────────────────────────────

  Future<void> _activar() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_tokenTemporal == null) return;
    setState(() => _cargando = true);

    try {
      await _auth.activar(
        _tokenTemporal!,
        _contrasenaCtrl.text.trim(),
      );

      if (!mounted) return;
      showSuccess(context, '¡Cuenta activada! Ya puedes iniciar sesión.');

      // Ir al login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);

      // Si el token expiró, volver al paso 1
      if (e.statusCode == 401) {
        setState(() => _paso = 1);
        showError(
          context,
          'El código expiró. Ingresa tu matrícula nuevamente.',
        );
      } else {
        showError(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_paso == 2) {
              setState(() => _paso = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Indicador de pasos ─────────────────────────
              _buildIndicadorPasos(),

              const SizedBox(height: 32),

              // ── Logo ───────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _paso == 1 ? 'Registrar cuenta' : 'Establecer contraseña',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                _paso == 1
                    ? 'Ingresa tu matrícula del ITLA'
                    : 'Hola${_nombreUsuario != null ? ", ${_nombreUsuario!.split(" ").first}" : ""}. Crea tu contraseña de acceso.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 36),

              // ── Formulario paso 1 ──────────────────────────
              if (_paso == 1) _buildFormPaso1(),

              // ── Formulario paso 2 ──────────────────────────
              if (_paso == 2) _buildFormPaso2(),

              const SizedBox(height: 32),

              // ── Ir a login ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes cuenta?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Inicia sesión'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Indicador de pasos ────────────────────────────────────

  Widget _buildIndicadorPasos() {
    return Row(
      children: [
        _paso1Indicador(1, 'Matrícula', _paso >= 1),
        Expanded(
          child: Container(
            height: 2,
            color: _paso >= 2 ? AppColors.primary : AppColors.divider,
          ),
        ),
        _paso1Indicador(2, 'Contraseña', _paso >= 2),
      ],
    );
  }

  Widget _paso1Indicador(int num, String label, bool activo) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              activo ? AppColors.primary : AppColors.divider,
          child: Text(
            '$num',
            style: TextStyle(
              color: activo ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: activo ? AppColors.primary : AppColors.textSecondary,
            fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Formulario paso 1 ─────────────────────────────────────

  Widget _buildFormPaso1() {
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          TextFormField(
            controller:   _matriculaCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _registrar(),
            decoration: const InputDecoration(
              labelText:  'Matrícula ITLA',
              hintText:   'Ej: 20001001',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'La matrícula es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _cargando
              ? buildLoader()
              : ElevatedButton.icon(
                  onPressed: _registrar,
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: const Text('Continuar'),
                ),
        ],
      ),
    );
  }

  // ── Formulario paso 2 ─────────────────────────────────────

  Widget _buildFormPaso2() {
    return Form(
      key: _formKey2,
      child: Column(
        children: [
          // Contraseña nueva
          TextFormField(
            controller:      _contrasenaCtrl,
            obscureText:     !_verClave,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText:  'Nueva contraseña',
              hintText:   'Mínimo 6 caracteres',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _verClave
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _verClave = !_verClave),
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

          const SizedBox(height: 16),

          // Confirmar contraseña
          TextFormField(
            controller:      _confirmarCtrl,
            obscureText:     !_verConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _activar(),
            decoration: InputDecoration(
              labelText:  'Confirmar contraseña',
              hintText:   'Repite la contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _verConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _verConfirm = !_verConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Confirma tu contraseña';
              }
              if (v.trim() != _contrasenaCtrl.text.trim()) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          _cargando
              ? buildLoader()
              : ElevatedButton.icon(
                  onPressed: _activar,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Activar cuenta'),
                ),
        ],
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _perfilRepo = PerfilRepository();
  final _picker     = ImagePicker();
  bool _subiendoFoto = false;

  // ── Cambiar foto ──────────────────────────────────────────

  Future<void> _cambiarFoto() async {
    final opcion = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.photo_library, color: Colors.white, size: 20),
              ),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (opcion == null || !mounted) return;

    final picked = await _picker.pickImage(
      source:    opcion,
      maxWidth:  800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked == null || !mounted) return;

    setState(() => _subiendoFoto = true);
    try {
      final res     = await _perfilRepo.subirFoto(File(picked.path));
      final fotoUrl = res['data']['fotoUrl'] as String;

      if (!mounted) return;
      context.read<AuthProvider>().actualizarFoto(fotoUrl);
      showSuccess(context, 'Foto actualizada correctamente');
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  // ── Cambiar contraseña ────────────────────────────────────

  Future<void> _cambiarClave() async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl  = TextEditingController();
    final formKey    = GlobalKey<FormState>();
    bool verActual   = false;
    bool verNueva    = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller:  actualCtrl,
                  obscureText: !verActual,
                  decoration: InputDecoration(
                    labelText:  'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(verActual
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setDialogState(() => verActual = !verActual),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerida' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller:  nuevaCtrl,
                  obscureText: !verNueva,
                  decoration: InputDecoration(
                    labelText:  'Nueva contraseña',
                    hintText:   'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(verNueva
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setDialogState(() => verNueva = !verNueva),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerida';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final authRepo = AuthRepository();
                  await authRepo.cambiarClave(
                    actualCtrl.text.trim(),
                    nuevaCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  showSuccess(context, 'Contraseña actualizada correctamente');
                } on ApiException catch (e) {
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  showError(context, e.message);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    actualCtrl.dispose();
    nuevaCtrl.dispose();
  }

  // ── Cerrar sesión ─────────────────────────────────────────

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pop(context);
    showInfo(context, 'Sesión cerrada');
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesión activa')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Cambiar contraseña',
            onPressed: _cambiarClave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Cabecera con foto ────────────────────────────
            _buildCabecera(usuario),

            const SizedBox(height: 24),

            // ── Datos del perfil ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildCard([
                    _buildFila(
                      Icons.person_outline,
                      'Nombre',
                      usuario.nombreCompleto,
                    ),
                    _buildFila(
                      Icons.badge_outlined,
                      'Matrícula',
                      usuario.matricula,
                    ),
                    _buildFila(
                      Icons.email_outlined,
                      'Correo',
                      usuario.correo,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _buildCard([
                    _buildFila(
                      Icons.school_outlined,
                      'Rol',
                      usuario.rol.isEmpty ? 'Estudiante' : usuario.rol,
                    ),
                    _buildFila(
                      Icons.group_outlined,
                      'Grupo',
                      usuario.grupo.isEmpty ? 'Sin asignar' : usuario.grupo,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── Opciones ─────────────────────────────────
                  _buildCard([
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                      ),
                      title: const Text('Cambiar contraseña'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _cambiarClave,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // ── Cerrar sesión ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cabecera con foto ─────────────────────────────────────

  Widget _buildCabecera(UsuarioSesion usuario) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Foto
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child: _subiendoFoto
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : usuario.fotoUrl != null
                          ? Image.network(
                              usuario.fotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarLetra(usuario),
                            )
                          : _avatarLetra(usuario),
                ),
              ),
              // Botón cámara
              GestureDetector(
                onTap: _subiendoFoto ? null : _cambiarFoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            usuario.nombreCompleto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            usuario.matricula,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarLetra(UsuarioSesion usuario) {
    return Container(
      color: AppColors.primaryDark,
      child: Center(
        child: Text(
          usuario.nombre[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Card contenedor ───────────────────────────────────────

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // ── Fila de dato ──────────────────────────────────────────

  Widget _buildFila(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
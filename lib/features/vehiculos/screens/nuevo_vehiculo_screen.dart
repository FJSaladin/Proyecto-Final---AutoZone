import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class NuevoVehiculoScreen extends StatefulWidget {
  const NuevoVehiculoScreen({super.key});

  @override
  State<NuevoVehiculoScreen> createState() => _NuevoVehiculoScreenState();
}

class _NuevoVehiculoScreenState extends State<NuevoVehiculoScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _repo         = VehiculosRepository();
  final _picker       = ImagePicker();

  final _placaCtrl    = TextEditingController();
  final _chasisCtrl   = TextEditingController();
  final _marcaCtrl    = TextEditingController();
  final _modeloCtrl   = TextEditingController();
  final _anioCtrl     = TextEditingController();

  int    _ruedas    = 4;
  File?  _foto;
  bool   _guardando = false;

  @override
  void dispose() {
    _placaCtrl.dispose();
    _chasisCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    super.dispose();
  }

  // ── Seleccionar foto ──────────────────────────────────────

  Future<void> _seleccionarFoto() async {
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
              'Foto del vehículo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

    if (opcion == null) return;
    final picked = await _picker.pickImage(
      source: opcion,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _foto = File(picked.path));
    }
  }

  // ── Guardar ───────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await _repo.registrar(
        placa:          _placaCtrl.text.trim(),
        chasis:         _chasisCtrl.text.trim(),
        marca:          _marcaCtrl.text.trim(),
        modelo:         _modeloCtrl.text.trim(),
        anio:           int.parse(_anioCtrl.text.trim()),
        cantidadRuedas: _ruedas,
        foto:           _foto,
      );
      if (!mounted) return;
      showSuccess(context, 'Vehículo registrado correctamente');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Foto ──────────────────────────────────────
              _buildSelectorFoto(),

              const SizedBox(height: 20),

              // ── Datos básicos ─────────────────────────────
              _buildSeccion('Datos del vehículo'),
              const SizedBox(height: 12),

              _buildCampo(
                controller: _placaCtrl,
                label: 'Placa',
                icono: Icons.pin_outlined,
                hint: 'Ej: A123456',
                validator: (v) => v == null || v.isEmpty ? 'La placa es requerida' : null,
                capitalizacion: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),

              _buildCampo(
                controller: _chasisCtrl,
                label: 'Número de chasis',
                icono: Icons.confirmation_number_outlined,
                hint: 'Ej: JN1AZ4EH7FM730887',
                validator: (v) => v == null || v.isEmpty ? 'El chasis es requerido' : null,
                capitalizacion: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCampo(
                      controller: _marcaCtrl,
                      label: 'Marca',
                      icono: Icons.directions_car_outlined,
                      hint: 'Ej: Toyota',
                      validator: (v) => v == null || v.isEmpty ? 'Requerida' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCampo(
                      controller: _modeloCtrl,
                      label: 'Modelo',
                      icono: Icons.car_repair_outlined,
                      hint: 'Ej: Corolla',
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCampo(
                      controller: _anioCtrl,
                      label: 'Año',
                      icono: Icons.calendar_today_outlined,
                      hint: 'Ej: 2020',
                      tipo: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final n = int.tryParse(v);
                        if (n == null || n < 1900 || n > 2100) return 'Año inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSelectorRuedas()),
                ],
              ),

              const SizedBox(height: 28),

              // ── Botón guardar ─────────────────────────────
              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(_guardando ? 'Guardando...' : 'Registrar vehículo'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Selector de foto ──────────────────────────────────────

  Widget _buildSelectorFoto() {
    return GestureDetector(
      onTap: _seleccionarFoto,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _foto != null
                ? AppColors.primary
                : AppColors.divider,
            width: _foto != null ? 2 : 1,
          ),
        ),
        child: _foto != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_foto!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Cambiar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agregar foto del vehículo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Opcional',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Selector de ruedas ────────────────────────────────────

  Widget _buildSelectorRuedas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ruedas',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _ruedas,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.tire_repair_outlined, size: 20),
            isDense: true,
          ),
          items: [2, 4, 6, 8, 10]
              .map(
                (n) => DropdownMenuItem(
                  value: n,
                  child: Text('$n ruedas'),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _ruedas = v ?? 4),
        ),
      ],
    );
  }

  // ── Título de sección ─────────────────────────────────────

  Widget _buildSeccion(String titulo) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Campo de texto ────────────────────────────────────────

  Widget _buildCampo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    String? hint,
    TextInputType tipo = TextInputType.text,
    TextCapitalization capitalizacion = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      textCapitalization: capitalizacion,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono, size: 20),
      ),
      validator: validator,
    );
  }
}
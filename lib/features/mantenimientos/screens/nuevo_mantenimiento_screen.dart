import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class NuevoMantenimientoScreen extends StatefulWidget {
  final int vehiculoId;
  const NuevoMantenimientoScreen({super.key, required this.vehiculoId});

  @override
  State<NuevoMantenimientoScreen> createState() =>
      _NuevoMantenimientoScreenState();
}

class _NuevoMantenimientoScreenState extends State<NuevoMantenimientoScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _repo       = MantenimientosRepository();
  final _picker     = ImagePicker();

  final _tipoCtrl   = TextEditingController();
  final _costoCtrl  = TextEditingController();
  final _piezasCtrl = TextEditingController();
  final _fechaCtrl  = TextEditingController();

  List<File> _fotos    = [];
  bool       _guardando = false;

  static const _tiposSugeridos = [
    'Cambio de aceite',
    'Cambio de frenos',
    'Cambio de filtros',
    'Cambio de batería',
    'Cambio de correa',
    'Revisión de suspensión',
    'Alineación y balanceo',
    'Revisión general',
  ];

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _costoCtrl.dispose();
    _piezasCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  // ── Seleccionar fecha ─────────────────────────────────────

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(2000),
      lastDate: hoy,
    );
    if (fecha != null) {
      _fechaCtrl.text =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    }
  }

  // ── Agregar foto ──────────────────────────────────────────

  Future<void> _agregarFoto() async {
    if (_fotos.length >= 5) {
      showInfo(context, 'Máximo 5 fotos permitidas');
      return;
    }

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
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Agregar foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
      source: opcion, maxWidth: 1024, maxHeight: 1024, imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _fotos.add(File(picked.path)));
    }
  }

  // ── Guardar ───────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await _repo.registrar(
        vehiculoId: widget.vehiculoId,
        tipo:       _tipoCtrl.text.trim(),
        costo:      double.parse(_costoCtrl.text.trim()),
        fecha:      _fechaCtrl.text.trim(),
        piezas:     _piezasCtrl.text.trim().isEmpty
                        ? null
                        : _piezasCtrl.text.trim(),
        fotos:      _fotos.isEmpty ? null : _fotos,
      );
      if (!mounted) return;
      showSuccess(context, 'Mantenimiento registrado');
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
      appBar: AppBar(title: const Text('Nuevo Mantenimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tipo ──────────────────────────────────────
              _buildSeccion('Información del mantenimiento'),
              const SizedBox(height: 12),

              // Sugerencias de tipo
              const Text(
                'Tipo de mantenimiento',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tiposSugeridos
                    .map((t) => GestureDetector(
                          onTap: () => setState(() => _tipoCtrl.text = t),
                          child: Chip(
                            label: Text(t,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _tipoCtrl.text == t
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                )),
                            backgroundColor: _tipoCtrl.text == t
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tipoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tipo (editable)',
                  prefixIcon: Icon(Icons.build_outlined, size: 20),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'El tipo es requerido' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Costo (RD\$)',
                        prefixIcon: Icon(Icons.attach_money, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fechaCtrl,
                      readOnly: true,
                      onTap: _seleccionarFecha,
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        prefixIcon:
                            Icon(Icons.calendar_today_outlined, size: 20),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerida' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _piezasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Piezas / Descripción (opcional)',
                  prefixIcon: Icon(Icons.settings_outlined, size: 20),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // ── Fotos ─────────────────────────────────────
              _buildSeccion('Fotos (máx. 5)'),
              const SizedBox(height: 12),
              _buildGaleriaFotos(),

              const SizedBox(height: 28),

              // ── Guardar ───────────────────────────────────
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
                label: Text(
                    _guardando ? 'Guardando...' : 'Registrar mantenimiento'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Galería de fotos ──────────────────────────────────────

  Widget _buildGaleriaFotos() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        // Fotos seleccionadas
        ..._fotos.asMap().entries.map(
              (e) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      e.value,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _fotos.removeAt(e.key)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        // Botón agregar (si no llegó al límite)
        if (_fotos.length < 5)
          GestureDetector(
            onTap: _agregarFoto,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fotos.length}/5',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Título de sección ─────────────────────────────────────

  Widget _buildSeccion(String titulo) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
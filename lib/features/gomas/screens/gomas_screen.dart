import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class GomasScreen extends StatefulWidget {
  final int    vehiculoId;
  final String vehiculoNombre;

  const GomasScreen({
    super.key,
    required this.vehiculoId,
    required this.vehiculoNombre,
  });

  @override
  State<GomasScreen> createState() => _GomasScreenState();
}

class _GomasScreenState extends State<GomasScreen> {
  final _repo = GomasRepository();

  List<dynamic> _gomas    = [];
  bool          _cargando = true;
  String        _error    = '';

  static const _estados = ['buena', 'regular', 'mala', 'reemplazada'];

  static const _coloresEstado = {
    'buena':       AppColors.success,
    'regular':     AppColors.warning,
    'mala':        AppColors.error,
    'reemplazada': AppColors.info,
  };

  static const _iconosEstado = {
    'buena':       Icons.check_circle_rounded,
    'regular':     Icons.warning_rounded,
    'mala':        Icons.cancel_rounded,
    'reemplazada': Icons.refresh_rounded,
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final res = await _repo.getEstado(widget.vehiculoId);
      setState(() => _gomas = res['data'] as List? ?? []);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _cargando = false);
    }
  }

  // ── Actualizar estado ─────────────────────────────────────

  Future<void> _actualizarEstado(int gomaId, String estadoActual) async {
    String nuevoEstado = estadoActual;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Cambiar estado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona el nuevo estado:'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: nuevoEstado,
                isExpanded: true,
                items: _estados
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Row(
                            children: [
                              Icon(
                                _iconosEstado[e],
                                color: _coloresEstado[e],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                e[0].toUpperCase() + e.substring(1),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlg(() => nuevoEstado = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true || nuevoEstado == estadoActual) return;

    try {
      await _repo.actualizarEstado(gomaId, nuevoEstado);
      if (!mounted) return;
      showSuccess(context, 'Estado actualizado');
      _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    }
  }

  // ── Registrar pinchazo ────────────────────────────────────

  Future<void> _registrarPinchazo(int gomaId, String posicion) async {
    final descCtrl  = TextEditingController();
    final fechaCtrl = TextEditingController();
    final formKey   = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pinchazo - $posicion'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerida' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fechaCtrl,
                readOnly: true,
                onTap: () async {
                  final hoy = DateTime.now();
                  final fecha = await showDatePicker(
                    context: ctx,
                    initialDate: hoy,
                    firstDate: DateTime(2000),
                    lastDate: hoy,
                  );
                  if (fecha != null) {
                    fechaCtrl.text =
                        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerida' : null,
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
                await _repo.registrarPinchazo(
                  gomaId: gomaId,
                  descripcion: descCtrl.text.trim(),
                  fecha: fechaCtrl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                showSuccess(context, 'Pinchazo registrado');
                _cargar();
              } on ApiException catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                showError(context, e.message);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    descCtrl.dispose();
    fechaCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estado de Gomas', style: TextStyle(fontSize: 16)),
            Text(widget.vehiculoNombre,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                )),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _buildContenido(),
    );
  }

  Widget _buildContenido() {
    if (_cargando) return buildLoader();
    if (_error.isNotEmpty) return buildErrorWidget(_error, _cargar);
    if (_gomas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tire_repair_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('No hay información de gomas',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Leyenda ──────────────────────────────────────
          _buildLeyenda(),
          const SizedBox(height: 20),
          // ── Tarjetas de gomas ────────────────────────────
          ..._gomas.map((g) => _buildTarjetaGoma(g as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _buildLeyenda() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _estados.map((e) {
        final color = _coloresEstado[e]!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconosEstado[e], color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              e[0].toUpperCase() + e.substring(1),
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTarjetaGoma(Map<String, dynamic> g) {
    final id       = g['id']       as int;
    final posicion = g['posicion'] as String? ?? 'Posición';
    final eje      = g['eje']      as String? ?? '';
    final estado   = (g['estado']  as String? ?? 'buena').toLowerCase();
    final color    = _coloresEstado[estado] ?? AppColors.textSecondary;
    final icono    = _iconosEstado[estado]  ?? Icons.tire_repair_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícono con color de estado
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(posicion,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                  if (eje.isNotEmpty)
                    Text('Eje: $eje',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        )),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estado[0].toUpperCase() + estado.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Acciones
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (accion) {
                if (accion == 'estado') {
                  _actualizarEstado(id, estado);
                } else if (accion == 'pinchazo') {
                  _registrarPinchazo(id, posicion);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'estado',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Cambiar estado'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pinchazo',
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Registrar pinchazo',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../mantenimientos/screens/mantenimientos_screen.dart';
import '../../gomas/screens/gomas_screen.dart';

class DetalleVehiculoScreen extends StatefulWidget {
  final int vehiculoId;
  const DetalleVehiculoScreen({super.key, required this.vehiculoId});

  @override
  State<DetalleVehiculoScreen> createState() => _DetalleVehiculoScreenState();
}

class _DetalleVehiculoScreenState extends State<DetalleVehiculoScreen> {
  final _repo   = VehiculosRepository();
  final _picker = ImagePicker();

  Map<String, dynamic>? _vehiculo;
  bool   _cargando      = true;
  bool   _subiendoFoto  = false;
  String _error         = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final res = await _repo.detalle(widget.vehiculoId);
      setState(() => _vehiculo = res['data'] as Map<String, dynamic>?);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _cargando = false);
    }
  }

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
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Foto del vehículo',
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

    if (opcion == null || !mounted) return;
    final picked = await _picker.pickImage(
      source: opcion, maxWidth: 1024, maxHeight: 1024, imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _subiendoFoto = true);
    try {
      await _repo.subirFoto(widget.vehiculoId, File(picked.path));
      if (!mounted) return;
      showSuccess(context, 'Foto actualizada');
      _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: buildLoader(),
      );
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: buildErrorWidget(_error, _cargar),
      );
    }

    final v       = _vehiculo!;
    final resumen = v['resumen'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('${v['marca']} ${v['modelo']}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Foto de cabecera ───────────────────────────
            _buildFoto(v['fotoUrl'] as String?),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Datos del vehículo ───────────────────
                  _buildTituloSeccion('Datos del vehículo'),
                  const SizedBox(height: 10),
                  _buildCard([
                    _buildFila(Icons.pin_outlined,            'Placa',   v['placa'] ?? '-'),
                    _buildFila(Icons.confirmation_number_outlined, 'Chasis', v['chasis'] ?? '-'),
                    _buildFila(Icons.directions_car_outlined, 'Marca',   v['marca']  ?? '-'),
                    _buildFila(Icons.car_repair_outlined,     'Modelo',  v['modelo'] ?? '-'),
                    _buildFila(Icons.calendar_today_outlined, 'Año',     '${v['anio'] ?? '-'}'),
                    _buildFila(Icons.tire_repair_outlined,    'Ruedas',  '${v['cantidadRuedas'] ?? '-'}'),
                  ]),

                  const SizedBox(height: 20),

                  // ── Resumen financiero ───────────────────
                  _buildTituloSeccion('Resumen financiero'),
                  const SizedBox(height: 10),
                  _buildResumen(resumen),

                  const SizedBox(height: 20),

                  // ── Accesos rápidos ──────────────────────
                  _buildTituloSeccion('Acciones'),
                  const SizedBox(height: 10),
                  _buildAcciones(v),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Foto de cabecera con overlay ──────────────────────────

  Widget _buildFoto(String? fotoUrl) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 220,
          child: _subiendoFoto
              ? Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : fotoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: fotoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.background),
                      errorWidget: (_, __, ___) => _fotoPlaceholder(),
                    )
                  : _fotoPlaceholder(),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _subiendoFoto ? null : _cambiarFoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Cambiar foto',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.directions_car, size: 80, color: AppColors.primary),
      ),
    );
  }

  // ── Resumen financiero en tarjetas ────────────────────────

  Widget _buildResumen(Map<String, dynamic> r) {
    double total(String k) =>
        (r[k] as num?)?.toDouble() ?? 0.0;

    final balance = total('totalIngresos') -
        total('totalMantenimientos') -
        total('totalCombustible') -
        total('totalGastos');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _tarjetaFinanciera(
                'Mantenimientos',
                total('totalMantenimientos'),
                Icons.build_rounded,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tarjetaFinanciera(
                'Combustible',
                total('totalCombustible'),
                Icons.local_gas_station_rounded,
                AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tarjetaFinanciera(
                'Gastos',
                total('totalGastos'),
                Icons.receipt_long_rounded,
                AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tarjetaFinanciera(
                'Ingresos',
                total('totalIngresos'),
                Icons.trending_up_rounded,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Balance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (balance >= 0 ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (balance >= 0 ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                balance >= 0
                    ? Icons.account_balance_wallet_rounded
                    : Icons.money_off_rounded,
                color: balance >= 0 ? AppColors.success : AppColors.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'RD\$ ${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: balance >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaFinanciera(
      String titulo, double monto, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'RD\$ ${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Botones de acciones ───────────────────────────────────

  Widget _buildAcciones(Map<String, dynamic> v) {
    return Column(
      children: [
        _botonAccion(
          icono: Icons.build_rounded,
          titulo: 'Mantenimientos',
          subtitulo: 'Historial y nuevos registros',
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MantenimientosScreen(
                vehiculoId: widget.vehiculoId,
                vehiculoNombre: '${v['marca']} ${v['modelo']}',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _botonAccion(
          icono: Icons.tire_repair_rounded,
          titulo: 'Estado de Gomas',
          subtitulo: 'Ver estado y registrar pinchazos',
          color: AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GomasScreen(
                vehiculoId: widget.vehiculoId,
                vehiculoNombre: '${v['marca']} ${v['modelo']}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonAccion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _buildTituloSeccion(String titulo) {
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
            .map((e) => Column(children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(height: 1, indent: 56),
                ]))
            .toList(),
      ),
    );
  }

  Widget _buildFila(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 2),
              Text(valor,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import 'nuevo_vehiculo_screen.dart';
import 'detalle_vehiculo_screen.dart';

class MisVehiculosScreen extends StatefulWidget {
  const MisVehiculosScreen({super.key});

  @override
  State<MisVehiculosScreen> createState() => _MisVehiculosScreenState();
}

class _MisVehiculosScreenState extends State<MisVehiculosScreen> {
  final _repo          = VehiculosRepository();
  final _marcaCtrl     = TextEditingController();
  final _modeloCtrl    = TextEditingController();

  List<dynamic> _vehiculos = [];
  bool   _cargando  = true;
  String _error     = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final res = await _repo.listar(
        marca:  _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim().isEmpty ? null : _modeloCtrl.text.trim(),
      );
      setState(() => _vehiculos = res['data'] as List? ?? []);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    _cargar();
  }

  void _limpiar() {
    _marcaCtrl.clear();
    _modeloCtrl.clear();
    _cargar();
  }

  Future<void> _irAgregar() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevoVehiculoScreen()),
    );
    if (creado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irAgregar,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Column(
        children: [
          // ── Filtros ────────────────────────────────────────
          _buildFiltros(),

          // ── Lista ──────────────────────────────────────────
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  // ── Panel de filtros ──────────────────────────────────────

  Widget _buildFiltros() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _marcaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _modeloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _buscar,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _limpiar,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpiar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contenido principal ───────────────────────────────────

  Widget _buildContenido() {
    if (_cargando) return buildLoader();
    if (_error.isNotEmpty) return buildErrorWidget(_error, _cargar);
    if (_vehiculos.isEmpty) return _buildVacio();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _vehiculos.length,
        itemBuilder: (_, i) => _buildTarjeta(_vehiculos[i]),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.garage_outlined, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No tienes vehículos registrados',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _irAgregar,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar vehículo'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 46)),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta de vehículo ───────────────────────────────────

  Widget _buildTarjeta(Map<String, dynamic> v) {
    final fotoUrl = v['fotoUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final actualizado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleVehiculoScreen(vehiculoId: v['id'] as int),
            ),
          );
          if (actualizado == true) _cargar();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Foto o ícono
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.background,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: fotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: fotoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => _iconoVehiculo(),
                        )
                      : _iconoVehiculo(),
                ),
              ),
              const SizedBox(width: 14),
              // Datos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${v['marca']} ${v['modelo']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _chip(Icons.calendar_today_outlined, '${v['anio']}'),
                    const SizedBox(height: 4),
                    _chip(Icons.pin_outlined, v['placa'] as String? ?? '-'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconoVehiculo() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.directions_car, size: 32, color: AppColors.primary),
    );
  }

  Widget _chip(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
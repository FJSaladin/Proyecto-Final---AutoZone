import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import 'nuevo_mantenimiento_screen.dart';

class MantenimientosScreen extends StatefulWidget {
  final int    vehiculoId;
  final String vehiculoNombre;

  const MantenimientosScreen({
    super.key,
    required this.vehiculoId,
    required this.vehiculoNombre,
  });

  @override
  State<MantenimientosScreen> createState() => _MantenimientosScreenState();
}

class _MantenimientosScreenState extends State<MantenimientosScreen> {
  final _repo = MantenimientosRepository();

  List<dynamic> _lista    = [];
  bool          _cargando = true;
  String        _error    = '';
  String?       _tipoFiltro;

  static const _tipos = [
    'Cambio de aceite',
    'Frenos',
    'Filtros',
    'Batería',
    'Correa',
    'Suspensión',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final res = await _repo.listar(
        vehiculoId: widget.vehiculoId,
        tipo: _tipoFiltro,
      );
      setState(() => _lista = res['data'] as List? ?? []);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _verDetalle(int id) async {
    setState(() => _cargando = true);
    try {
      final res   = await _repo.detalle(id);
      final detalle = res['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarDetalle(detalle);
    } on ApiException catch (e) {
      setState(() { _cargando = false; });
      if (!mounted) return;
      showError(context, e.message);
    }
  }

  void _mostrarDetalle(Map<String, dynamic> d) {
    final fotos = (d['fotos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(d['tipo'] as String? ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 16),
              _filaDetalle(Icons.build_outlined,          'Tipo',    d['tipo']   ?? '-'),
              _filaDetalle(Icons.attach_money,            'Costo',   'RD\$ ${d['costo'] ?? 0}'),
              _filaDetalle(Icons.settings_outlined,       'Piezas',  d['piezas'] ?? 'N/A'),
              _filaDetalle(Icons.calendar_today_outlined, 'Fecha',   d['fecha']  ?? '-'),
              if (fotos.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Fotos',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final url = fotos[i]['url'] as String? ?? '';
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaDetalle(IconData icono, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  )),
              Text(valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mantenimientos', style: TextStyle(fontSize: 16)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final creado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => NuevoMantenimientoScreen(
                vehiculoId: widget.vehiculoId,
              ),
            ),
          );
          if (creado == true) _cargar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Column(
        children: [
          // ── Filtro por tipo ────────────────────────────────
          _buildFiltroTipo(),
          // ── Lista ─────────────────────────────────────────
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildFiltroTipo() {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chipFiltro('Todos', null),
          ..._tipos.map((t) => _chipFiltro(t, t)),
        ],
      ),
    );
  }

  Widget _chipFiltro(String label, String? valor) {
    final activo = _tipoFiltro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: activo,
        onSelected: (_) {
          setState(() => _tipoFiltro = valor);
          _cargar();
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          color: activo ? AppColors.primary : AppColors.textPrimary,
          fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) return buildLoader();
    if (_error.isNotEmpty) return buildErrorWidget(_error, _cargar);
    if (_lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build_circle_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('Sin mantenimientos registrados',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _lista.length,
        itemBuilder: (_, i) => _buildItem(_lista[i]),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.build_rounded,
              color: AppColors.warning, size: 22),
        ),
        title: Text(
          m['tipo'] as String? ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m['fecha'] as String? ?? '-',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'RD\$ ${m['costo'] ?? 0}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () => _verDetalle(m['id'] as int),
      ),
    );
  }
}
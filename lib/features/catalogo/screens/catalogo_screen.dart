import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import 'detalle_catalogo_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _repo       = CatalogoRepository();
  final _marcaCtrl  = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anioCtrl   = TextEditingController();
  final _minCtrl    = TextEditingController();
  final _maxCtrl    = TextEditingController();

  List<dynamic> _lista    = [];
  bool          _cargando = true;
  String        _error    = '';
  bool          _filtrosVisibles = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    FocusScope.of(context).unfocus();
    try {
      final res = await _repo.listar(
        marca:     _marcaCtrl.text.trim().isEmpty  ? null : _marcaCtrl.text.trim(),
        modelo:    _modeloCtrl.text.trim().isEmpty ? null : _modeloCtrl.text.trim(),
        anio:      int.tryParse(_anioCtrl.text.trim()),
        precioMin: double.tryParse(_minCtrl.text.trim()),
        precioMax: double.tryParse(_maxCtrl.text.trim()),
        limit:     30,
      );
      final data = res['data'];
if (data is List) {
  setState(() => _lista = data);
} else if (data is Map && data['items'] != null) {
  setState(() => _lista = data['items'] as List? ?? []);
} else {
  setState(() => _lista = []);
}
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _limpiar() {
    _marcaCtrl.clear();
    _modeloCtrl.clear();
    _anioCtrl.clear();
    _minCtrl.clear();
    _maxCtrl.clear();
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Vehículos'),
        actions: [
          IconButton(
            icon: Icon(
              _filtrosVisibles ? Icons.filter_list_off : Icons.filter_list,
            ),
            tooltip: 'Filtros',
            onPressed: () =>
                setState(() => _filtrosVisibles = !_filtrosVisibles),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros (colapsables) ──────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _filtrosVisibles
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildFiltros(),
            secondChild: const SizedBox.shrink(),
          ),
          // ── Resultados ─────────────────────────────────────
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _campoFiltro(_marcaCtrl, 'Marca', Icons.directions_car_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _campoFiltro(_modeloCtrl, 'Modelo', Icons.car_repair_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _campoFiltro(
                  _anioCtrl, 'Año', Icons.calendar_today_outlined,
                  tipo: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _campoFiltro(
                  _minCtrl, 'Precio min', Icons.attach_money,
                  tipo: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _campoFiltro(
                  _maxCtrl, 'Precio max', Icons.money_off_outlined,
                  tipo: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Buscar'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _limpiar,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpiar'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campoFiltro(
    TextEditingController ctrl,
    String label,
    IconData icono, {
    TextInputType tipo = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, size: 18),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onSubmitted: (_) => _cargar(),
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
            const Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('No se encontraron vehículos',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _limpiar,
              child: const Text('Ver todos'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _lista.length,
        itemBuilder: (_, i) => _buildTarjeta(_lista[i]),
      ),
    );
  }

  Widget _buildTarjeta(Map<String, dynamic> v) {
    final foto  = v['fotoUrl']     as String?;
    final marca = v['marca']       as String? ?? '';
    final modelo= v['modelo']      as String? ?? '';
    final anio  = v['anio']        as int?;
    final precio= (v['precio'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleCatalogoScreen(catalogoId: v['id'] as int),
        ),
      ),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: foto != null
                    ? CachedNetworkImage(
                        imageUrl: foto,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.background),
                        errorWidget: (_, __, ___) => _fotoDefault(),
                      )
                    : _fotoDefault(),
              ),
            ),
            // Datos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$marca $modelo',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (anio != null)
                    Text(
                      '$anio',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'US\$ ${precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoDefault() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.directions_car, size: 48, color: AppColors.primary),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class DetalleCatalogoScreen extends StatefulWidget {
  final int catalogoId;
  const DetalleCatalogoScreen({super.key, required this.catalogoId});

  @override
  State<DetalleCatalogoScreen> createState() => _DetalleCatalogoScreenState();
}

class _DetalleCatalogoScreenState extends State<DetalleCatalogoScreen> {
  final _repo = CatalogoRepository();

  Map<String, dynamic>? _vehiculo;
  bool   _cargando = true;
  String _error    = '';
  int    _fotoActiva = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final res = await _repo.detalle(widget.catalogoId);
      setState(() => _vehiculo = res['data'] as Map<String, dynamic>?);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _cargando = false);
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

    final v     = _vehiculo!;
    final fotos = (v['fotos'] as List?)?.cast<String>() ??
        (v['fotoUrl'] != null ? [v['fotoUrl'] as String] : <String>[]);
    final specs = v['especificaciones'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar con galería ───────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            title: Text('${v['marca']} ${v['modelo']}'),
            flexibleSpace: FlexibleSpaceBar(
              background: fotos.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: fotos.length,
                          onPageChanged: (i) =>
                              setState(() => _fotoActiva = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: fotos[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppColors.background),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primary
                                  .withValues(alpha: 0.08),
                              child: const Icon(Icons.directions_car,
                                  size: 80, color: AppColors.primary),
                            ),
                          ),
                        ),
                        if (fotos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                fotos.length,
                                (i) => AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: _fotoActiva == i ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _fotoActiva == i
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.5),
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: const Center(
                        child: Icon(Icons.directions_car,
                            size: 100, color: AppColors.primary),
                      ),
                    ),
            ),
          ),

          // ── Contenido ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y precio
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${v['marca']} ${v['modelo']}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (v['anio'] != null)
                              Text(
                                '${v['anio']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'US\$ ${(v['precio'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  if (v['descripcion'] != null &&
                      (v['descripcion'] as String).isNotEmpty) ...[
                    _buildTituloSeccion('Descripción'),
                    const SizedBox(height: 8),
                    Text(
                      v['descripcion'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Especificaciones
                  if (specs.isNotEmpty) ...[
                    _buildTituloSeccion('Especificaciones'),
                    const SizedBox(height: 10),
                    _buildEspecificaciones(specs),
                    const SizedBox(height: 20),
                  ],

                  // Info básica si no hay specs
                  if (specs.isEmpty) ...[
                    _buildTituloSeccion('Información'),
                    const SizedBox(height: 10),
                    _buildCard([
                      if (v['marca']  != null)
                        _buildFila(Icons.directions_car_outlined,
                            'Marca',  v['marca'].toString()),
                      if (v['modelo'] != null)
                        _buildFila(Icons.car_repair_outlined,
                            'Modelo', v['modelo'].toString()),
                      if (v['anio']   != null)
                        _buildFila(Icons.calendar_today_outlined,
                            'Año',   '${v['anio']}'),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // Galería miniaturas (si hay más de 1 foto)
                  if (fotos.length > 1) ...[
                    _buildTituloSeccion('Galería'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () =>
                              setState(() => _fotoActiva = i),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: _fotoActiva == i
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: CachedNetworkImage(
                                imageUrl: fotos[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Especificaciones en grid ──────────────────────────────

  Widget _buildEspecificaciones(Map<String, dynamic> specs) {
    final items = specs.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final e = items[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                e.key,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                e.value.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
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
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
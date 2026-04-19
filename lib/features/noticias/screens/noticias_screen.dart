import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/noticia_model.dart';
import 'detalle_noticia_screen.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  final _noticiasRepo = NoticiasRepository();
  List<Noticia> _noticias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNoticias();
  }

  Future<void> _cargarNoticias() async {
    setState(() => _cargando = true);
    try {
      final res = await _noticiasRepo.getNoticias();
      if (mounted) {
        setState(() {
          _noticias = (res['data'] as List)
              .map((n) => Noticia.fromJson(n))
              .toList();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar noticias: $e');
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias del Sector'),
      ),
      body: _cargando
          ? buildLoader()
          : RefreshIndicator(
              onRefresh: _cargarNoticias,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _noticias.length,
                itemBuilder: (context, index) {
                  final noticia = _noticias[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleNoticiaScreen(noticiaId: noticia.id),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CachedNetworkImage(
                            imageUrl: noticia.imagenUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.divider,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      noticia.fuente.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      noticia.fecha,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  noticia.titulo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  noticia.resumen,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

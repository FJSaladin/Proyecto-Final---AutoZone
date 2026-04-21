import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/noticia_model.dart';

class DetalleNoticiaScreen extends StatefulWidget {
  final int noticiaId;
  const DetalleNoticiaScreen({super.key, required this.noticiaId});

  @override
  State<DetalleNoticiaScreen> createState() => _DetalleNoticiaScreenState();
}

class _DetalleNoticiaScreenState extends State<DetalleNoticiaScreen> {
  final _noticiasRepo = NoticiasRepository();
  Noticia? _noticia;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _cargando = true);
    try {
      final res = await _noticiasRepo.getDetalle(widget.noticiaId);
      if (mounted) {
        setState(() {
          _noticia = Noticia.fromJson(res['data']);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar detalle: $e');
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _abrirEnNavegador() async {
    if (_noticia == null) return;
    final url = Uri.parse(_noticia!.link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showError(context, 'No se pudo abrir el enlace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noticia')),
      body: _cargando
          ? buildLoader()
          : _noticia == null
              ? buildErrorWidget('No se encontró la noticia', _cargarDetalle)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedNetworkImage(
                        imageUrl: _noticia!.imagenUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _noticia!.fuente.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _noticia!.titulo,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _noticia!.fecha,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const Divider(height: 40),
                            Text(
                              _noticia!.resumen,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_noticia!.contenido != null)
                              Text(
                                _noticia!.contenido!
                                    .replaceAll(RegExp(r'<[^>]*>'), '')
                                    .trim(),
                                style: const TextStyle(fontSize: 15, height: 1.5),
                              ),
                            const SizedBox(height: 40),
                            ElevatedButton.icon(
                              onPressed: _abrirEnNavegador,
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('LEER ARTÍCULO COMPLETO'),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

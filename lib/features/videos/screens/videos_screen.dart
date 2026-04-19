import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/video_model.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final _videosRepo = VideosRepository();
  List<Video> _videos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVideos();
  }

  Future<void> _cargarVideos() async {
    setState(() => _cargando = true);
    try {
      final res = await _videosRepo.listar();
      if (mounted) {
        setState(() {
          _videos = (res['data'] as List)
              .map((v) => Video.fromJson(v))
              .toList();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar videos: $e');
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _reproducirVideo(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showError(context, 'No se pudo abrir el video');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos de Mantenimiento'),
      ),
      body: _cargando
          ? buildLoader()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return InkWell(
                  onTap: () => _reproducirVideo(video.url),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CachedNetworkImage(
                              imageUrl: video.thumbnail,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.categoria,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                video.titulo,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
    );
  }
}

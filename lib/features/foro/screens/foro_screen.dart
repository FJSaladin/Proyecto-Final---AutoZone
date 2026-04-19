import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/foro_model.dart';
import 'detalle_foro_screen.dart';
import 'nuevo_tema_screen.dart';

class ForoScreen extends StatefulWidget {
  const ForoScreen({super.key});

  @override
  State<ForoScreen> createState() => _ForoScreenState();
}

class _ForoScreenState extends State<ForoScreen> {
  final _foroRepo = ForoRepository();
  List<Tema> _temas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTemas();
  }

  Future<void> _cargarTemas() async {
    setState(() => _cargando = true);
    try {
      final res = await _foroRepo.getTemas();
      if (mounted) {
        setState(() {
          _temas = (res['data'] as List).map((t) => Tema.fromJson(t)).toList();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar el foro: $e');
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foro de Comunidad'),
        actions: [
          IconButton(
            onPressed: _cargarTemas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? buildLoader()
          : _temas.isEmpty
              ? buildErrorWidget('No hay temas en el foro aún.', _cargarTemas)
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _temas.length,
                  itemBuilder: (context, index) {
                    final tema = _temas[index];
                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleForoScreen(temaId: tema.id),
                          ),
                        ).then((_) => _cargarTemas()),
                        leading: Hero(
                          tag: 'foro_img_${tema.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              tema.vehiculoFoto,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 40),
                            ),
                          ),
                        ),
                        title: Text(
                          tema.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tema.vehiculo, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                            Text('Por: ${tema.autor}', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.comment, size: 20, color: AppColors.textSecondary),
                            Text('${tema.totalRespuestas}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: auth.estaLogueado
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NuevoTemaScreen()),
              ).then((_) => _cargarTemas()),
              label: const Text('Preguntar'),
              icon: const Icon(Icons.add_comment),
            )
          : null,
    );
  }
}

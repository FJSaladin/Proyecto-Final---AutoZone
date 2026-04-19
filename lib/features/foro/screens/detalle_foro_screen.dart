import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/foro_model.dart';

class DetalleForoScreen extends StatefulWidget {
  final int temaId;
  const DetalleForoScreen({super.key, required this.temaId});

  @override
  State<DetalleForoScreen> createState() => _DetalleForoScreenState();
}

class _DetalleForoScreenState extends State<DetalleForoScreen> {
  final _foroRepo = ForoRepository();
  Tema? _tema;
  bool _cargando = true;
  final _respuestaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _cargando = true);
    try {
      final res = await _foroRepo.detalleTema(widget.temaId);
      if (mounted) {
        setState(() {
          _tema = Tema.fromJson(res['data']);
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

  Future<void> _enviarRespuesta() async {
    if (_respuestaCtrl.text.trim().isEmpty) return;

    try {
      await _foroRepo.responder(
        temaId: widget.temaId,
        contenido: _respuestaCtrl.text.trim(),
      );
      _respuestaCtrl.clear();
      if (mounted) {
        showSuccess(context, 'Respuesta publicada');
        _cargarDetalle();
      }
    } catch (e) {
      showError(context, 'Error al responder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tema del Foro')),
      body: _cargando
          ? buildLoader()
          : _tema == null
              ? buildErrorWidget('No se pudo cargar el tema.', _cargarDetalle)
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cabecera del tema
                            Row(
                              children: [
                                Hero(
                                  tag: 'foro_img_${_tema!.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _tema!.vehiculoFoto,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _tema!.titulo,
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                      Text(_tema!.vehiculo, style: const TextStyle(color: AppColors.primary)),
                                      Text('Por: ${_tema!.autor}', style: const TextStyle(fontSize: 12)),
                                      Text(_tema!.fecha, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Text(_tema!.descripcion, style: const TextStyle(fontSize: 16)),
                            const Divider(height: 32),
                            Text(
                              'Respuestas (${_tema!.totalRespuestas})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            // Lista de respuestas
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tema!.respuestas?.length ?? 0,
                              itemBuilder: (context, index) {
                                final r = _tema!.respuestas![index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(r.autor, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                            Text(r.fecha, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(r.contenido),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Input para responder (solo si está logueado)
                    if (auth.estaLogueado)
                      Container(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.of(context).padding.bottom + 8,
                          top: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _respuestaCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Escribe una respuesta...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                maxLines: null,
                              ),
                            ),
                            IconButton(
                              onPressed: _enviarRespuesta,
                              icon: const Icon(Icons.send, color: AppColors.primary),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Inicia sesión para participar en el foro',
                          style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class NuevoTemaScreen extends StatefulWidget {
  const NuevoTemaScreen({super.key});

  @override
  State<NuevoTemaScreen> createState() => _NuevoTemaScreenState();
}

class _NuevoTemaScreenState extends State<NuevoTemaScreen> {
  final _foroRepo = ForoRepository();
  final _vehiculosRepo = VehiculosRepository();

  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<dynamic> _vehiculosConFoto = [];
  int? _vehiculoId;
  bool _cargandoVehiculos = true;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final res = await _vehiculosRepo.listar();
      final lista = res['data'] as List;
      
      if (mounted) {
        setState(() {
          // Filtrar solo vehículos que tengan foto (según la guía)
          _vehiculosConFoto = lista.where((v) => v['foto_url'] != null).toList();
          _cargandoVehiculos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar tus vehículos: $e');
        setState(() => _cargandoVehiculos = false);
      }
    }
  }

  Future<void> _crearTema() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehiculoId == null) {
      showError(context, 'Debes seleccionar un vehículo con foto');
      return;
    }

    try {
      await _foroRepo.crearTema(
        vehiculoId: _vehiculoId!,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
      );
      if (mounted) {
        showSuccess(context, 'Consulta publicada con éxito');
        Navigator.pop(context);
      }
    } catch (e) {
      showError(context, 'Error al crear tema: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Consulta')),
      body: _cargandoVehiculos
          ? buildLoader()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Selecciona el vehículo del problema',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _vehiculosConFoto.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'No tienes vehículos con foto registrados. El foro requiere un vehículo con foto para crear un tema.',
                              style: TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: _vehiculoId,
                            decoration: const InputDecoration(
                              hintText: 'Selecciona un vehículo',
                            ),
                            items: _vehiculosConFoto.map((v) {
                              return DropdownMenuItem<int>(
                                value: v['id'] as int,
                                child: Text('${v['marca']} ${v['modelo']}'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _vehiculoId = val),
                            validator: (v) => v == null ? 'Selecciona un vehículo' : null,
                          ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título de la consulta',
                        hintText: 'Ej: Ruido extraño al encender',
                      ),
                      validator: (v) => v!.isEmpty ? 'Ingresa un título' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción detallada',
                        hintText: 'Explica lo que sucede con tu vehículo...',
                      ),
                      maxLines: 5,
                      validator: (v) => v!.isEmpty ? 'Ingresa una descripción' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _vehiculosConFoto.isEmpty ? null : _crearTema,
                      child: const Text('PUBLICAR EN EL FORO'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

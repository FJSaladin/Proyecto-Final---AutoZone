import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/gasto_model.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _vehiculosRepo = VehiculosRepository();
  final _gastosRepo = GastosRepository();

  List<dynamic> _vehiculos = [];
  int? _vehiculoSeleccionadoId;
  
  List<CategoriaGasto> _categorias = [];
  int? _categoriaFiltroId; // null = todas
  
  List<Gasto> _gastos = [];
  bool _cargandoVehiculos = true;
  bool _cargandoCategorias = true;
  bool _cargandoGastos = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await Future.wait([
      _cargarVehiculos(),
      _cargarCategorias(),
    ]);
  }

  Future<void> _cargarVehiculos() async {
    try {
      final res = await _vehiculosRepo.listar();
      if (mounted) {
        setState(() {
          _vehiculos = res['data'] as List;
          if (_vehiculos.isNotEmpty) {
            _vehiculoSeleccionadoId = _vehiculos.first['id'];
            _cargarGastos();
          }
          _cargandoVehiculos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar vehículos: $e');
        setState(() => _cargandoVehiculos = false);
      }
    }
  }

  Future<void> _cargarCategorias() async {
    try {
      final res = await _gastosRepo.getCategorias();
      if (mounted) {
        setState(() {
          _categorias = (res['data'] as List)
              .map((json) => CategoriaGasto.fromJson(json))
              .toList();
          _cargandoCategorias = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar categorías: $e');
        setState(() => _cargandoCategorias = false);
      }
    }
  }

  Future<void> _cargarGastos() async {
    if (_vehiculoSeleccionadoId == null) return;
    setState(() => _cargandoGastos = true);
    try {
      final res = await _gastosRepo.listar(
        vehiculoId: _vehiculoSeleccionadoId!,
        categoriaId: _categoriaFiltroId,
      );
      if (mounted) {
        setState(() {
          _gastos = (res['data'] as List)
              .map((json) => Gasto.fromJson(json))
              .toList();
          _cargandoGastos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar gastos: $e');
        setState(() => _cargandoGastos = false);
      }
    }
  }

  void _mostrarFormularioNuevo() {
    if (_vehiculoSeleccionadoId == null) {
      showError(context, 'Selecciona un vehículo primero');
      return;
    }

    final formKey = GlobalKey<FormState>();
    int? categoriaSeleccionadaId = _categorias.isNotEmpty ? _categorias.first.id : null;
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar Gasto',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: categoriaSeleccionadaId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.nombre));
                  }).toList(),
                  onChanged: (v) => categoriaSeleccionadaId = v,
                  validator: (v) => v == null ? 'Selecciona una categoría' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) => v!.isEmpty ? 'Ingresa el monto' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await _gastosRepo.registrar(
                          vehiculoId: _vehiculoSeleccionadoId!,
                          categoriaId: categoriaSeleccionadaId!,
                          monto: double.parse(montoCtrl.text),
                          descripcion: descCtrl.text,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          showSuccess(context, 'Gasto registrado correctamente');
                          _cargarGastos();
                        }
                      } catch (e) {
                        showError(context, 'Error: $e');
                      }
                    }
                  },
                  child: const Text('GUARDAR GASTO'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos del Vehículo'),
      ),
      body: (_cargandoVehiculos || _cargandoCategorias)
          ? buildLoader()
          : Column(
              children: [
                // Card de selección y filtro
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: _vehiculoSeleccionadoId,
                          decoration: const InputDecoration(labelText: 'Vehículo'),
                          items: _vehiculos.map((v) {
                            return DropdownMenuItem<int>(
                              value: v['id'] as int,
                              child: Text('${v['marca']} ${v['modelo']}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _vehiculoSeleccionadoId = val;
                              _cargarGastos();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          value: _categoriaFiltroId,
                          decoration: const InputDecoration(labelText: 'Filtrar por categoría'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
                            ..._categorias.map((c) {
                              return DropdownMenuItem(value: c.id, child: Text(c.nombre));
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _categoriaFiltroId = val;
                              _cargarGastos();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de Gastos
                Expanded(
                  child: _cargandoGastos
                      ? buildLoader()
                      : _gastos.isEmpty
                          ? buildErrorWidget(
                              'No se encontraron gastos.',
                              _cargarGastos,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _gastos.length,
                              itemBuilder: (context, index) {
                                final gasto = _gastos[index];
                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: AppColors.error,
                                      child: Icon(Icons.money_off, color: Colors.white),
                                    ),
                                    title: Text(
                                      gasto.categoriaNombre,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (gasto.descripcion != null && gasto.descripcion!.isNotEmpty)
                                          Text(gasto.descripcion!),
                                        Text(gasto.fecha, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    trailing: Text(
                                      '-\$${gasto.monto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioNuevo,
        label: const Text('Nuevo Gasto'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

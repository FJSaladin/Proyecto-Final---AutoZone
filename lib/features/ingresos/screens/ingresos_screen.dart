import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/ingreso_model.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  final _vehiculosRepo = VehiculosRepository();
  final _ingresosRepo = IngresosRepository();

  List<dynamic> _vehiculos = [];
  int? _vehiculoSeleccionadoId;
  List<Ingreso> _ingresos = [];
  
  bool _cargandoVehiculos = true;
  bool _cargandoIngresos = false;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final res = await _vehiculosRepo.listar();
      if (mounted) {
        setState(() {
          _vehiculos = res['data'] as List;
          if (_vehiculos.isNotEmpty) {
            _vehiculoSeleccionadoId = _vehiculos.first['id'];
            _cargarIngresos();
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

  Future<void> _cargarIngresos() async {
    if (_vehiculoSeleccionadoId == null) return;
    setState(() => _cargandoIngresos = true);
    try {
      final res = await _ingresosRepo.listar(vehiculoId: _vehiculoSeleccionadoId!);
      if (mounted) {
        setState(() {
          _ingresos = (res['data'] as List)
              .map((json) => Ingreso.fromJson(json))
              .toList();
          _cargandoIngresos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar ingresos: $e');
        setState(() => _cargandoIngresos = false);
      }
    }
  }

  void _mostrarFormularioNuevo() {
    if (_vehiculoSeleccionadoId == null) {
      showError(context, 'Selecciona un vehículo primero');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final montoCtrl = TextEditingController();
    final conceptoCtrl = TextEditingController();

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
                  'Registrar Ingreso',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: conceptoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Concepto (¿De qué fue la ganancia?)',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (v) => v!.isEmpty ? 'Ingresa el concepto' : null,
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await _ingresosRepo.registrar(
                          vehiculoId: _vehiculoSeleccionadoId!,
                          monto: double.parse(montoCtrl.text),
                          concepto: conceptoCtrl.text,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          showSuccess(context, 'Ingreso registrado correctamente');
                          _cargarIngresos();
                        }
                      } catch (e) {
                        showError(context, 'Error: $e');
                      }
                    }
                  },
                  child: const Text('GUARDAR INGRESO'),
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
        title: const Text('Mis Ingresos'),
      ),
      body: _cargandoVehiculos
          ? buildLoader()
          : Column(
              children: [
                // Selector de vehículo
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      value: _vehiculoSeleccionadoId,
                      decoration: const InputDecoration(labelText: 'Vehículo asociado'),
                      items: _vehiculos.map((v) {
                        return DropdownMenuItem<int>(
                          value: v['id'] as int,
                          child: Text('${v['marca']} ${v['modelo']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _vehiculoSeleccionadoId = val;
                          _cargarIngresos();
                        });
                      },
                    ),
                  ),
                ),

                // Lista de Ingresos
                Expanded(
                  child: _cargandoIngresos
                      ? buildLoader()
                      : _ingresos.isEmpty
                          ? buildErrorWidget(
                              'No se han registrado ingresos para este vehículo.',
                              _cargarIngresos,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _ingresos.length,
                              itemBuilder: (context, index) {
                                final ingreso = _ingresos[index];
                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: AppColors.success,
                                      child: Icon(Icons.trending_up, color: Colors.white),
                                    ),
                                    title: Text(
                                      ingreso.concepto,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(ingreso.fecha),
                                    trailing: Text(
                                      '+\$${ingreso.monto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.success,
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
        label: const Text('Nuevo Ingreso'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

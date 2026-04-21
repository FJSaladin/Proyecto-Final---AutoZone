import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/combustible_model.dart';

class CombustibleScreen extends StatefulWidget {
  const CombustibleScreen({super.key});

  @override
  State<CombustibleScreen> createState() => _CombustibleScreenState();
}

class _CombustibleScreenState extends State<CombustibleScreen> {
  final _vehiculosRepo = VehiculosRepository();
  final _combustibleRepo = CombustiblesRepository();

  List<dynamic> _vehiculos = [];
  int? _vehiculoSeleccionadoId;
  List<Combustible> _registros = [];
  bool _cargandoVehiculos = true;
  bool _cargandoRegistros = false;
  String _filtroTipo = 'todos'; // todos, combustible, aceite

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
            _cargarRegistros();
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

  Future<void> _cargarRegistros() async {
    if (_vehiculoSeleccionadoId == null) return;
    setState(() => _cargandoRegistros = true);
    try {
      final tipo = _filtroTipo == 'todos' ? null : _filtroTipo;
      final res = await _combustibleRepo.listar(
        vehiculoId: _vehiculoSeleccionadoId!,
        tipo: tipo,
      );
      if (mounted) {
        setState(() {
          _registros = (res['data'] as List)
              .map((json) => Combustible.fromJson(json))
              .toList();
          _cargandoRegistros = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al cargar registros: $e');
        setState(() => _cargandoRegistros = false);
      }
    }
  }

  void _mostrarFormularioNuevo() {
    if (_vehiculoSeleccionadoId == null) {
      showError(context, 'Debes seleccionar un vehículo primero');
      return;
    }

    final formKey = GlobalKey<FormState>();
    String tipo = 'combustible';
    final cantidadCtrl = TextEditingController();
    final unidadCtrl = TextEditingController(text: 'galones');
    final montoCtrl = TextEditingController();

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
                  'Nuevo Registro',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de carga'),
                  items: const [
                    DropdownMenuItem(value: 'combustible', child: Text('Combustible')),
                    DropdownMenuItem(value: 'aceite', child: Text('Aceite')),
                  ],
                  onChanged: (v) => tipo = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cantidadCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) => v!.isEmpty ? 'Ingresa la cantidad' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unidadCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unidad',
                    hintText: 'Ej: galones, litros, cuartos',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  validator: (v) => v!.isEmpty ? 'Ingresa la unidad' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto total (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) => v!.isEmpty ? 'Ingresa el monto' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await _combustibleRepo.registrar(
                          vehiculoId: _vehiculoSeleccionadoId!,
                          tipo: tipo,
                          cantidad: double.parse(cantidadCtrl.text),
                          unidad: unidadCtrl.text,
                          monto: double.parse(montoCtrl.text),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          showSuccess(context, 'Registro guardado con éxito');
                          _cargarRegistros();
                        }
                      } catch (e) {
                        showError(context, 'Error al guardar: $e');
                      }
                    }
                  },
                  child: const Text('GUARDAR REGISTRO'),
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
        title: const Text('Combustible y Aceite'),
      ),
      body: _cargandoVehiculos
          ? buildLoader()
          : Column(
              children: [
                // Selector de vehículo con estilo de tarjeta
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<int>(
                        value: _vehiculoSeleccionadoId,
                        decoration: const InputDecoration(
                          labelText: 'Vehículo',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        items: _vehiculos.map((v) {
                          return DropdownMenuItem<int>(
                            value: v['id'] as int,
                            child: Text(
                              '${v['marca']} ${v['modelo']} (${v['placa']})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _vehiculoSeleccionadoId = val;
                            _cargarRegistros();
                          });
                        },
                      ),
                    ),
                  ),
                ),

                // Filtros de tipo (Chips)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'todos'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Combustible', 'combustible'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Aceite', 'aceite'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Lista de registros
                Expanded(
                  child: _cargandoRegistros
                      ? buildLoader()
                      : _registros.isEmpty
                          ? buildErrorWidget(
                              'No hay registros para este vehículo.',
                              _cargarRegistros,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _registros.length,
                              itemBuilder: (context, index) {
                                final reg = _registros[index];
                                final esCombustible = reg.tipo == 'combustible';

                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: esCombustible
                                          ? AppColors.primary.withOpacity(0.1)
                                          : AppColors.info.withOpacity(0.1),
                                      child: Icon(
                                        esCombustible
                                            ? Icons.local_gas_station
                                            : Icons.oil_barrel,
                                        color: esCombustible
                                            ? AppColors.primary
                                            : AppColors.info,
                                      ),
                                    ),
                                    title: Text(
                                      '${reg.cantidad} ${reg.unidad}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(reg.fecha),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${reg.monto.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          reg.tipo.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: esCombustible
                                                ? AppColors.primary
                                                : AppColors.info,
                                          ),
                                        ),
                                      ],
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
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filtroTipo == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) {
          setState(() {
            _filtroTipo = value;
            _cargarRegistros();
          });
        }
      },
    );
  }
}

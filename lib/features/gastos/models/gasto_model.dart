class CategoriaGasto {
  final int id;
  final String nombre;

  CategoriaGasto({required this.id, required this.nombre});

  factory CategoriaGasto.fromJson(Map<String, dynamic> json) {
    return CategoriaGasto(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] as String,
    );
  }
}

class Gasto {
  final int id;
  final int vehiculoId;
  final int categoriaId;
  final String categoriaNombre;
  final double monto;
  final String? descripcion;
  final String fecha;

  Gasto({
    required this.id,
    required this.vehiculoId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.monto,
    this.descripcion,
    required this.fecha,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    // Solución al error de casteo - Hecho por Sebastian Florentino
    return Gasto(
      id: int.tryParse(json['id'].toString()) ?? 0,
      vehiculoId: int.tryParse(json['vehiculo_id'].toString()) ?? 0,
      categoriaId: int.tryParse(json['categoria_id'].toString()) ?? 0,
      categoriaNombre: json['categoriaNombre'] as String? ?? 'Sin categoría',
      monto: double.tryParse(json['monto'].toString()) ?? 0.0,
      descripcion: json['descripcion'] as String?,
      fecha: json['fecha'] as String? ?? '',
    );
  }
}

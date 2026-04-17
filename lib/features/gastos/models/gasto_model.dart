class CategoriaGasto {
  final int id;
  final String nombre;

  CategoriaGasto({required this.id, required this.nombre});

  factory CategoriaGasto.fromJson(Map<String, dynamic> json) {
    return CategoriaGasto(
      id: json['id'] as int,
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
    return Gasto(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      categoriaId: json['categoria_id'] as int,
      categoriaNombre: json['categoriaNombre'] as String? ?? 'Sin categoría',
      monto: (json['monto'] as num).toDouble(),
      descripcion: json['descripcion'] as String?,
      fecha: json['fecha'] as String,
    );
  }
}

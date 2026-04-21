class Combustible {
  final int id;
  final int vehiculoId;
  final String tipo;
  final double cantidad;
  final String unidad;
  final double monto;
  final String fecha;

  Combustible({
    required this.id,
    required this.vehiculoId,
    required this.tipo,
    required this.cantidad,
    required this.unidad,
    required this.monto,
    required this.fecha,
  });

  factory Combustible.fromJson(Map<String, dynamic> json) {
    // Solución al error de casteo - Hecho por Sebastian Florentino
    return Combustible(
      id: int.tryParse(json['id'].toString()) ?? 0,
      vehiculoId: int.tryParse(json['vehiculo_id'].toString()) ?? 0,
      tipo: json['tipo'] as String? ?? '',
      cantidad: double.tryParse(json['cantidad'].toString()) ?? 0.0,
      unidad: json['unidad'] as String? ?? '',
      monto: double.tryParse(json['monto'].toString()) ?? 0.0,
      fecha: json['fecha'] as String? ?? '',
    );
  }
}

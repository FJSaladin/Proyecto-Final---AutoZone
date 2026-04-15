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
    return Combustible(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      tipo: json['tipo'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      unidad: json['unidad'] as String,
      monto: (json['monto'] as num).toDouble(),
      fecha: json['fecha'] as String,
    );
  }
}

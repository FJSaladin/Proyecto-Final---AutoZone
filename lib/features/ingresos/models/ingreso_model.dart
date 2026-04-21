class Ingreso {
  final int id;
  final int vehiculoId;
  final double monto;
  final String concepto;
  final String fecha;

  Ingreso({
    required this.id,
    required this.vehiculoId,
    required this.monto,
    required this.concepto,
    required this.fecha,
  });

  factory Ingreso.fromJson(Map<String, dynamic> json) {
    // Solución al error de casteo - Hecho por Sebastian Florentino
    return Ingreso(
      id: int.tryParse(json['id'].toString()) ?? 0,
      vehiculoId: int.tryParse(json['vehiculo_id'].toString()) ?? 0,
      monto: double.tryParse(json['monto'].toString()) ?? 0.0,
      concepto: json['concepto'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
    );
  }
}

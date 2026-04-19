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
    return Ingreso(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      monto: (json['monto'] as num).toDouble(),
      concepto: json['concepto'] as String,
      fecha: json['fecha'] as String,
    );
  }
}

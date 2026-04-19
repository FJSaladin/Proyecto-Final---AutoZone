class Tema {
  final int id;
  final String titulo;
  final String descripcion;
  final String fecha;
  final String vehiculo;
  final String vehiculoFoto;
  final String autor;
  final int totalRespuestas;
  final List<Respuesta>? respuestas;

  Tema({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.vehiculo,
    required this.vehiculoFoto,
    required this.autor,
    required this.totalRespuestas,
    this.respuestas,
  });

  factory Tema.fromJson(Map<String, dynamic> json) {
    return Tema(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      fecha: json['fecha'] as String,
      vehiculo: json['vehiculo'] as String,
      vehiculoFoto: json['vehiculoFoto'] as String,
      autor: json['autor'] as String? ?? 'Anónimo',
      totalRespuestas: json['totalRespuestas'] as int? ?? 0,
      respuestas: json['respuestas'] != null
          ? (json['respuestas'] as List)
              .map((r) => Respuesta.fromJson(r))
              .toList()
          : null,
    );
  }
}

class Respuesta {
  final int id;
  final String contenido;
  final String fecha;
  final String autor;

  Respuesta({
    required this.id,
    required this.contenido,
    required this.fecha,
    required this.autor,
  });

  factory Respuesta.fromJson(Map<String, dynamic> json) {
    return Respuesta(
      id: json['id'] as int,
      contenido: json['contenido'] as String,
      fecha: json['fecha'] as String,
      autor: json['autor'] as String,
    );
  }
}

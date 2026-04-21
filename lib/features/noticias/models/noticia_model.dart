class Noticia {
  final int id;
  final String titulo;
  final String resumen;
  final String imagenUrl;
  final String fecha;
  final String fuente;
  final String link;
  final String? contenido; // HTML completo, solo viene en el detalle

  Noticia({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.imagenUrl,
    required this.fecha,
    required this.fuente,
    required this.link,
    this.contenido,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    return Noticia(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      resumen: json['resumen'] as String? ?? '',
      imagenUrl: json['imagenUrl'] as String,
      fecha: json['fecha'] as String,
      fuente: json['fuente'] as String? ?? 'Desconocida',
      link: json['link'] as String,
      contenido: json['contenido'] as String?,
    );
  }
}

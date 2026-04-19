class Video {
  final int id;
  final String youtubeId;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String url;
  final String thumbnail;

  Video({
    required this.id,
    required this.youtubeId,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.url,
    required this.thumbnail,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as int,
      youtubeId: json['youtubeId'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'General',
      url: json['url'] as String,
      thumbnail: json['thumbnail'] as String,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


// ─────────────────────────────────────────────────────────────
//  Modelo Contacto — flexible, cada integrante tiene los suyos
// ─────────────────────────────────────────────────────────────

class Contacto {
  final IconData icono;
  final String   etiqueta;
  final String   valor;
  final Color    color;
  final String   url;

  const Contacto({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.url,
  });
}

// ─────────────────────────────────────────────────────────────
//  Modelo Integrante
// ─────────────────────────────────────────────────────────────

class _Integrante {
  final String         nombre;
  final String         apellido;
  final String         matricula;
  final List<Contacto> contactos;
  final String?        fotoAsset; // 'assets/fotos/fausto.jpg'

  const _Integrante({
    required this.nombre,
    required this.apellido,
    required this.matricula,
    required this.contactos,
    this.fotoAsset,
  });

  String get nombreCompleto => '$nombre $apellido';
  String get iniciales =>
      '${nombre[0].toUpperCase()}${apellido[0].toUpperCase()}';
}

// ─────────────────────────────────────────────────────────────
//  DATOS — edita aquí los 3 integrantes
//  Cada uno puede tener distintos contactos en cualquier orden
// ─────────────────────────────────────────────────────────────

const _integrantes = [
  _Integrante(
    nombre:    'Fausto Jose',
    apellido:  'Arredondo Saladin',
    matricula: '20231004',
    // fotoAsset: 'assets/fotos/fausto.jpg',
    contactos: [
      Contacto(
        icono: FontAwesomeIcons.whatsapp,
        etiqueta: 'WhatsApp',
        valor: '+18295796520',
        color: AppColors.success,
        url: 'https://wa.me/18295796520', // formato oficial de WhatsApp
      ),

      Contacto(
        icono:    FontAwesomeIcons.github,
        etiqueta: 'Github',
        valor:    'github.com/FJSaladin',
        color:    Color.fromARGB(255, 55, 67, 73),
        url:      'https://github.com/FJSaladin',
      ),
      Contacto(
        icono:    Icons.email_outlined,
        etiqueta: 'Correo',
        valor:    '20231004@itla.edu.do',
        color:    AppColors.secondary,
        url:      'mailto:20231004@itla.edu.do',
      ),
    ],
  ),

  _Integrante(
    nombre:    'Sebastian',       
    apellido:  'Florentino',
    matricula: '20211102',
    contactos: [
      Contacto(
        icono: FontAwesomeIcons.whatsapp,
        etiqueta: 'WhatsApp',
        valor: '+18295796520',
        color: AppColors.success,
        url: 'https://wa.me/18295796520', // formato oficial de WhatsApp
      ),

      Contacto(
        icono:    FontAwesomeIcons.github,
        etiqueta: 'Github',
        valor:    'github.com/SebastianFlorentino',
        color:    Color.fromARGB(255, 55, 67, 73),
        url:      'https://github.com/SebastianFlorentino',
      ),
      Contacto(
        icono:    Icons.email_outlined,
        etiqueta: 'Correo',
        valor:    '20211102@itla.edu.do',
        color:    AppColors.secondary,
        url:      'mailto:20211102@itla.edu.do',
      ),
    ],
  ),

  _Integrante(
    nombre:    'Smerling',       
    apellido:  'Varela',
    matricula: '20163668',
    contactos: [
      Contacto(
        icono: FontAwesomeIcons.whatsapp,
        etiqueta: 'WhatsApp',
        valor: '+18295796520',
        color: AppColors.success,
        url: 'https://wa.me/18295796520', // formato oficial de WhatsApp
      ),

      Contacto(
        icono:    FontAwesomeIcons.github,
        etiqueta: 'Github',
        valor:    'github.com/SmerlingVarela',
        color:    Color.fromARGB(255, 55, 67, 73),
        url:      'https://github.com/SmerlingVarela',
      ),
      Contacto(
        icono:    Icons.email_outlined,
        etiqueta: 'Correo',
        valor:    '20163668@itla.edu.do',
        color:    AppColors.secondary,
        url:      'mailto:20163668@itla.edu.do',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
//  AcercaScreen
// ─────────────────────────────────────────────────────────────

class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  Future<void> _lanzar(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) showError(context, 'No se pudo abrir el enlace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca De')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCabeceraProyecto(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Equipo de desarrollo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _integrantes.length,
              (i) => _buildCardIntegrante(context, _integrantes[i], i + 1),
            ),
            const SizedBox(height: 24),
            _buildInfoProyecto(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Cabecera ──────────────────────────────────────────────

  Widget _buildCabeceraProyecto() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AutoZone ITLA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gestión de Vehículos',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Proyecto Final — Aplicaciones Móviles — ITLA 2026',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Card integrante ───────────────────────────────────────

  Widget _buildCardIntegrante(
    BuildContext context,
    _Integrante integrante,
    int numero,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Avatar + datos ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: integrante.fotoAsset != null
                        ? Image.asset(
                            integrante.fotoAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatar(integrante),
                          )
                        : _buildAvatar(integrante),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        integrante.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            integrante.matricula,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          // ── Contactos dinámicos con Wrap ─────────────────
          // Wrap pone hasta 3 por fila y baja a nueva línea
          // si hay más. Cada integrante puede tener distintos.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: integrante.contactos.map((c) {
                final ancho =
                    (MediaQuery.of(context).size.width - 64) / 3;
                return SizedBox(
                  width: ancho,
                  child: _buildBotonContacto(
                    contacto: c,
                    onTap: () => _lanzar(context, c.url),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar con iniciales ──────────────────────────────────

  Widget _buildAvatar(_Integrante integrante) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          integrante.iniciales,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Botón de contacto ─────────────────────────────────────

  Widget _buildBotonContacto({
    required Contacto contacto,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: contacto.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: contacto.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(contacto.icono, color: contacto.color, size: 22),
            const SizedBox(height: 4),
            Text(
              contacto.etiqueta,
              style: TextStyle(
                fontSize: 11,
                color: contacto.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              contacto.valor,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info del proyecto ─────────────────────────────────────

  Widget _buildInfoProyecto() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            const Icon(Icons.school_outlined,
                size: 32, color: AppColors.secondary),
            const SizedBox(height: 10),
            const Text(
              'ITLA — Instituto Tecnológico de Las Américas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'C1-2026\nDesarrollo de Aplicaciones Móviles',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoFila(
                Icons.code_rounded, 'Tecnología', 'Flutter / Dart'),
            const SizedBox(height: 6),
            _buildInfoFila(
                Icons.cloud_outlined, 'API', 'taller-itla.ia3x.com'),
            const SizedBox(height: 6),
            _buildInfoFila(
                Icons.phone_android_rounded, 'Plataforma', 'Android'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoFila(IconData icono, String etiqueta, String valor) {
    return Row(
      children: [
        Icon(icono, size: 16, color: AppColors.secondary),
        const SizedBox(width: 10),
        Text(
          '$etiqueta: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
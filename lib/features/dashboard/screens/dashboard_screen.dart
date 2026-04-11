import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../perfil/screens/perfil_screen.dart';
// ─────────────────────────────────────────────────────────────
//  Datos del slider
// ─────────────────────────────────────────────────────────────

class _SliderItem {
  final String imagen;
  final String titulo;
  final String subtitulo;

  const _SliderItem({
    required this.imagen,
    required this.titulo,
    required this.subtitulo,
  });
}

const _slides = [
  _SliderItem(
    imagen: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800',
    titulo: '¿Cuándo fue tu último cambio de aceite?',
    subtitulo: 'Mantén tu motor en óptimas condiciones',
  ),
  _SliderItem(
    imagen: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
    titulo: 'Revisa tus gomas regularmente',
    subtitulo: 'Una goma en mal estado puede ser peligrosa',
  ),
  _SliderItem(
    imagen: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
    titulo: 'Controla tus gastos vehiculares',
    subtitulo: 'Registra cada gasto y mantén el balance',
  ),
  _SliderItem(
    imagen: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800',
    titulo: 'Tu vehículo, tu inversión',
    subtitulo: 'Cuídalo y durará muchos años más',
  ),
];

// ─────────────────────────────────────────────────────────────
//  Accesos rápidos
// ─────────────────────────────────────────────────────────────

class _AccesoItem {
  final IconData icono;
  final String   etiqueta;
  final Color    color;
  final bool     requiereLogin;

  const _AccesoItem({
    required this.icono,
    required this.etiqueta,
    required this.color,
    this.requiereLogin = false,
  });
}

const _accesosPublicos = [
  _AccesoItem(
    icono: Icons.newspaper_rounded,
    etiqueta: 'Noticias',
    color: Color(0xFF1565C0),
  ),
  _AccesoItem(
    icono: Icons.forum_rounded,
    etiqueta: 'Foro',
    color: Color(0xFF6A1B9A),
  ),
  _AccesoItem(
    icono: Icons.directions_car_rounded,
    etiqueta: 'Catálogo',
    color: Color(0xFF2E7D32),
  ),
  _AccesoItem(
    icono: Icons.play_circle_rounded,
    etiqueta: 'Videos',
    color: Color(0xFFC62828),
  ),
];

const _accesosPrivados = [
  _AccesoItem(
    icono: Icons.garage_rounded,
    etiqueta: 'Mis Vehículos',
    color: Color(0xFFE65100),
    requiereLogin: true,
  ),
  _AccesoItem(
    icono: Icons.build_rounded,
    etiqueta: 'Mantenimiento',
    color: Color(0xFF00695C),
    requiereLogin: true,
  ),
  _AccesoItem(
    icono: Icons.local_gas_station_rounded,
    etiqueta: 'Combustible',
    color: Color(0xFFF57F17),
    requiereLogin: true,
  ),
  _AccesoItem(
    icono: Icons.account_balance_wallet_rounded,
    etiqueta: 'Gastos',
    color: Color(0xFF4527A0),
    requiereLogin: true,
  ),
];

// ─────────────────────────────────────────────────────────────
//  DashboardScreen
// ─────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _iniciarAutoPlay();
  }

  void _iniciarAutoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final siguiente = (_paginaActual + 1) % _slides.length;
      _pageController.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _iniciarAutoPlay();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.directions_car, size: 22),
             SizedBox(width: 8),
             Text('AutoZone ITLA'),
          ],
        ),
        actions: [
          if (auth.estaLogueado)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PerfilScreen()),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: auth.usuario?.fotoUrl != null
                      ? NetworkImage(auth.usuario!.fotoUrl!)
                      : null,
                  child: auth.usuario?.fotoUrl == null
                      ? Text(
                          auth.usuario?.nombre[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login, color: Colors.white, size: 18),
              label: const Text(
                'Iniciar sesión',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),

      // ── Drawer ──────────────────────────────────────────────
      drawer: _buildDrawer(auth),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Slider ────────────────────────────────────────
            _buildSlider(),

            const SizedBox(height: 24),

            // ── Saludo si está logueado ────────────────────────
            if (auth.estaLogueado) _buildSaludo(auth),

            // ── Accesos rápidos públicos ───────────────────────
            _buildSeccion('Explorar', _accesosPublicos),

            const SizedBox(height: 8),

            // ── Accesos privados (si está logueado) ───────────
            if (auth.estaLogueado)
              _buildSeccion('Mi vehículo', _accesosPrivados)
            else
              _buildBannerLogin(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Slider de imágenes ──────────────────────────────────────

  Widget _buildSlider() {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemBuilder: (_, i) => _buildSlide(_slides[i]),
          ),
          // Indicadores
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  _paginaActual == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _paginaActual == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_SliderItem slide) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          slide.imagen,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primary,
            child: const Icon(Icons.directions_car,
                size: 64, color: Colors.white),
          ),
        ),
        // Gradiente oscuro abajo
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        // Texto
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slide.subtitulo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Saludo ──────────────────────────────────────────────────

  Widget _buildSaludo(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.waving_hand_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${auth.usuario?.nombre}!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'Bienvenido a AutoZone ITLA',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sección de accesos rápidos ──────────────────────────────

  Widget _buildSeccion(String titulo, List<_AccesoItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildAcceso(items[i]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAcceso(_AccesoItem item) {
    return GestureDetector(
      onTap: () {
        // TODO: navegación a cada módulo
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.color.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(item.icono, color: item.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            item.etiqueta,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner para usuarios sin login ──────────────────────────

  Widget _buildBannerLogin() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_open_rounded,
                size: 36, color: AppColors.secondary),
            const SizedBox(height: 10),
            const Text(
              'Inicia sesión para acceder a\ntus vehículos y más funciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(160, 44),
              ),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer ──────────────────────────────────────────────────

  Widget _buildDrawer(AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          // Cabecera
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              backgroundImage: auth.usuario?.fotoUrl != null
                  ? NetworkImage(auth.usuario!.fotoUrl!)
                  : null,
              child: auth.usuario?.fotoUrl == null
                  ? Icon(
                      auth.estaLogueado
                          ? Icons.person
                          : Icons.person_outline,
                      color: Colors.white,
                      size: 32,
                    )
                  : null,
            ),
            accountName: Text(
              auth.estaLogueado
                  ? auth.usuario!.nombreCompleto
                  : 'Invitado',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            accountEmail: Text(
              auth.estaLogueado
                  ? auth.usuario!.correo
                  : 'Inicia sesión para más opciones',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Opciones siempre visibles
          _drawerItem(Icons.home_rounded, 'Inicio', onTap: () {
            Navigator.pop(context);
          }),
          _drawerItem(Icons.newspaper_rounded, 'Noticias'),
          _drawerItem(Icons.forum_rounded, 'Foro'),
          _drawerItem(Icons.directions_car_rounded, 'Catálogo'),
          _drawerItem(Icons.play_circle_rounded, 'Videos'),

          // Opciones con login
          if (auth.estaLogueado) ...[
            const Divider(),
            _drawerItem(Icons.garage_rounded, 'Mis Vehículos'),
            _drawerItem(Icons.build_rounded, 'Mantenimientos'),
            _drawerItem(Icons.local_gas_station_rounded, 'Combustible'),
            _drawerItem(Icons.account_balance_wallet_rounded, 'Gastos'),
            _drawerItem(Icons.forum_outlined, 'Mi Foro'),
            _drawerItem(Icons.person_outline, 'Mi Perfil', onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              );
            }),
          ],

          const Divider(),
          _drawerItem(Icons.info_outline_rounded, 'Acerca De'),

          const Spacer(),

          // Login / Logout
          if (auth.estaLogueado)
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login, color: AppColors.primary),
              title: const Text(
                'Iniciar sesión',
                style: TextStyle(color: AppColors.primary),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icono, String titulo,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icono, color: AppColors.textSecondary, size: 22),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      onTap: onTap ?? () => Navigator.pop(context),
      dense: true,
    );
  }
}
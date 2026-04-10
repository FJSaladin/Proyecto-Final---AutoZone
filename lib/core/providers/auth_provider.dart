import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
//  Modelo de usuario en sesión
// ─────────────────────────────────────────────────────────────

class UsuarioSesion {
  final int    id;
  final String nombre;
  final String apellido;
  final String correo;
  final String matricula;
  final String rol;
  final String grupo;
  final String? fotoUrl;

  const UsuarioSesion({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.matricula,
    required this.rol,
    required this.grupo,
    this.fotoUrl,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory UsuarioSesion.fromJson(Map<String, dynamic> json) {
    return UsuarioSesion(
      id:        json['id']        as int,
      nombre:    json['nombre']    as String,
      apellido:  json['apellido']  as String,
      correo:    json['correo']    as String,
      matricula: json['matricula'] as String? ?? '',
      rol:       json['rol']       as String? ?? '',
      grupo:     json['grupo']     as String? ?? '',
      fotoUrl:   json['fotoUrl']   as String?,
    );
  }

  UsuarioSesion copyWith({String? fotoUrl}) {
    return UsuarioSesion(
      id:        id,
      nombre:    nombre,
      apellido:  apellido,
      correo:    correo,
      matricula: matricula,
      rol:       rol,
      grupo:     grupo,
      fotoUrl:   fotoUrl ?? this.fotoUrl,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AuthProvider
// ─────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  final _auth   = AuthRepository();
  final _perfil = PerfilRepository();

  UsuarioSesion? _usuario;
  bool _cargando    = false;
  bool _inicializado = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────

  UsuarioSesion? get usuario     => _usuario;
  bool get estaLogueado          => _usuario != null;
  bool get cargando              => _cargando;
  bool get inicializado          => _inicializado;
  String? get error              => _error;

  // ── Inicialización — llamar al arrancar la app ─────────────
  // Si hay token guardado, carga el perfil automáticamente
  // para no pedir login cada vez que se abre la app.

  Future<void> inicializar() async {
    if (_inicializado) return;
    _cargando = true;
    notifyListeners();

    try {
      final logueado = await _auth.isLoggedIn();
      if (logueado) {
        await _cargarPerfil();
      }
    } catch (_) {
      // Si falla (token expirado, sin internet), simplemente
      // arranca sin sesión. El usuario tendrá que iniciar sesión.
      _usuario = null;
    } finally {
      _cargando     = false;
      _inicializado = true;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────

  Future<bool> login(String matricula, String contrasena) async {
    _cargando = true;
    _error    = null;
    notifyListeners();

    try {
      final res  = await _auth.login(matricula, contrasena);
      final data = res['data'] as Map<String, dynamic>;

      // Construir usuario desde la respuesta del login
      _usuario = UsuarioSesion(
        id:       data['id']       as int,
        nombre:   data['nombre']   as String,
        apellido: data['apellido'] as String,
        correo:   data['correo']   as String,
        matricula: matricula,
        rol:      '',
        grupo:    '',
        fotoUrl:  data['fotoUrl']  as String?,
      );

      // Cargar perfil completo (tiene rol, grupo, matrícula)
      await _cargarPerfil();

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.logout();
    _usuario = null;
    _error   = null;
    notifyListeners();
  }

  // ── Actualizar foto de perfil ─────────────────────────────

  void actualizarFoto(String nuevaUrl) {
    if (_usuario == null) return;
    _usuario = _usuario!.copyWith(fotoUrl: nuevaUrl);
    notifyListeners();
  }

  // ── Recargar perfil desde la API ──────────────────────────

  Future<void> recargarPerfil() async {
    try {
      await _cargarPerfil();
    } catch (_) {}
  }

  // ── Privado: cargar perfil ────────────────────────────────

  Future<void> _cargarPerfil() async {
    final res  = await _perfil.getPerfil();
    final data = res['data'] as Map<String, dynamic>;
    _usuario   = UsuarioSesion.fromJson(data);
    notifyListeners();
  }
}
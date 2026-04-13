import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
//  Constantes
// ─────────────────────────────────────────────────────────────

const String _baseUrl  = 'https://taller-itla.ia3x.com/api';
const String _keyToken   = 'auth_token';
const String _keyRefresh = 'refresh_token';

// ─────────────────────────────────────────────────────────────
//  Excepción personalizada
// ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────
//  ApiService  (Singleton)
// ─────────────────────────────────────────────────────────────

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ── Tokens ───────────────────────────────────────────────

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefresh);
  }

  Future<void> saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRefresh, refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefresh);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Helpers privados ──────────────────────────────────────

  Uri _uri(String path, [Map<String, dynamic>? params]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (params == null) return uri;
    return uri.replace(
      queryParameters:
          params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('No hay sesión activa. Inicia sesión.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _parse(http.Response res) {
    late Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Respuesta inesperada del servidor',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode >= 400) {
      final msg = body['message'] as String? ?? 'Error ${res.statusCode}';
      throw ApiException(msg, statusCode: res.statusCode);
    }
    return body;
  }

  Future<bool> _tryRefresh() async {
    final rt = await getRefreshToken();
    if (rt == null) return false;
    try {
      final res = await http.post(
        _uri('/auth/refresh'),
        body: {'datax': jsonEncode({'refreshToken': rt})},
      );
      if (res.statusCode == 200) {
        final data =
            (jsonDecode(res.body) as Map)['data'] as Map<String, dynamic>;
        await saveTokens(
          data['token'] as String,
          data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _attachFiles(
    http.MultipartRequest req,
    Map<String, File>? files,
    Map<String, List<File>>? multi,
  ) async {
    if (files != null) {
      for (final e in files.entries) {
        req.files
            .add(await http.MultipartFile.fromPath(e.key, e.value.path));
      }
    }
    if (multi != null) {
      for (final e in multi.entries) {
        for (final f in e.value) {
          req.files
              .add(await http.MultipartFile.fromPath(e.key, f.path));
        }
      }
    }
  }

  // ── GET público ───────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    try {
      return _parse(await http.get(_uri(path, params)));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet');
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  // ── GET autenticado ───────────────────────────────────────

  Future<Map<String, dynamic>> getAuth(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    try {
      var h = await _authHeaders();
      var res = await http.get(_uri(path, params), headers: h);
      if (res.statusCode == 401) {
        if (!await _tryRefresh()) {
          throw const ApiException(
              'Sesión expirada. Inicia sesión nuevamente.',
              statusCode: 401);
        }
        h   = await _authHeaders();
        res = await http.get(_uri(path, params), headers: h);
      }
      return _parse(res);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet');
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  // ── POST form-encoded público ─────────────────────────────

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      return _parse(await http.post(
        _uri(path),
        body: {'datax': jsonEncode(data)},
      ));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet');
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  // ── POST form-encoded autenticado ─────────────────────────

  Future<Map<String, dynamic>> postAuth(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      var h = await _authHeaders();
      var res = await http.post(
        _uri(path),
        headers: h,
        body: {'datax': jsonEncode(data)},
      );
      if (res.statusCode == 401) {
        if (!await _tryRefresh()) {
          throw const ApiException(
              'Sesión expirada. Inicia sesión nuevamente.',
              statusCode: 401);
        }
        h   = await _authHeaders();
        res = await http.post(
          _uri(path),
          headers: h,
          body: {'datax': jsonEncode(data)},
        );
      }
      return _parse(res);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet');
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  // ── POST multipart público ────────────────────────────────

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> data,
    Map<String, File>?        files,
    Map<String, List<File>>?  multiFiles,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _uri(path));
      req.fields['datax'] = jsonEncode(data);
      await _attachFiles(req, files, multiFiles);
      return _parse(await http.Response.fromStream(await req.send()));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet');
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  // ── POST multipart autenticado ────────────────────────────

  Future<Map<String, dynamic>> postMultipartAuth(
    String path, {
    required Map<String, dynamic> data,
    Map<String, File>?        files,
    Map<String, List<File>>?  multiFiles,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('No hay sesión activa. Inicia sesión.');
      }
      final req = http.MultipartRequest('POST', _uri(path));
      req.headers['Authorization'] = 'Bearer $token';
      req.fields['datax'] = jsonEncode(data);
      await _attachFiles(req, files, multiFiles);
      return _parse(await http.Response.fromStream(await req.send()));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Sin conexión a internet');
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }
}

// ═════════════════════════════════════════════════════════════
//  REPOSITORIOS
// ═════════════════════════════════════════════════════════════

// ── Auth  (Integrante 1) ──────────────────────────────────────

class AuthRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> registro(String matricula) =>
      _api.post('/auth/registro', {'matricula': matricula});

  Future<Map<String, dynamic>> activar(
      String token, String contrasena) async {
    final res = await _api.post('/auth/activar', {
      'token': token,
      'contrasena': contrasena,
    });
    final d = res['data'] as Map<String, dynamic>;
    await _api.saveTokens(d['token'] as String, d['refreshToken'] as String);
    return res;
  }

  Future<Map<String, dynamic>> login(
      String matricula, String contrasena) async {
    final res = await _api.post('/auth/login', {
      'matricula': matricula,
      'contrasena': contrasena,
    });
    final d = res['data'] as Map<String, dynamic>;
    await _api.saveTokens(d['token'] as String, d['refreshToken'] as String);
    return res;
  }

  Future<Map<String, dynamic>> olvidarClave(String matricula) =>
      _api.post('/auth/olvidar', {'matricula': matricula});

  Future<Map<String, dynamic>> cambiarClave(String actual, String nueva) =>
      _api.postAuth('/auth/cambiar-clave', {
        'actual': actual,
        'nueva': nueva,
      });

  Future<void> logout() => _api.clearTokens();
  Future<bool> isLoggedIn() => _api.isLoggedIn();
}

// ── Perfil  (Integrante 1) ────────────────────────────────────

class PerfilRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getPerfil() => _api.getAuth('/perfil');

  Future<Map<String, dynamic>> subirFoto(File foto) =>
      _api.postMultipartAuth('/perfil/foto', data: {}, files: {'foto': foto});
}

// ── Vehículos  (Integrante 2) ─────────────────────────────────

class VehiculosRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> listar({
    String? marca, String? modelo, int page = 1, int limit = 20,
  }) => _api.getAuth('/vehiculos', params: {
    if (marca != null) 'marca': marca,
    if (modelo != null) 'modelo': modelo,
    'page': page, 'limit': limit,
  });

  Future<Map<String, dynamic>> detalle(int id) =>
      _api.getAuth('/vehiculos/detalle', params: {'id': id});

  Future<Map<String, dynamic>> registrar({
    required String placa, required String chasis,
    required String marca,  required String modelo,
    required int anio,      required int cantidadRuedas,
    File? foto,
  }) => _api.postMultipartAuth('/vehiculos', data: {
    'placa': placa, 'chasis': chasis, 'marca': marca,
    'modelo': modelo, 'anio': anio, 'cantidadRuedas': cantidadRuedas,
  }, files: foto != null ? {'foto': foto} : null);

  Future<Map<String, dynamic>> editar(int id, Map<String, dynamic> campos) =>
      _api.postAuth('/vehiculos/editar', {'id': id, ...campos});

  Future<Map<String, dynamic>> subirFoto(int id, File foto) =>
      _api.postMultipartAuth('/vehiculos/foto',
          data: {'id': id}, files: {'foto': foto});
}

// ── Mantenimientos  (Integrante 2) ────────────────────────────

class MantenimientosRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> listar({
    required int vehiculoId, String? tipo, int page = 1, int limit = 20,
  }) => _api.getAuth('/mantenimientos', params: {
    'vehiculo_id': vehiculoId,
    if (tipo != null) 'tipo': tipo,
    'page': page, 'limit': limit,
  });

  Future<Map<String, dynamic>> detalle(int id) =>
      _api.getAuth('/mantenimientos/detalle', params: {'id': id});

  Future<Map<String, dynamic>> registrar({
    required int vehiculoId, required String tipo,
    required double costo,   required String fecha,
    String? piezas, List<File>? fotos,
  }) => _api.postMultipartAuth('/mantenimientos', data: {
    'vehiculo_id': vehiculoId, 'tipo': tipo,
    'costo': costo, 'fecha': fecha,
    if (piezas != null) 'piezas': piezas,
  }, multiFiles: fotos != null ? {'fotos[]': fotos} : null);

  Future<Map<String, dynamic>> subirFotos(int id, List<File> fotos) =>
      _api.postMultipartAuth('/mantenimientos/fotos',
          data: {'mantenimiento_id': id},
          multiFiles: {'fotos[]': fotos});
}

// ── Gomas  (Integrante 2) ─────────────────────────────────────

class GomasRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getEstado(int vehiculoId) =>
      _api.getAuth('/gomas', params: {'vehiculo_id': vehiculoId});

  Future<Map<String, dynamic>> actualizarEstado(int gomaId, String estado) =>
      _api.postAuth('/gomas/actualizar',
          {'goma_id': gomaId, 'estado': estado});

  Future<Map<String, dynamic>> registrarPinchazo({
    required int gomaId, required String descripcion, required String fecha,
  }) => _api.postAuth('/gomas/pinchazos', {
    'goma_id': gomaId, 'descripcion': descripcion, 'fecha': fecha,
  });
}

// ── Combustibles  (Integrante 3) ──────────────────────────────

class CombustiblesRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> listar({
    required int vehiculoId, String? tipo, int page = 1, int limit = 20,
  }) => _api.getAuth('/combustibles', params: {
    'vehiculo_id': vehiculoId,
    if (tipo != null) 'tipo': tipo,
    'page': page, 'limit': limit,
  });

  Future<Map<String, dynamic>> registrar({
    required int vehiculoId, required String tipo,
    required double cantidad, required String unidad, required double monto,
  }) => _api.postAuth('/combustibles', {
    'vehiculo_id': vehiculoId, 'tipo': tipo,
    'cantidad': cantidad, 'unidad': unidad, 'monto': monto,
  });
}

// ── Gastos  (Integrante 3) ────────────────────────────────────

class GastosRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getCategorias() =>
      _api.getAuth('/gastos/categorias');

  Future<Map<String, dynamic>> listar({
    required int vehiculoId, int? categoriaId, int page = 1, int limit = 20,
  }) => _api.getAuth('/gastos', params: {
    'vehiculo_id': vehiculoId,
    if (categoriaId != null) 'categoria_id': categoriaId,
    'page': page, 'limit': limit,
  });

  Future<Map<String, dynamic>> registrar({
    required int vehiculoId, required int categoriaId,
    required double monto,   required String descripcion,
  }) => _api.postAuth('/gastos', {
    'vehiculo_id': vehiculoId, 'categoriaId': categoriaId,
    'monto': monto, 'descripcion': descripcion,
  });
}

// ── Ingresos  (Integrante 3) ──────────────────────────────────

class IngresosRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> listar({
    required int vehiculoId, int page = 1, int limit = 20,
  }) => _api.getAuth('/ingresos', params: {
    'vehiculo_id': vehiculoId, 'page': page, 'limit': limit,
  });

  Future<Map<String, dynamic>> registrar({
    required int vehiculoId, required double monto, required String concepto,
  }) => _api.postAuth('/ingresos', {
    'vehiculo_id': vehiculoId, 'monto': monto, 'concepto': concepto,
  });
}

// ── Foro  (Integrante 3) ──────────────────────────────────────

class ForoRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getTemas({int page = 1, int limit = 20}) =>
      _api.get('/foro/temas', params: {'page': page, 'limit': limit});

  Future<Map<String, dynamic>> getDetalle(int id) =>
      _api.get('/foro/detalle', params: {'id': id});

  Future<Map<String, dynamic>> getMisTemas({int page = 1, int limit = 20}) =>
      _api.getAuth('/foro/mis-temas',
          params: {'page': page, 'limit': limit});

  Future<Map<String, dynamic>> crearTema({
    required int vehiculoId, required String titulo, required String descripcion,
  }) => _api.postAuth('/foro/crear', {
    'vehiculo_id': vehiculoId, 'titulo': titulo, 'descripcion': descripcion,
  });

  Future<Map<String, dynamic>> responder({
    required int temaId, required String contenido,
  }) => _api.postAuth('/foro/responder', {
    'tema_id': temaId, 'contenido': contenido,
  });
}

// ── Noticias  (Integrante 3) ──────────────────────────────────

class NoticiasRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getNoticias() => _api.get('/noticias');

  Future<Map<String, dynamic>> getDetalle(int id) =>
      _api.get('/noticias/detalle', params: {'id': id});
}

// ── Videos  (Integrante 3) ────────────────────────────────────

class VideosRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getVideos() => _api.get('/videos');
}

// ── Catálogo  (Integrante 2) ──────────────────────────────────

class CatalogoRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> listar({
    String? marca,   String? modelo,  int? anio,
    double? precioMin, double? precioMax, int page = 1, int limit = 20,
  }) => _api.getAuth('/catalogo', params: {
    if (marca != null) 'marca': marca,
    if (modelo != null) 'modelo': modelo,
    if (anio != null) 'anio': anio,
    if (precioMin != null) 'precioMin': precioMin,
    if (precioMax != null) 'precioMax': precioMax,
    'page': page, 'limit': limit,
  });

  Future<Map<String, dynamic>> detalle(int id) =>
      _api.getAuth('/catalogo/detalle', params: {'id': id});
}
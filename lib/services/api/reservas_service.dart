import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/reserva_api.dart';
import '../../models/api/reserva_actividad.dart';
import '../../config/api_config.dart';
import '../secure_storage_service.dart';
import 'huespedes_service.dart';

class ReservasService {
  static final ReservasService _instance = ReservasService._internal();
  factory ReservasService() => _instance;
  ReservasService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();
  final _huespedesService = HuespedesService();

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.reservasBaseUrl, // http://localhost:5141
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para agregar el token automáticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _storage.getAccessToken();
          if (accessToken != null) {
            final tokenType = await _storage.getTokenType() ?? 'Bearer';
            options.headers['Authorization'] = '$tokenType $accessToken';
          }
          return handler.next(options);
        },
      ),
    );

    // Interceptor para logging en modo debug
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }
  }

  Future<List<ReservaApi>> getMisReservas() async {
    try {
      final response = await _dio.get('/me');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }
      throw Exception('Error al obtener mis reservas');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/Reservas
  Future<List<ReservaApi>> getAll() async {
    try {
      final response = await _dio.get('/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }

      throw Exception('Error al obtener reservas');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Validar reserva por número de reserva y documento
  // 1. Busca la reserva por numeroReserva
  // 2. Obtiene el huespedId
  // 3. Busca el huésped
  // 4. Compara el documento
  Future<ReservaApi?> validarReserva(String numeroReserva, String documento) async {
    try {
      debugPrint('[ReservasService] Validando reserva: $numeroReserva, documento: $documento');
      
      // Paso 1: Obtener todas las reservas y buscar por número
      final response = await _dio.get('/');
      
      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> reservasData;
        
        if (response.data is List) {
          reservasData = response.data as List<dynamic>;
        } else if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          reservasData = map['\$values'] ?? map['data'] ?? map['items'] ?? [];
        } else {
          return null;
        }

        // Buscar reserva por número
        final reservaJson = reservasData.firstWhere(
          (r) => r['numeroReserva'] == numeroReserva,
          orElse: () => null,
        );

        if (reservaJson == null) {
          debugPrint('[ReservasService] Reserva no encontrada: $numeroReserva');
          return null;
        }

        // Verificar que la reserva esté confirmada o pendiente (aceptar varios estados)
        final estado = reservaJson['estado'] as String?;
        final estadoLower = estado?.toLowerCase() ?? '';
        if (estadoLower != 'confirmada' && 
            estadoLower != 'confirmado' && 
            estadoLower != 'pendiente' &&
            estadoLower != 'pagada') {
          debugPrint('[ReservasService] Reserva no válida para check-in. Estado: $estado');
          return null;
        }
        
        // Verificar que no haya hecho check-in previamente
        final checkInRealizado = reservaJson['checkInRealizado'];
        if (checkInRealizado != null) {
          debugPrint('[ReservasService] Ya se realizó el check-in anteriormente');
          // Devolver un código especial indicando que ya se hizo check-in
          throw Exception('CHECKIN_ALREADY_DONE');
        }

        // Paso 2: Obtener el huespedId de la reserva
        final huespedId = reservaJson['huespedId'];
        if (huespedId == null) {
          debugPrint('[ReservasService] Reserva sin huespedId');
          return null;
        }

        debugPrint('[ReservasService] HuespedId encontrado: $huespedId');

        // Paso 3: Buscar el huésped usando HuespedesService
        try {
          // Usar HuespedesService que ya tiene la URL correcta (usuariosBaseUrl: 5284)
          final huesped = await _huespedesService.getHuespedById(huespedId);
          
          if (huesped != null) {
            final documentoHuesped = huesped.numeroDocumento;
            
            debugPrint('[ReservasService] Documento del huésped: $documentoHuesped');
            debugPrint('[ReservasService] Documento ingresado: $documento');

            // Paso 4: Comparar documentos
            if (documentoHuesped != null && documentoHuesped == documento) {
              // Documentos coinciden - reserva válida
              return ReservaApi.fromJson(reservaJson);
            } else {
              debugPrint('[ReservasService] Documento no coincide');
              return null;
            }
          }
        } catch (e) {
          debugPrint('[ReservasService] Error al obtener huésped: $e');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('[ReservasService] Error validando reserva: $e');
      return null;
    }
  }

  Future<List<ReservaActividadApi>> getReservasActividadesByHuespedId(
    int huespedId,
  ) async {
    try {
      debugPrint(
        '[ReservasService] Obteniendo reservas actividades para huespedId: $huespedId',
      );
      debugPrint(
        '[ReservasService] URL: ${_dio.options.baseUrl}/ReservasActividades',
      );

      final response = await _dio.get('/ReservasActividades');

      debugPrint('[ReservasService] Status: ${response.statusCode}');
      debugPrint(
        '[ReservasService] Response type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> allReservas;

        if (response.data is List) {
          allReservas = response.data as List<dynamic>;
        } else if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          allReservas = map['\$values'] ?? map['data'] ?? map['items'] ?? [];
        } else {
          return [];
        }

        debugPrint(
          '[ReservasService] Total reservas actividades: ${allReservas.length}',
        );

        // Filtrar por huespedId
        final misReservas = allReservas
            .where((r) => r['huespedId'] == huespedId)
            .map(
              (json) =>
                  ReservaActividadApi.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        debugPrint(
          '[ReservasService] Reservas actividades del huesped $huespedId: ${misReservas.length}',
        );

        return misReservas;
      }

      return [];
    } on DioException catch (e) {
      debugPrint('[ReservasService] Error: ${e.message}');
      debugPrint('[ReservasService] Response: ${e.response?.data}');
      return [];
    }
  }

  // GET /api/Reservas/{id}
  Future<ReservaApi> getById(int id) async {
    try {
      final response = await _dio.get('/$id');

      if (response.statusCode == 200) {
        return ReservaApi.fromJson(response.data);
      }

      throw Exception('Error al obtener reserva');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/Reservas/huesped/{huespedId}
  Future<List<ReservaApi>> getByHuespedId(int huespedId) async {
    try {
      final response = await _dio.get('/huesped/$huespedId');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        
        // Si la respuesta contiene todos los registros, filtrar por huespedId en el cliente
        // Esto es un workaround para cuando el backend no filtra correctamente
        if (data.isNotEmpty && data.first is Map) {
          // Verificar si hay reservas con diferentes huespedId
          final hasMultipleHuespedIds = data.any((r) => 
            (r as Map<String, dynamic>)['huespedId'] != huespedId
          );
          
          if (hasMultipleHuespedIds) {
            debugPrint('[ReservasService] Filtrando reservas por huespedId en cliente: $huespedId');
            data = data.where((r) => 
              (r as Map<String, dynamic>)['huespedId'] == huespedId
            ).toList();
          }
        }
        
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }

      throw Exception('Error al obtener reservas del huésped');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Buscar reserva por número de reserva
  Future<ReservaApi?> buscarReservaPorNumero(String numeroReserva) async {
    try {
      final response = await _dio.get('/');
      
      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> reservasData;
        
        if (response.data is List) {
          reservasData = response.data as List<dynamic>;
        } else if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          reservasData = map['\$values'] ?? map['data'] ?? map['items'] ?? [];
        } else {
          return null;
        }

        // Buscar reserva por número
        final reservaJson = reservasData.firstWhere(
          (r) => r['numeroReserva'] == numeroReserva,
          orElse: () => null,
        );

        if (reservaJson == null) {
          return null;
        }

        return ReservaApi.fromJson(reservaJson as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('[ReservasService] Error buscando reserva por número: $e');
      return null;
    }
  }

  // PUT /api/Reservas/{id}
  // Marca el check-in como realizado en la base de datos
  Future<bool> realizarCheckIn(int reservaId) async {
    try {
      debugPrint('[ReservasService] Iniciando check-in para reserva ID: $reservaId');
      
      // 1. Obtener la reserva completa
      final getResponse = await _dio.get('/$reservaId');
      
      if (getResponse.statusCode != 200 || getResponse.data == null) {
        debugPrint('[ReservasService] Error: No se pudo obtener la reserva');
        return false;
      }
      
      // 2. Copiar todos los datos y agregar checkInRealizado
      final reservaData = Map<String, dynamic>.from(getResponse.data);
      
      // Verificar si ya tiene check-in realizado
      if (reservaData['checkInRealizado'] != null) {
        debugPrint('[ReservasService] La reserva ya tiene check-in realizado');
        return true;
      }
      
      // Agregar la fecha de check-in
      reservaData['checkInRealizado'] = DateTime.now().toUtc().toIso8601String();
      
      // Actualizar el estado a 'Activa'
      reservaData['estado'] = 'Activa';
      
      debugPrint('[ReservasService] Enviando reserva con check-in: ${reservaData['checkInRealizado']}, estado: ${reservaData['estado']}');
      
      // 3. Enviar el objeto completo con PUT
      final putResponse = await _dio.put(
        '/$reservaId',
        data: reservaData,
      );
      
      final success = putResponse.statusCode == 200 || putResponse.statusCode == 204;
      debugPrint('[ReservasService] Check-in completado: $success');
      return success;
    } catch (e) {
      debugPrint('[ReservasService] Error en check-in: $e');
      return false;
    }
  }

  Future<List<dynamic>> getReservasActividades() async {
    try {
      final response = await _dio.get('/ReservasActividades');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      throw Exception('Error al obtener reservas de actividades');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crea una nueva reserva de actividad
  /// POST /ReservasActividades
  Future<ReservaActividadApi?> crearReservaActividad({
    required int actividadId,
    required int huespedId,
    required DateTime fechaReserva,
    required String horaReserva,
    required int numeroPersonas,
    required double montoTotal,
    String? notasEspeciales,
  }) async {
    try {
      debugPrint('[ReservasService] Creando reserva de actividad');
      debugPrint(
        '[ReservasService] URL: ${_dio.options.baseUrl}/ReservasActividades',
      );

      final data = {
        'actividadId': actividadId,
        'huespedId': huespedId,
        'fechaReserva': fechaReserva.toIso8601String(),
        'horaReserva': horaReserva,
        'numeroPersonas': numeroPersonas,
        'montoTotal': montoTotal,
        'notasEspeciales': notasEspeciales,
      };

      debugPrint('[ReservasService] Request data: $data');

      final response = await _dio.post('/ReservasActividades', data: data);

      debugPrint('[ReservasService] Create status: ${response.statusCode}');
      debugPrint('[ReservasService] Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          return ReservaActividadApi.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
        return null;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[ReservasService] Error creando reserva: ${e.message}');
      debugPrint('[ReservasService] Response: ${e.response?.data}');
      return null;
    }
  }

  /// Cancela una reserva de actividad
  /// DELETE /ReservasActividades/{id}
  Future<bool> cancelarReservaActividad(int reservaActividadId) async {
    try {
      debugPrint(
        '[ReservasService] Cancelando reserva ID: $reservaActividadId',
      );
      debugPrint(
        '[ReservasService] URL: ${_dio.options.baseUrl}/ReservasActividades/$reservaActividadId',
      );

      final response = await _dio.delete(
        '/ReservasActividades/$reservaActividadId',
      );

      debugPrint('[ReservasService] Delete status: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      debugPrint('[ReservasService] Error cancelando reserva: ${e.message}');
      debugPrint('[ReservasService] Response: ${e.response?.data}');
      return false;
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'] as String?;
        final title = data['title'] as String?;
        return Exception(title ?? detail ?? 'Error en la solicitud');
      }

      return Exception('Error en la solicitud: ${error.response!.statusCode}');
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado. Verifica tu conexión.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception('No se pudo conectar al servidor.');
    }

    return Exception(error.message ?? 'Error desconocido');
  }
}

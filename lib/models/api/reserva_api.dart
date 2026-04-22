import 'package:flutter/foundation.dart';

class ReservaApi {
  final int reservaId;
  final int huespedId;
  final int habitacionId;
  final String? numeroReserva;
  final DateTime fechaCheckIn;
  final DateTime fechaCheckOut;
  final int numeroHuespedes;
  final int numeroNinos;
  final double montoTotal;
  final double montoPagado;
  final String estado; // Sigue siendo String no-nula, pero le daremos un default
  final DateTime? checkInRealizado;
  final DateTime? checkOutRealizado;
  final String? observaciones;
  final String? creadoPor;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  ReservaApi({
    required this.reservaId,
    required this.huespedId,
    required this.habitacionId,
    this.numeroReserva,
    required this.fechaCheckIn,
    required this.fechaCheckOut,
    required this.numeroHuespedes,
    required this.numeroNinos,
    required this.montoTotal,
    required this.montoPagado,
    required this.estado,
    this.checkInRealizado,
    this.checkOutRealizado,
    this.observaciones,
    this.creadoPor,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory ReservaApi.fromJson(Map<String, dynamic> json) {
  try {
    return ReservaApi(
      // Números: Si es null, ponemos 0 o un ID por defecto
      reservaId: json['reservaId'] is int ? json['reservaId'] : (int.tryParse(json['reservaId']?.toString() ?? '0') ?? 0),
      huespedId: json['huespedId'] is int ? json['huespedId'] : (int.tryParse(json['huespedId']?.toString() ?? '0') ?? 0),
      habitacionId: json['habitacionId'] is int ? json['habitacionId'] : (int.tryParse(json['habitacionId']?.toString() ?? '0') ?? 0),
      
      // Strings: Si es null, ponemos una cadena vacía o un valor por defecto
      numeroReserva: json['numeroReserva']?.toString() ?? 'S/N',
      estado: json['estadoNombre']?.toString() ?? json['estado']?.toString() ?? 'Pendiente',
      observaciones: json['observaciones']?.toString() ?? '',
      creadoPor: json['creadoPor']?.toString() ?? '',

      // Fechas obligatorias: Si fallan, usamos la fecha de hoy para evitar el crash
      fechaCheckIn: json['fechaCheckIn'] != null 
          ? DateTime.parse(json['fechaCheckIn'].toString()) 
          : DateTime.now(),
      fechaCheckOut: json['fechaCheckOut'] != null 
          ? DateTime.parse(json['fechaCheckOut'].toString()) 
          : DateTime.now(),

      // Otros campos numéricos
      numeroHuespedes: int.tryParse(json['numeroHuespedes']?.toString() ?? '1') ?? 1,
      numeroNinos: int.tryParse(json['numeroNinos']?.toString() ?? '0') ?? 0,
      montoTotal: double.tryParse(json['montoTotal']?.toString() ?? '0.0') ?? 0.0,
      montoPagado: double.tryParse(json['montoPagado']?.toString() ?? '0.0') ?? 0.0,

      // Fechas opcionales: tryParse devuelve null si el valor es null, perfecto para DateTime?
      checkInRealizado: json['checkInRealizado'] != null ? DateTime.tryParse(json['checkInRealizado'].toString()) : null,
      checkOutRealizado: json['checkOutRealizado'] != null ? DateTime.tryParse(json['checkOutRealizado'].toString()) : null,
      fechaCreacion: json['fechaCreacion'] != null ? DateTime.tryParse(json['fechaCreacion'].toString()) : null,
      fechaActualizacion: json['fechaActualizacion'] != null ? DateTime.tryParse(json['fechaActualizacion'].toString()) : null,
    );
  } catch (e, stack) {
    debugPrint('Error parseando ReservaApi: $e');
    debugPrint('Stacktrace: $stack');
    rethrow;
  }
}

  Map<String, dynamic> toJson() {
    return {
      'reservaId': reservaId,
      'huespedId': huespedId,
      'habitacionId': habitacionId,
      'fechaCheckIn': fechaCheckIn.toIso8601String(),
      'fechaCheckOut': fechaCheckOut.toIso8601String(),
      'numeroHuespedes': numeroHuespedes,
      'numeroNinos': numeroNinos,
      'montoTotal': montoTotal,
      'montoPagado': montoPagado,
      'estado': estado,
      'checkInRealizado': checkInRealizado?.toIso8601String(),
      'checkOutRealizado': checkOutRealizado?.toIso8601String(),
      'observaciones': observaciones,
      'creadoPor': creadoPor,
    };
  }

  bool get estaActiva {
    final ahora = DateTime.now();
    return estado == 'Activa' &&
        ahora.isAfter(fechaCheckIn) &&
        ahora.isBefore(fechaCheckOut);
  }

  int get diasRestantes {
    final ahora = DateTime.now();
    return fechaCheckOut.difference(ahora).inDays;
  }

  double get montoPendiente {
    return montoTotal - montoPagado;
  }
}

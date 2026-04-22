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
  final String estado; 
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
      
      reservaId: json['reservaId'] is int ? json['reservaId'] : (int.tryParse(json['reservaId']?.toString() ?? '0') ?? 0),
      huespedId: json['huespedId'] is int ? json['huespedId'] : (int.tryParse(json['huespedId']?.toString() ?? '0') ?? 0),
      habitacionId: json['habitacionId'] is int ? json['habitacionId'] : (int.tryParse(json['habitacionId']?.toString() ?? '0') ?? 0),
      
      
      numeroReserva: json['numeroReserva']?.toString() ?? 'S/N',
      estado: json['estadoNombre']?.toString() ?? json['estado']?.toString() ?? 'Pendiente',
      observaciones: json['observaciones']?.toString() ?? '',
      creadoPor: json['creadoPor']?.toString() ?? '',

      
      fechaCheckIn: json['fechaCheckIn'] != null 
          ? DateTime.parse(json['fechaCheckIn'].toString()) 
          : DateTime.now(),
      fechaCheckOut: json['fechaCheckOut'] != null 
          ? DateTime.parse(json['fechaCheckOut'].toString()) 
          : DateTime.now(),

      
      numeroHuespedes: int.tryParse(json['numeroHuespedes']?.toString() ?? '1') ?? 1,
      numeroNinos: int.tryParse(json['numeroNinos']?.toString() ?? '0') ?? 0,
      montoTotal: double.tryParse(json['montoTotal']?.toString() ?? '0.0') ?? 0.0,
      montoPagado: double.tryParse(json['montoPagado']?.toString() ?? '0.0') ?? 0.0,

      
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
    'numeroReserva': numeroReserva,
    'fechaCheckIn': fechaCheckIn.toIso8601String(),
    'fechaCheckOut': fechaCheckOut.toIso8601String(),
    'numeroHuespedes': numeroHuespedes,
    'numeroNinos': numeroNinos,
    'montoTotal': montoTotal,
    'montoPagado': montoPagado,
    'estadoReservaId': _estadoToId(estado),   
    'estadoNombre': estado,
    'estado': estado,
    'checkInRealizado': checkInRealizado?.toIso8601String(),
    'checkOutRealizado': checkOutRealizado?.toIso8601String(),
    'observaciones': observaciones,
    'creadoPor': creadoPor,
    'fechaCreacion': fechaCreacion?.toIso8601String(),
  };
}


static int _estadoToId(String estado) {
  switch (estado.toLowerCase()) {
    case 'activa':    return 2;
    case 'checkout':
    case 'check-out':
    case 'check out': return 3;
    case 'cancelada': return 4;
    default:          return 1; 
  }
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

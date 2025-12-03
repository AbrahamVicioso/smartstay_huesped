class ReservaApi {
  final int reservaId;
  final int huespedId;
  final int habitacionId;
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

  ReservaApi({
    required this.reservaId,
    required this.huespedId,
    required this.habitacionId,
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
  });

  factory ReservaApi.fromJson(Map<String, dynamic> json) {
    return ReservaApi(
      reservaId: json['reservaId'] as int,
      huespedId: json['huespedId'] as int,
      habitacionId: json['habitacionId'] as int,
      fechaCheckIn: DateTime.parse(json['fechaCheckIn'] as String),
      fechaCheckOut: DateTime.parse(json['fechaCheckOut'] as String),
      numeroHuespedes: json['numeroHuespedes'] as int,
      numeroNinos: json['numeroNinos'] as int,
      montoTotal: (json['montoTotal'] as num).toDouble(),
      montoPagado: (json['montoPagado'] as num).toDouble(),
      estado: json['estado'] as String,
      checkInRealizado: json['checkInRealizado'] != null
          ? DateTime.parse(json['checkInRealizado'] as String)
          : null,
      checkOutRealizado: json['checkOutRealizado'] != null
          ? DateTime.parse(json['checkOutRealizado'] as String)
          : null,
      observaciones: json['observaciones'] as String?,
      creadoPor: json['creadoPor'] as String?,
    );
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

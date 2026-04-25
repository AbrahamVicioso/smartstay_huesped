class Habitacion {
  final int habitacionId;
  final int hotelId;
  final String numeroHabitacion;
  final String tipoHabitacion;
  final int piso;
  final int capacidadMaxima;
  final double precioPorNoche;
  final String estado;
  final bool estaDisponible;
  final String? descripcion;

  // Additional fields from reservation
  final int? reservaId;
  final DateTime? fechaCheckIn;
  final DateTime? fechaCheckOut;
  final String? pinAcceso;
  final String? reservaEstado;

  Habitacion({
    required this.habitacionId,
    required this.hotelId,
    required this.numeroHabitacion,
    required this.tipoHabitacion,
    required this.piso,
    required this.capacidadMaxima,
    required this.precioPorNoche,
    required this.estado,
    required this.estaDisponible,
    this.descripcion,
    this.reservaId,
    this.fechaCheckIn,
    this.fechaCheckOut,
    this.pinAcceso,
    this.reservaEstado,
  });

  factory Habitacion.fromJson(Map<String, dynamic> json) {
    return Habitacion(
      habitacionId: json['habitacionId'] as int,
      hotelId: json['hotelId'] as int,
      numeroHabitacion: json['numeroHabitacion'] as String,
      tipoHabitacion: (json['tipoHabitacion'] ?? json['nombreTipo'] ?? '') as String,
      piso: json['piso'] as int,
      capacidadMaxima: json['capacidadMaxima'] as int,
      precioPorNoche: (json['precioPorNoche'] as num).toDouble(),
      estado: (json['estado'] ?? json['descripcionEstado'] ?? '') as String,
      estaDisponible: json['estaDisponible'] as bool? ?? true,
      descripcion: json['descripcion'] as String?,
      reservaId: json['reservaId'] as int?,
      fechaCheckIn: json['fechaCheckIn'] != null 
          ? DateTime.parse(json['fechaCheckIn'] as String)
          : null,
      fechaCheckOut: json['fechaCheckOut'] != null 
          ? DateTime.parse(json['fechaCheckOut'] as String)
          : null,
      pinAcceso: json['pinAcceso'] as String?,
      reservaEstado: json['reservaEstado'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habitacionId': habitacionId,
      'hotelId': hotelId,
      'numeroHabitacion': numeroHabitacion,
      'tipoHabitacion': tipoHabitacion,
      'piso': piso,
      'capacidadMaxima': capacidadMaxima,
      'precioPorNoche': precioPorNoche,
      'estado': estado,
      'estaDisponible': estaDisponible,
      'descripcion': descripcion,
      'reservaId': reservaId,
      'fechaCheckIn': fechaCheckIn?.toIso8601String(),
      'fechaCheckOut': fechaCheckOut?.toIso8601String(),
      'pinAcceso': pinAcceso,
      'reservaEstado': reservaEstado,
    };
  }

  /// Returns true if the room has an active reservation
  bool get tieneReservaActiva {
    if (reservaId == null || reservaEstado == null) return false;
    final estado = reservaEstado!.toLowerCase();
    return estado == 'activa' || estado == 'checkin' || estado == 'confirmada';
  }

  /// Returns true if the current date is within the reservation period
  bool get estaOcupada {
    if (fechaCheckIn == null || fechaCheckOut == null) return false;
    final ahora = DateTime.now();
    return ahora.isAfter(fechaCheckIn!) && ahora.isBefore(fechaCheckOut!);
  }

  /// Returns days remaining until check-out
  int get diasRestantes {
    if (fechaCheckOut == null) return 0;
    final ahora = DateTime.now();
    return fechaCheckOut!.difference(ahora).inDays;
  }

  /// Returns formatted check-out date
  String get fechaCheckOutFormateada {
    if (fechaCheckOut == null) return '-';
    return '${fechaCheckOut!.day}/${fechaCheckOut!.month}/${fechaCheckOut!.year}';
  }

  /// Creates a copy with additional reservation data
  Habitacion copyWithReserva({
    int? reservaId,
    DateTime? fechaCheckIn,
    DateTime? fechaCheckOut,
    String? pinAcceso,
    String? reservaEstado,
  }) {
    return Habitacion(
      habitacionId: habitacionId,
      hotelId: hotelId,
      numeroHabitacion: numeroHabitacion,
      tipoHabitacion: tipoHabitacion,
      piso: piso,
      capacidadMaxima: capacidadMaxima,
      precioPorNoche: precioPorNoche,
      estado: estado,
      estaDisponible: estaDisponible,
      descripcion: descripcion,
      reservaId: reservaId ?? this.reservaId,
      fechaCheckIn: fechaCheckIn ?? this.fechaCheckIn,
      fechaCheckOut: fechaCheckOut ?? this.fechaCheckOut,
      pinAcceso: pinAcceso ?? this.pinAcceso,
      reservaEstado: reservaEstado ?? this.reservaEstado,
    );
  }
}

// lib/models/api/reserva_hotel.dart
class ReservaHotel {
  final int reservaId;
  final int huespedId;
  final int habitacionId;
  final String numeroReserva;
  final DateTime fechaCheckIn;
  final DateTime fechaCheckOut;
  final int numeroHuespedes;
  final int numeroNinos;
  final double montoTotal;
  final double montoPagado;
  final int estadoReservaId;
  final String estadoNombre;
  final DateTime fechaCreacion;
  final DateTime? checkInRealizado;
  final DateTime? checkOutRealizado;
  final String? observaciones;
  final bool puedeDesbloquearCerradura;

  ReservaHotel({
    required this.reservaId,
    required this.huespedId,
    required this.habitacionId,
    required this.numeroReserva,
    required this.fechaCheckIn,
    required this.fechaCheckOut,
    required this.numeroHuespedes,
    required this.numeroNinos,
    required this.montoTotal,
    required this.montoPagado,
    required this.estadoReservaId,
    required this.estadoNombre,
    required this.fechaCreacion,
    this.checkInRealizado,
    this.checkOutRealizado,
    this.observaciones,
    this.puedeDesbloquearCerradura = false,
  });

  bool get tieneCheckIn => checkInRealizado != null;
  bool get tieneCheckOut => checkOutRealizado != null;
  bool get estaActiva => tieneCheckIn && !tieneCheckOut;

  int get diasRestantes {
    final ahora = DateTime.now();
    return fechaCheckOut.difference(ahora).inDays;
  }

  factory ReservaHotel.fromJson(Map<String, dynamic> json) {
    final huespedes = (json['huespedes'] as List?) ?? [];
    final puedeDesbloquear = huespedes.any(
      (h) => h['puedeDesbloquearCerradura'] == true,
    );

    return ReservaHotel(
      reservaId: json['reservaId'] ?? 0,
      huespedId: json['huespedId'] ?? 0,
      habitacionId: json['habitacionId'] ?? 0,
      numeroReserva: json['numeroReserva'] ?? '',
      fechaCheckIn: DateTime.parse(json['fechaCheckIn']),
      fechaCheckOut: DateTime.parse(json['fechaCheckOut']),
      numeroHuespedes: json['numeroHuespedes'] ?? 0,
      numeroNinos: json['numeroNinos'] ?? 0,
      montoTotal: (json['montoTotal'] ?? 0).toDouble(),
      montoPagado: (json['montoPagado'] ?? 0).toDouble(),
      estadoReservaId: json['estadoReservaId'] ?? 0,
      estadoNombre: json['estadoNombre'] ?? '',
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      checkInRealizado: json['checkInRealizado'] != null
          ? DateTime.tryParse(json['checkInRealizado'])
          : null,
      checkOutRealizado: json['checkOutRealizado'] != null
          ? DateTime.tryParse(json['checkOutRealizado'])
          : null,
      observaciones: json['observaciones'],
      puedeDesbloquearCerradura: puedeDesbloquear,
    );
  }
}

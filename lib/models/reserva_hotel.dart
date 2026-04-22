

enum EstadoReserva {
  pendiente,   
  activa,      
  checkOut,    
  cancelada,   
}

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

  
  EstadoReserva get estado {
    switch (estadoReservaId) {
      case 2: return EstadoReserva.activa;
      case 3: return EstadoReserva.checkOut;
      case 4: return EstadoReserva.cancelada;
      default: return EstadoReserva.pendiente;
    }
  }

  bool get tieneCheckIn  => checkInRealizado != null || estadoReservaId == 2;
  bool get tieneCheckOut => checkOutRealizado != null || estadoReservaId == 3;

  
  bool get esHistorial   => estadoReservaId == 3 || estadoReservaId == 4;

  
  bool get estaActiva    => !esHistorial;

  int get diasRestantes {
    final ahora = DateTime.now();
    return fechaCheckOut.difference(ahora).inDays;
  }

  factory ReservaHotel.fromJson(Map<String, dynamic> json) {
    DateTime parseSafeDate(dynamic d) =>
        d != null ? (DateTime.tryParse(d.toString()) ?? DateTime.now()) : DateTime.now();

    final huespedes = (json['huespedes'] as List?) ?? [];
    final estadoId  = json['estadoReservaId'] as int? ?? 1;
    final checkInTs = json['checkInRealizado'];

    
    final puedeDesbloquear = estadoId == 2 ||
        checkInTs != null ||
        huespedes.any((h) => h != null && h['puedeDesbloquearCerradura'] == true);

    return ReservaHotel(
      reservaId:    json['reservaId']    ?? 0,
      huespedId:    json['huespedId']    ?? 0,
      habitacionId: json['habitacionId'] ?? 0,
      numeroReserva: json['numeroReserva']?.toString() ?? 'S/N',
      fechaCheckIn:  parseSafeDate(json['fechaCheckIn']),
      fechaCheckOut: parseSafeDate(json['fechaCheckOut']),
      numeroHuespedes: json['numeroHuespedes'] ?? 0,
      numeroNinos:     json['numeroNinos']     ?? 0,
      montoTotal:   (json['montoTotal']  ?? 0).toDouble(),
      montoPagado:  (json['montoPagado'] ?? 0).toDouble(),
      estadoReservaId: estadoId,
      estadoNombre: json['estadoNombre']?.toString() ??
                    json['estado']?.toString() ?? 'Pendiente',
      fechaCreacion: parseSafeDate(json['fechaCreacion']),
      checkInRealizado: checkInTs != null
          ? DateTime.tryParse(checkInTs.toString()) : null,
      checkOutRealizado: json['checkOutRealizado'] != null
          ? DateTime.tryParse(json['checkOutRealizado'].toString()) : null,
      observaciones: json['observaciones']?.toString(),
      puedeDesbloquearCerradura: puedeDesbloquear,
    );
  }
}
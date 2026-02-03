class Reserva {
  final String id;
  final String numeroReserva;
  final String idUsuario;
  final String numeroHabitacion;
  final String tipoHabitacion;
  final DateTime fechaEntrada;
  final DateTime fechaSalida;
  final String pinAcceso; // PIN de 6 dígitos
  final String estado; // 'pendiente', 'activa', 'completada', 'cancelada'

  Reserva({
    required this.id,
    required this.numeroReserva,
    required this.idUsuario,
    required this.numeroHabitacion,
    required this.tipoHabitacion,
    required this.fechaEntrada,
    required this.fechaSalida,
    required this.pinAcceso,
    this.estado = 'pendiente',
  });

  bool get estaActiva {
    final ahora = DateTime.now();
    return estado == 'activa' &&
        ahora.isAfter(fechaEntrada) &&
        ahora.isBefore(fechaSalida);
  }

  int get diasRestantes {
    final ahora = DateTime.now();
    return fechaSalida.difference(ahora).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeroReserva': numeroReserva,
      'idUsuario': idUsuario,
      'numeroHabitacion': numeroHabitacion,
      'tipoHabitacion': tipoHabitacion,
      'fechaEntrada': fechaEntrada.toIso8601String(),
      'fechaSalida': fechaSalida.toIso8601String(),
      'pinAcceso': pinAcceso,
      'estado': estado,
    };
  }

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'],
      numeroReserva: json['numeroReserva'],
      idUsuario: json['idUsuario'],
      numeroHabitacion: json['numeroHabitacion'],
      tipoHabitacion: json['tipoHabitacion'],
      fechaEntrada: DateTime.parse(json['fechaEntrada']),
      fechaSalida: DateTime.parse(json['fechaSalida']),
      pinAcceso: json['pinAcceso'],
      estado: json['estado'] ?? 'pendiente',
    );
  }
}

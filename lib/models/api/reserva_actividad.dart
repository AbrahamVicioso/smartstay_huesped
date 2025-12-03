class ReservaActividadApi {
  final int reservaActividadId;
  final int actividadId;
  final int huespedId;
  final DateTime fechaReserva;
  final String horaReserva;
  final int numeroPersonas;
  final String estado;
  final double montoTotal;
  final String? notasEspeciales;
  final bool recordatorioEnviado;
  final DateTime? fechaRecordatorio;

  ReservaActividadApi({
    required this.reservaActividadId,
    required this.actividadId,
    required this.huespedId,
    required this.fechaReserva,
    required this.horaReserva,
    required this.numeroPersonas,
    required this.estado,
    required this.montoTotal,
    this.notasEspeciales,
    this.recordatorioEnviado = false,
    this.fechaRecordatorio,
  });

  factory ReservaActividadApi.fromJson(Map<String, dynamic> json) {
    return ReservaActividadApi(
      reservaActividadId: json['reservaActividadId'] as int,
      actividadId: json['actividadId'] as int,
      huespedId: json['huespedId'] as int,
      fechaReserva: DateTime.parse(json['fechaReserva'] as String),
      horaReserva: json['horaReserva'] as String,
      numeroPersonas: json['numeroPersonas'] as int,
      estado: json['estado'] as String,
      montoTotal: (json['montoTotal'] as num).toDouble(),
      notasEspeciales: json['notasEspeciales'] as String?,
      recordatorioEnviado: json['recordatorioEnviado'] as bool? ?? false,
      fechaRecordatorio: json['fechaRecordatorio'] != null
          ? DateTime.parse(json['fechaRecordatorio'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservaActividadId': reservaActividadId,
      'actividadId': actividadId,
      'huespedId': huespedId,
      'fechaReserva': fechaReserva.toIso8601String(),
      'horaReserva': horaReserva,
      'numeroPersonas': numeroPersonas,
      'estado': estado,
      'montoTotal': montoTotal,
      'notasEspeciales': notasEspeciales,
      'recordatorioEnviado': recordatorioEnviado,
      'fechaRecordatorio': fechaRecordatorio?.toIso8601String(),
    };
  }
}

class CreateReservaActividadCommand {
  final int actividadId;
  final int huespedId;
  final DateTime fechaReserva;
  final String horaReserva;
  final int numeroPersonas;
  final double montoTotal;
  final String? notasEspeciales;

  CreateReservaActividadCommand({
    required this.actividadId,
    required this.huespedId,
    required this.fechaReserva,
    required this.horaReserva,
    required this.numeroPersonas,
    required this.montoTotal,
    this.notasEspeciales,
  });

  Map<String, dynamic> toJson() {
    return {
      'actividadId': actividadId,
      'huespedId': huespedId,
      'fechaReserva': fechaReserva.toIso8601String(),
      'horaReserva': horaReserva,
      'numeroPersonas': numeroPersonas,
      'montoTotal': montoTotal,
      'notasEspeciales': notasEspeciales,
    };
  }
}

class UpdateReservaActividadCommand {
  final int reservaActividadId;
  final DateTime fechaReserva;
  final String horaReserva;
  final int numeroPersonas;
  final String estado;
  final double montoTotal;
  final String? notasEspeciales;
  final bool recordatorioEnviado;
  final DateTime? fechaRecordatorio;

  UpdateReservaActividadCommand({
    required this.reservaActividadId,
    required this.fechaReserva,
    required this.horaReserva,
    required this.numeroPersonas,
    required this.estado,
    required this.montoTotal,
    this.notasEspeciales,
    required this.recordatorioEnviado,
    this.fechaRecordatorio,
  });

  Map<String, dynamic> toJson() {
    return {
      'reservaActividadId': reservaActividadId,
      'fechaReserva': fechaReserva.toIso8601String(),
      'horaReserva': horaReserva,
      'numeroPersonas': numeroPersonas,
      'estado': estado,
      'montoTotal': montoTotal,
      'notasEspeciales': notasEspeciales,
      'recordatorioEnviado': recordatorioEnviado,
      'fechaRecordatorio': fechaRecordatorio?.toIso8601String(),
    };
  }
}

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

  
  ReservaActividadApi copyWith({
    int? reservaActividadId,
    int? actividadId,
    int? huespedId,
    DateTime? fechaReserva,
    String? horaReserva,
    int? numeroPersonas,
    String? estado,
    double? montoTotal,
    String? notasEspeciales,
    bool? recordatorioEnviado,
    DateTime? fechaRecordatorio,
  }) {
    return ReservaActividadApi(
      reservaActividadId: reservaActividadId ?? this.reservaActividadId,
      actividadId: actividadId ?? this.actividadId,
      huespedId: huespedId ?? this.huespedId,
      fechaReserva: fechaReserva ?? this.fechaReserva,
      horaReserva: horaReserva ?? this.horaReserva,
      numeroPersonas: numeroPersonas ?? this.numeroPersonas,
      estado: estado ?? this.estado,
      montoTotal: montoTotal ?? this.montoTotal,
      notasEspeciales: notasEspeciales ?? this.notasEspeciales,
      recordatorioEnviado: recordatorioEnviado ?? this.recordatorioEnviado,
      fechaRecordatorio: fechaRecordatorio ?? this.fechaRecordatorio,
    );
  }

  factory ReservaActividadApi.fromJson(Map<String, dynamic> json) {
    return ReservaActividadApi(
      reservaActividadId: json['reservaActividadId'] ?? json['reservaId'] ?? 0,
      actividadId: json['actividadId'] ?? 0,
      huespedId: json['huespedId'] ?? 0,
      fechaReserva: json['fechaReserva'] != null
          ? DateTime.parse(json['fechaReserva'])
          : DateTime.now(),
      horaReserva: json['horaReserva']?.toString() ?? "00:00",
      numeroPersonas: json['numeroPersonas'] ?? 1,

      
      estado: (json['estado'] ?? json['estadoNombre'] ?? 'Confirmada')
          .toString(),

      montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0.0,
      notasEspeciales: json['notasEspeciales']?.toString(),
      recordatorioEnviado:
          json['recordatorioEnviado'] == true ||
          json['recordatorioEnviado'] == 1,
      fechaRecordatorio: json['fechaRecordatorio'] != null
          ? DateTime.parse(json['fechaRecordatorio'])
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
class CredencialAcceso {
  final int credencialId;
  final int? huespedId;
  final int? reservaId;
  final int? reservaActividadId;
  final String codigoPin;
  final DateTime fechaActivacion;
  final DateTime fechaExpiracion;
  final bool estaActiva;
  final String tipoCredencial;
  final int numeroUsos;

  CredencialAcceso({
    required this.credencialId,
    this.huespedId,
    this.reservaId,
    this.reservaActividadId,
    required this.codigoPin,
    required this.fechaActivacion,
    required this.fechaExpiracion,
    required this.estaActiva,
    required this.tipoCredencial,
    required this.numeroUsos,
  });

  CredencialAcceso copyWith({bool? estaActiva}) {
    return CredencialAcceso(
      credencialId: credencialId,
      huespedId: huespedId,
      reservaId: reservaId,
      reservaActividadId: reservaActividadId,
      codigoPin: codigoPin,
      fechaActivacion: fechaActivacion,
      fechaExpiracion: fechaExpiracion,
      estaActiva: estaActiva ?? this.estaActiva,
      tipoCredencial: tipoCredencial,
      numeroUsos: numeroUsos,
    );
  }

  factory CredencialAcceso.fromJson(Map<String, dynamic> json) {
    return CredencialAcceso(
      credencialId: json['credencialId'] ?? 0,
      huespedId: json['huespedId'],
      reservaId: json['reservaId'],
      reservaActividadId: json['reservaActividadId'],
      codigoPin: json['codigoPin']?.toString() ?? '',
      fechaActivacion: json['fechaActivacion'] != null
          ? DateTime.parse(json['fechaActivacion'])
          : DateTime.now(),
      fechaExpiracion: json['fechaExpiracion'] != null
          ? DateTime.parse(json['fechaExpiracion'])
          : DateTime.now(),
      estaActiva: json['estaActiva'] == true,
      tipoCredencial: json['tipoCredencial']?.toString() ?? '',
      numeroUsos: json['numeroUsos'] ?? 0,
    );
  }
}

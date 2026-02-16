class Huesped {
  final int? huespedId;
  final String usuarioId;
  final String nombreCompleto;
  final String tipoDocumento;
  final String numeroDocumento;
  final String nacionalidad;
  final DateTime? fechaNacimiento;
  final String? contactoEmergencia;
  final String? telefonoEmergencia;
  final bool esVip;
  final DateTime? fechaRegistro;
  final String? preferenciasAlimentarias;
  final String? notasEspeciales;
  final String? correoElectronico;

  Huesped({
    this.huespedId,
    required this.usuarioId,
    required this.nombreCompleto,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.nacionalidad,
    this.fechaNacimiento,
    this.contactoEmergencia,
    this.telefonoEmergencia,
    this.esVip = false,
    this.fechaRegistro,
    this.preferenciasAlimentarias,
    this.notasEspeciales,
    this.correoElectronico,
  });

  factory Huesped.fromJson(Map<String, dynamic> json) {
    return Huesped(
      huespedId: json['huespedId'] as int?,
      usuarioId: json['usuarioId'] as String? ?? '',
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      tipoDocumento: json['tipoDocumento'] as String? ?? '',
      numeroDocumento: json['numeroDocumento'] as String? ?? '',
      nacionalidad: json['nacionalidad'] as String? ?? '',
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.tryParse(json['fechaNacimiento'] as String)
          : null,
      contactoEmergencia: json['contactoEmergencia'] as String?,
      telefonoEmergencia: json['telefonoEmergencia'] as String?,
      esVip: json['esVip'] as bool? ?? json['esVIP'] as bool? ?? false,
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.tryParse(json['fechaRegistro'] as String)
          : null,
      preferenciasAlimentarias: json['preferenciasAlimentarias'] as String?,
      notasEspeciales: json['notasEspeciales'] as String?,
      correoElectronico: json['correoElectronico'] as String?,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'usuarioId': usuarioId,
      'nombreCompleto': nombreCompleto,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'nacionalidad': nacionalidad,
      'fechaNacimiento':
          fechaNacimiento?.toIso8601String() ??
          DateTime(2000, 1, 1).toIso8601String(),
      'contactoEmergencia': contactoEmergencia,
      'telefonoEmergencia': telefonoEmergencia,
      'esVip': esVip,
      'preferenciasAlimentarias': preferenciasAlimentarias,
      'notasEspeciales': notasEspeciales,
      'correoElectronico': correoElectronico,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'huespedId': huespedId,
      'nombreCompleto': nombreCompleto,
      'contactoEmergencia': contactoEmergencia,
      'telefonoEmergencia': telefonoEmergencia,
      'esVip': esVip,
      'preferenciasAlimentarias': preferenciasAlimentarias,
      'notasEspeciales': notasEspeciales,
    };
  }

  Huesped copyWith({
    int? huespedId,
    String? usuarioId,
    String? nombreCompleto,
    String? tipoDocumento,
    String? numeroDocumento,
    String? nacionalidad,
    DateTime? fechaNacimiento,
    String? contactoEmergencia,
    String? telefonoEmergencia,
    bool? esVip,
    DateTime? fechaRegistro,
    String? preferenciasAlimentarias,
    String? notasEspeciales,
    String? correoElectronico,
  }) {
    return Huesped(
      huespedId: huespedId ?? this.huespedId,
      usuarioId: usuarioId ?? this.usuarioId,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      contactoEmergencia: contactoEmergencia ?? this.contactoEmergencia,
      telefonoEmergencia: telefonoEmergencia ?? this.telefonoEmergencia,
      esVip: esVip ?? this.esVip,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      preferenciasAlimentarias:
          preferenciasAlimentarias ?? this.preferenciasAlimentarias,
      notasEspeciales: notasEspeciales ?? this.notasEspeciales,
      correoElectronico: correoElectronico ?? this.correoElectronico,
    );
  }
}

class Huesped {
  final int? huespedId;
  final String usuarioId;
  final String nombreCompleto;
  final int tipoDocumentoId;        // ← cambiado a int
  final String tipoDocumento;       // ← solo para display (mapeado localmente)
  final String numeroDocumento;
  final String nacionalidad;
  final DateTime? fechaNacimiento;
  final String? contactoEmergencia;
  final String? telefonoEmergencia;
  final String? telefono;
  final bool esVip;
  final DateTime? fechaRegistro;
  final String? preferenciasAlimentarias;
  final String? notasEspeciales;
  final String? correoElectronico;

  // Mapa estático para convertir ID → nombre legible
  static const Map<int, String> _tiposDocumentoMap = {
    1: 'Pasaporte',
    2: 'Cédula',
    3: 'Licencia de Conducir',
    4: 'Otro',
  };

  static int tipoDocumentoToId(String tipo) {
    const map = {
      'Pasaporte': 1,
      'Cédula': 2,
      'Licencia de Conducir': 3,
      'Otro': 4,
    };
    return map[tipo] ?? 1;
  }

  Huesped({
    this.huespedId,
    required this.usuarioId,
    required this.nombreCompleto,
    required this.tipoDocumentoId,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.nacionalidad,
    this.fechaNacimiento,
    this.contactoEmergencia,
    this.telefonoEmergencia,
    this.telefono,
    this.esVip = false,
    this.fechaRegistro,
    this.preferenciasAlimentarias,
    this.notasEspeciales,
    this.correoElectronico,
  });

  factory Huesped.fromJson(Map<String, dynamic> json) {
    final id = json['tipoDocumentoId'] as int? ?? 1;
    return Huesped(
      huespedId: json['huespedId'] as int?,
      usuarioId: json['usuarioId'] as String? ?? '',
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      tipoDocumentoId: id,
      tipoDocumento: _tiposDocumentoMap[id] ?? json['tipoDocumento'] as String? ?? 'Cédula',
      numeroDocumento: json['numeroDocumento'] as String? ?? '',
      nacionalidad: json['nacionalidad'] as String? ?? '',
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.tryParse(json['fechaNacimiento'] as String)
          : null,
      contactoEmergencia: json['contactoEmergencia'] as String?,
      telefonoEmergencia: json['telefonoEmergencia'] as String?,
      telefono: json['telefono'] as String?,
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
      'tipoDocumentoId': tipoDocumentoId,
      'numeroDocumento': numeroDocumento,
      'nacionalidad': nacionalidad,
      'fechaNacimiento': fechaNacimiento?.toIso8601String() ??
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
      'tipoDocumentoId': tipoDocumentoId,   // ← API espera int, no string
      'numeroDocumento': numeroDocumento,
      'nacionalidad': nacionalidad,
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      'contactoEmergencia': contactoEmergencia,
      'telefonoEmergencia': telefonoEmergencia,
      'esVip': esVip,
      'preferenciasAlimentarias': preferenciasAlimentarias,
      'notasEspeciales': notasEspeciales,
      'correoElectronico': correoElectronico,
    };
  }

  Huesped copyWith({
    int? huespedId,
    String? usuarioId,
    String? nombreCompleto,
    int? tipoDocumentoId,
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
    final newId = tipoDocumentoId ?? this.tipoDocumentoId;
    return Huesped(
      huespedId: huespedId ?? this.huespedId,
      usuarioId: usuarioId ?? this.usuarioId,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      tipoDocumentoId: newId,
      tipoDocumento: tipoDocumento ?? _tiposDocumentoMap[newId] ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      contactoEmergencia: contactoEmergencia ?? this.contactoEmergencia,
      telefonoEmergencia: telefonoEmergencia ?? this.telefonoEmergencia,
      esVip: esVip ?? this.esVip,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      preferenciasAlimentarias: preferenciasAlimentarias ?? this.preferenciasAlimentarias,
      notasEspeciales: notasEspeciales ?? this.notasEspeciales,
      correoElectronico: correoElectronico ?? this.correoElectronico,
    );
  }
}
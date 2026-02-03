class ActividadRecreativa {
  final int actividadId;
  final int hotelId;
  final String nombreActividad;
  final String? descripcion;
  final String categoria;
  final String ubicacion;
  final String horaApertura;
  final String horaCierre;
  final int capacidadMaxima;
  final double precioPorPersona;
  final bool requiereReserva;
  final int? duracionMinutos;
  final bool estaActiva;
  final String? imagenUrl;

  ActividadRecreativa({
    required this.actividadId,
    required this.hotelId,
    required this.nombreActividad,
    this.descripcion,
    required this.categoria,
    required this.ubicacion,
    required this.horaApertura,
    required this.horaCierre,
    required this.capacidadMaxima,
    required this.precioPorPersona,
    required this.requiereReserva,
    this.duracionMinutos,
    this.estaActiva = true,
    this.imagenUrl,
  });

  factory ActividadRecreativa.fromJson(Map<String, dynamic> json) {
    return ActividadRecreativa(
      actividadId: json['actividadId'] as int,
      hotelId: json['hotelId'] as int,
      nombreActividad: json['nombreActividad'] as String,
      descripcion: json['descripcion'] as String?,
      categoria: json['categoria'] as String,
      ubicacion: json['ubicacion'] as String,
      horaApertura: json['horaApertura'] as String,
      horaCierre: json['horaCierre'] as String,
      capacidadMaxima: json['capacidadMaxima'] as int,
      precioPorPersona: (json['precioPorPersona'] as num).toDouble(),
      requiereReserva: json['requiereReserva'] as bool,
      duracionMinutos: json['duracionMinutos'] as int?,
      estaActiva: json['estaActiva'] as bool? ?? true,
      imagenUrl: json['imagenUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actividadId': actividadId,
      'hotelId': hotelId,
      'nombreActividad': nombreActividad,
      'descripcion': descripcion,
      'categoria': categoria,
      'ubicacion': ubicacion,
      'horaApertura': horaApertura,
      'horaCierre': horaCierre,
      'capacidadMaxima': capacidadMaxima,
      'precioPorPersona': precioPorPersona,
      'requiereReserva': requiereReserva,
      'duracionMinutos': duracionMinutos,
      'estaActiva': estaActiva,
      'imagenUrl': imagenUrl,
    };
  }
}

class CreateActividadRecreativaCommand {
  final int hotelId;
  final String nombreActividad;
  final String? descripcion;
  final String categoria;
  final String ubicacion;
  final String horaApertura;
  final String horaCierre;
  final int capacidadMaxima;
  final double precioPorPersona;
  final bool requiereReserva;
  final int? duracionMinutos;
  final String? imagenUrl;

  CreateActividadRecreativaCommand({
    required this.hotelId,
    required this.nombreActividad,
    this.descripcion,
    required this.categoria,
    required this.ubicacion,
    required this.horaApertura,
    required this.horaCierre,
    required this.capacidadMaxima,
    required this.precioPorPersona,
    required this.requiereReserva,
    this.duracionMinutos,
    this.imagenUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'hotelId': hotelId,
      'nombreActividad': nombreActividad,
      'descripcion': descripcion,
      'categoria': categoria,
      'ubicacion': ubicacion,
      'horaApertura': horaApertura,
      'horaCierre': horaCierre,
      'capacidadMaxima': capacidadMaxima,
      'precioPorPersona': precioPorPersona,
      'requiereReserva': requiereReserva,
      'duracionMinutos': duracionMinutos,
      'imagenUrl': imagenUrl,
    };
  }
}

class UpdateActividadRecreativaCommand {
  final int actividadId;
  final String nombreActividad;
  final String? descripcion;
  final String categoria;
  final String ubicacion;
  final String horaApertura;
  final String horaCierre;
  final int capacidadMaxima;
  final double precioPorPersona;
  final bool requiereReserva;
  final int? duracionMinutos;
  final bool estaActiva;
  final String? imagenUrl;

  UpdateActividadRecreativaCommand({
    required this.actividadId,
    required this.nombreActividad,
    this.descripcion,
    required this.categoria,
    required this.ubicacion,
    required this.horaApertura,
    required this.horaCierre,
    required this.capacidadMaxima,
    required this.precioPorPersona,
    required this.requiereReserva,
    this.duracionMinutos,
    required this.estaActiva,
    this.imagenUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'actividadId': actividadId,
      'nombreActividad': nombreActividad,
      'descripcion': descripcion,
      'categoria': categoria,
      'ubicacion': ubicacion,
      'horaApertura': horaApertura,
      'horaCierre': horaCierre,
      'capacidadMaxima': capacidadMaxima,
      'precioPorPersona': precioPorPersona,
      'requiereReserva': requiereReserva,
      'duracionMinutos': duracionMinutos,
      'estaActiva': estaActiva,
      'imagenUrl': imagenUrl,
    };
  }
}

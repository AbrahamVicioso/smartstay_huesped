class Actividad {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono; 
  final String categoria; 
  final String horarioApertura;
  final String horarioCierre;
  final int capacidadMaxima;
  final bool requiereReserva;
  final double? precio;

  Actividad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.categoria,
    required this.horarioApertura,
    required this.horarioCierre,
    required this.capacidadMaxima,
    this.requiereReserva = true,
    this.precio,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'categoria': categoria,
      'horarioApertura': horarioApertura,
      'horarioCierre': horarioCierre,
      'capacidadMaxima': capacidadMaxima,
      'requiereReserva': requiereReserva,
      'precio': precio,
    };
  }

  factory Actividad.fromJson(Map<String, dynamic> json) {
  return Actividad(
    
    id: json['actividadId']?.toString() ?? json['id']?.toString() ?? '0', 
    
    
    nombre: json['nombre'] ?? json['title'] ?? json['titulo'] ?? 'Sin nombre',
    
    descripcion: json['descripcion'] ?? json['description'] ?? '',
    icono: json['icono'] ?? 'help_outline',
    categoria: json['categoria'] ?? 'general',
    horarioApertura: json['horarioApertura'] ?? '',
    horarioCierre: json['horarioCierre'] ?? '',
    
    
    capacidadMaxima: json['capacidadMaxima'] is String 
        ? int.tryParse(json['capacidadMaxima']) ?? 0 
        : (json['capacidadMaxima'] ?? 0),
        
    requiereReserva: json['requiereReserva'] ?? true,
    precio: json['precio'] != null ? (json['precio'] as num).toDouble() : null,
  );
}
}

class ReservaActividad {
  final String id;
  final String idActividad;
  final String idUsuario;
  final DateTime fecha;
  final String hora;
  final int numeroPersonas;
  final String estado; 

  ReservaActividad({
    required this.id,
    required this.idActividad,
    required this.idUsuario,
    required this.fecha,
    required this.hora,
    required this.numeroPersonas,
    this.estado = 'pendiente',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idActividad': idActividad,
      'idUsuario': idUsuario,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'numeroPersonas': numeroPersonas,
      'estado': estado,
    };
  }

  factory ReservaActividad.fromJson(Map<String, dynamic> json) {
    return ReservaActividad(
      id: json['id'],
      idActividad: json['idActividad'],
      idUsuario: json['idUsuario'],
      fecha: DateTime.parse(json['fecha']),
      hora: json['hora'],
      numeroPersonas: json['numeroPersonas'],
      estado: json['estado'] ?? 'pendiente',
    );
  }
}

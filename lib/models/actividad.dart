class Actividad {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono; // Nombre del icono de Material Icons
  final String categoria; // 'gimnasio', 'spa', 'restaurante', 'piscina', 'tour'
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
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      icono: json['icono'],
      categoria: json['categoria'],
      horarioApertura: json['horarioApertura'],
      horarioCierre: json['horarioCierre'],
      capacidadMaxima: json['capacidadMaxima'],
      requiereReserva: json['requiereReserva'] ?? true,
      precio: json['precio']?.toDouble(),
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
  final String estado; // 'pendiente', 'confirmada', 'cancelada', 'completada'

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

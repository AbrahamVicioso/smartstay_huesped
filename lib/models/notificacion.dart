class Notificacion {
  final String id;
  final String idUsuario;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final String tipo; // 'acceso', 'recordatorio', 'sistema', 'actividad'
  final bool leida;
  final Map<String, dynamic>? datos; // Datos adicionales según el tipo

  Notificacion({
    required this.id,
    required this.idUsuario,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.tipo,
    this.leida = false,
    this.datos,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idUsuario': idUsuario,
      'titulo': titulo,
      'mensaje': mensaje,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'leida': leida,
      'datos': datos,
    };
  }

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      idUsuario: json['idUsuario'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      fecha: DateTime.parse(json['fecha']),
      tipo: json['tipo'],
      leida: json['leida'] ?? false,
      datos: json['datos'],
    );
  }

  Notificacion copyWith({
    String? id,
    String? idUsuario,
    String? titulo,
    String? mensaje,
    DateTime? fecha,
    String? tipo,
    bool? leida,
    Map<String, dynamic>? datos,
  }) {
    return Notificacion(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
      leida: leida ?? this.leida,
      datos: datos ?? this.datos,
    );
  }
}

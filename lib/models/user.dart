class User {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String? fotoPerfil;
  final String idioma; // 'es' o 'en'

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    this.fotoPerfil,
    this.idioma = 'es',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'fotoPerfil': fotoPerfil,
      'idioma': idioma,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      telefono: json['telefono'],
      fotoPerfil: json['fotoPerfil'],
      idioma: json['idioma'] ?? 'es',
    );
  }

  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? fotoPerfil,
    String? idioma,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      idioma: idioma ?? this.idioma,
    );
  }
}

class Notificaciones {
  final String id;
  final String title; // Nuevo campo para el título
  final String message;
  final DateTime timestamp;

  Notificaciones({
    required this.id,
    required this.title, // Añadido el título
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title, // Incluye el título en el mapa
      'message': message,
      'timestamp': timestamp,
    };
  }

  static Notificaciones fromMap(Map<String, dynamic> map) {
    return Notificaciones(
      id: map['id'],
      title: map['title'], // Recupera el título del mapa
      message: map['message'],
      timestamp: map['timestamp'].toDate(),
    );
  }
}

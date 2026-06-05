class Question {
  String id;
  String text;
  List<String> options; // Las 4 opciones (Rojo, Azul, Amarillo, Verde)
  int correctOptionIndex; // 0 a 3
  int timerSeconds; // 15, 30, etc.
  String difficulty; // Básico, Intermedio, Avanzado
  String themeId; // Para vincularlo a un Tema (Matemáticas, etc.)

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.timerSeconds,
    required this.difficulty,
    required this.themeId,
  });

  // Convierte un documento de Firestore a un objeto Question
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'timerSeconds': timerSeconds,
      'difficulty': difficulty,
      'themeId': themeId,
    };
  }
}
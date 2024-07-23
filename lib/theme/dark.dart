import 'package:flutter/material.dart';
import 'package:rastreogt/conf/export.dart';

class ThemeDark {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor:Colors.grey[900]!,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(95, 44, 51, 99),
        inversePrimary: Color.fromARGB(255, 61, 63, 77),
        secondary: Color(0xFF1F1F1F),
        surface: Color(0xFF1F1F1F),
        error: Colors.red,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Color.fromARGB(255, 100, 30, 30),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(139, 52, 55, 77),
        titleTextStyle: TextStyle(color: Color.fromARGB(255, 237, 220, 220), fontSize: 20),
        iconTheme: IconThemeData(color: Color.fromARGB(255, 216, 207, 207)),
      ),
      buttonTheme:  ButtonThemeData(
        buttonColor: Color.fromARGB(255, 130, 138, 199),
        textTheme: ButtonTextTheme.normal,
      ),

       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 37, 41, 69)),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      textTheme: const TextTheme(
        // Define los estilos de texto aquí si es necesario

      ),
      cardTheme: const CardTheme(
        color: Color.fromARGB(165, 49, 49, 98),
      ),
      cardColor: Color.fromARGB(234, 35, 35, 81),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Color.fromARGB(255, 237, 220, 220)),
        labelStyle: TextStyle(color: Color.fromARGB(255, 237, 220, 220)),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 100, 104, 133),style: BorderStyle.solid),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 100, 104, 133)),
        ),
         enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 124, 124, 134)),
        ),
      ),
    );
  }
}
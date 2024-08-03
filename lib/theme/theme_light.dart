import 'package:flutter/material.dart';
import 'package:rastreogt/conf/export.dart';

class ThemeLight {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color.fromARGB(255, 114, 130, 255),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color.fromARGB(255, 96, 97, 179),
        inversePrimary: Color.fromARGB(255, 90, 110, 255),
        secondary: Colors.white,
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 114, 130, 255),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color.fromARGB(255, 114, 130, 255),
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 114, 130, 255)),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      textTheme: const TextTheme(
        // Define los estilos de texto aquí si es necesario
      ),
      cardTheme: const CardTheme(
        color: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 114, 130, 255)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 59, 59, 62)),
        ),
      ),
        dialogTheme:  DialogTheme(
        backgroundColor: Colors.grey.shade200,
        titleTextStyle: GoogleFonts.roboto(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: GoogleFonts.roboto(color: Colors.black, fontSize: 16),
      ),
    );
  }
}
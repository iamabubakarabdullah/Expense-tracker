import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.grey.shade800,
    background: Colors.grey.shade900,
    secondary: Colors.white70,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 18, color: Colors.white),
    titleMedium: TextStyle(
        fontSize: 16, color: Colors.white, fontWeight: FontWeight.normal),
    titleSmall: TextStyle(
        fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white),
  ),
);

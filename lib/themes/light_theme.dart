import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.grey.shade300,
    secondary: Colors.grey.shade800,
    primary: Colors.white,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 18, color: Colors.black),
    titleMedium: TextStyle(
        fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
    titleSmall: TextStyle(
        fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
  ),
);

import 'package:expense/database/expense_database.dart';
import 'package:expense/pages/home_page.dart';
import 'package:expense/themes/dark_theme.dart';
import 'package:expense/themes/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialized db
  await ExpenseDatabase.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) =>
          ExpenseDatabase()..getThemePreference(), // Retrieve theme preference
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // // Set system navigation bar color
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   systemNavigationBarColor: Colors.transparent, // or any color you prefer
    // ));
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Expense Tracker',
          //darkTheme: darkTheme,
          theme: value.darkTheme ? darkTheme : lightTheme,
          home: const HomePage(),
        );
      },
    );
  }
}

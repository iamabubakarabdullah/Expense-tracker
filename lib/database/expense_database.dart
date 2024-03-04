import 'package:device_info_plus/device_info_plus.dart';
import 'package:expense/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  final List<Expense> _allExpenses = [];
  bool _darkTheme = true;
  bool get darkTheme => _darkTheme;

  // Method to save theme preference
  Future<void> saveThemePreference(bool isDark) async {
    _darkTheme = isDark;
    notifyListeners(); // Notify listeners about the change
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', isDark);
  }

  // Method to retrieve theme preference
  Future<void> getThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDark = prefs.getBool('darkTheme');
    if (isDark != null) {
      _darkTheme = isDark;
      notifyListeners(); // Notify listeners about the change
    }
  }

  // SETUP

  // initialize db
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  // GETTERS

  List<Expense> get allExpenses => _allExpenses;

  // OPERATIONS

  // create - add a new expense

  Future<void> createNewExpense(Expense newExpense) async {
    // add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));
    // re-read from db
    await readExpenses();
  }

  // read - expense from db
  Future<void> readExpenses() async {
    // fetch all existing expenses from db
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    // give to local expense list
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);

    //update UI
    notifyListeners();
  }

  // update - edit an expense in db
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    // make sure new expense has same id as existing one
    updatedExpense.id = id;

    // update in db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));

    // re-read from db
    await readExpenses();
  }

  // delete - an expense
  Future<void> deleteExpense(int id) async {
    // delete an expense from db
    await isar.writeTxn(() => isar.expenses.delete(id));

    // re-read from db
    await readExpenses();
  }

  // HELPER

  // calculate total expenses for each month, year
  Future<Map<String, double>> calculateMonthlyTotals() async {
    // ensure the expenses are read from db
    await readExpenses();

    // create a map to keep track of total expenses per month
    Map<String, double> monthlyTotals = {};

    // iterate over all expenses
    for (var expense in _allExpenses) {
      // extract the yar & month from the date of the expense
      String yearMonth = '${expense.date.year}-${expense.date.month}';

      // if the month is not yet in the map, initialize to 0
      if (!monthlyTotals.containsKey(yearMonth)) {
        monthlyTotals[yearMonth] = 0;
      }

      // add the expense amount to the total for each month
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount;
    }
    return monthlyTotals;
  }

  // calculate current month total
  Future<double> calculateCurrentMonthTotal() async {
    // ensure expenses are read from db
    await readExpenses();

    //get current month,year
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    // filter the expenses to include only those for this month this year
    List<Expense> currentMonthExpenses = _allExpenses.where((expense) {
      return expense.date.month == currentMonth &&
          expense.date.year == currentYear;
    }).toList();

    double total =
        currentMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);

    return total;
  }

  // get start month
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime
          .january; // default to current month is no expenses are recorded
    }

    // sort expenses by date to find the earliest
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    //return _allExpenses.first.date.month;
    return DateTime.january;
  }

  // get start year
  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now()
          .year; // default to current month is no expenses are recorded
    }

    // sort expenses by date to find the earliest
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    //return _allExpenses.first.date.year;
    return DateTime.now().year;
  }

/////////////////////////////////////////

  // void readSpecificExpenses(int year) async {
  //   // Fetch expenses for the specified year
  //   List<Expense> yearExpenses = allExpenses.where((expense) {
  //     return expense.date.year == year;
  //   }).toList();

  //   // Group expenses by month
  //   Map<int, List<Expense>> groupedExpenses = {};
  //   for (var expense in yearExpenses) {
  //     int month = expense.date.month;
  //     if (!groupedExpenses.containsKey(month)) {
  //       groupedExpenses[month] = [];
  //     }
  //     groupedExpenses[month]!.add(expense);
  //   }

  //   // Print expenses by year and month
  //   groupedExpenses.forEach((month, expenses) {
  //     print(_getMonthName(month));
  //     for (var expense in expenses) {
  //       print('${expense.id} ${expense.name} ${expense.amount.toString()}');
  //     }
  //   });
  // }

  // String _getMonthName(int month) {
  //   switch (month) {
  //     case 1:
  //       return 'January';
  //     case 2:
  //       return 'February';
  //     case 3:
  //       return 'March';
  //     case 4:
  //       return 'April';
  //     case 5:
  //       return 'May';
  //     case 6:
  //       return 'June';
  //     case 7:
  //       return 'July';
  //     case 8:
  //       return 'August';
  //     case 9:
  //       return 'September';
  //     case 10:
  //       return 'October';
  //     case 11:
  //       return 'November';
  //     case 12:
  //       return 'December';
  //     default:
  //       return '';
  //   }
  // }

  Future<bool> requestStoragePermission(Permission permission) async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt >= 30) {
      var request = await Permission.manageExternalStorage.request();
      if (request.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      if (await permission.isGranted) {
        return true;
      } else {
        var result = await permission.request();
        if (result.isGranted) {
          return true;
        } else {
          return false;
        }
      }
    }
  }
}

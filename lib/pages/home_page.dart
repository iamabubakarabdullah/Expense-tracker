import 'package:expense/bar%20graph/bar_graph.dart';
import 'package:expense/components/drawer.dart';
import 'package:expense/components/my_list_tile.dart';
import 'package:expense/database/expense_database.dart';
import 'package:expense/helper/helper_functions.dart';
import 'package:expense/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // future to load graph data & monthly total
  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? _calculateCurrentMonthTotal;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        // get dates
        int startMonth = value.getStartMonth();
        int startYear = value.getStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;

        // only display the expenses for the current month
        List<Expense> currentMonthExpenses = value.allExpenses.where((expense) {
          return expense.date.year == currentYear &&
              expense.date.month == currentMonth;
        }).toList();
        //value.readSpecificExpenses(2024);
        // return UI
        return Scaffold(
          extendBody: true,
          backgroundColor: Theme.of(context).colorScheme.background,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.grey.shade100,
            onPressed: () {
              openNewExpenseBox();
            },
            child: const Icon(
              Icons.add,
            ),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: FutureBuilder<double>(
              future: _calculateCurrentMonthTotal,
              builder: (context, snapshot) {
                // loaded
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text(
                    'Rs ${snapshot.data!.toStringAsFixed(1)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge, // Adjust font size as needed
                  );
                } else {
                  return const Text('loading...');
                }
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Text(
                  getCurrentMonthName(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge, // Adjust font size as needed
                ),
              ),
            ],
            centerTitle:
                true, // Set to true if you want the title in the center
          ),
          drawer: const MyDrawer(),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GRAPH UI
                Center(
                  child: SizedBox(
                    height: 250,
                    child: FutureBuilder(
                      future: _monthlyTotalsFuture,
                      builder: (context, snapshot) {
                        // data is loaded
                        if (snapshot.connectionState == ConnectionState.done) {
                          Map<String, double> monthlyTotals =
                              snapshot.data ?? {};

                          // create the list of monthly summary

                          List<double> monthlySummary = List.generate(
                            12,
                            (index) {
                              // calculate year-month considering startMonth & index
                              int year =
                                  startYear + (startMonth + index - 1) ~/ 12;
                              int month = (startMonth + index - 1) % 12 + 1;

                              // create the key in fromat 'year-month'
                              String yearMonthKey = '$year-$month';

                              // return the total for year-month or 0.0 if non exists
                              return monthlyTotals[yearMonthKey] ?? 0.0;
                            },
                          );
                          //print(monthlySummary);
                          return MyBarGraph(
                              monthlySummary: monthlySummary,
                              startMonth: startMonth);
                        }
                        // loading..
                        else {
                          return const Center(
                            child: Text('Loading...'),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                Text(
                  'Expenses:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                // LISTVIEW OF EXPENSES
                Expanded(
                  child: ListView.builder(
                    itemCount: currentMonthExpenses.length,
                    itemBuilder: (context, index) {
                      // reverse the list to show latest item first
                      int reversedIndex =
                          currentMonthExpenses.length - 1 - index;
                      // get individual expense
                      Expense individualExpense =
                          currentMonthExpenses[reversedIndex];

                      return MyListTile(
                        title: individualExpense.name,
                        trailing: formatAmount(individualExpense.amount),
                        onDeletePressed: (context) =>
                            openDeleteBox(individualExpense),
                        onEditPressed: (context) =>
                            openEditBox(individualExpense),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // cancel button widget
  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        // pop box
        Navigator.pop(context);

        // clear controllers
        nameController.clear();
        amountController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  // save create new expense widget
  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          // pop box
          Navigator.pop(context);

          // create new expense
          Expense newExpense = Expense(
              name: nameController.text,
              amount: convertStringToDouble(amountController.text),
              date: DateTime.now());

          // add to db
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);

          // refresh graph data
          refreshData();

          // clear controllers
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  // save edit-update expense widget
  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        // save as long as at least one textfield has been changed
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          // pop box
          Navigator.pop(context);

          // create a new updated expenses
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertStringToDouble(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );

          // old expense id
          int oldId = expense.id;

          // save to db
          await context
              .read<ExpenseDatabase>()
              .updateExpense(oldId, updatedExpense);

          // refresh graph data
          refreshData();
        }
      },
      child: const Text('Save'),
    );
  }

  // delete expense button
  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        // pop box
        Navigator.pop(context);
        // delete expense from db
        await context.read<ExpenseDatabase>().deleteExpense(id);

        // refresh graph data
        refreshData();
      },
      child: const Text('Delete'),
    );
  }

  // read expenses
  @override
  void initState() {
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();

    refreshData();
    permissionHandler();
    super.initState();
  }

  void permissionHandler() async {
    await Provider.of<ExpenseDatabase>(context, listen: false)
        .requestStoragePermission(Permission.storage);
  }

  // refresh  data
  void refreshData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
    _calculateCurrentMonthTotal =
        Provider.of<ExpenseDatabase>(context, listen: false)
            .calculateCurrentMonthTotal();
  }

  void openNewExpenseBox() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('New Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // user input -> expense name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                    keyboardType: TextInputType.name,
                  ),

                  // user input -> expense amount
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(hintText: 'Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                // cancel button
                _cancelButton(),

                // save button
                _createNewExpenseButton(),
              ],
            ));
  }

  void openEditBox(Expense expense) {
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // user input -> expense name
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingName),
              keyboardType: TextInputType.name,
            ),

            // user input -> expense amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingAmount),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          // cancel button
          _cancelButton(),

          // save button
          _editExpenseButton(expense)
        ],
      ),
    );
  }

  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        actions: [
          // cancel button
          _cancelButton(),

          // save button
          _deleteExpenseButton(expense.id)
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharif 2026 Expense',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MonthListPage(),
    );
  }
}

class MonthListPage extends StatelessWidget {
  const MonthListPage({Key? key}) : super(key: key);

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sharif 2026 Expense'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: months.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(
                months[index],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonthExpensePage(month: months[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class Expense {
  String cause;
  double amount;

  Expense({required this.cause, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'cause': cause,
      'amount': amount,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      cause: map['cause'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}

class MonthExpensePage extends StatefulWidget {
  final String month;

  const MonthExpensePage({Key? key, required this.month}) : super(key: key);

  @override
  State<MonthExpensePage> createState() => _MonthExpensePageState();
}

class _MonthExpensePageState extends State<MonthExpensePage> {
  final List<Expense> expenses = [];
  final List<Expense> filteredExpenses = [];
  final List<TextEditingController> causeControllers = [];
  final List<TextEditingController> amountControllers = [];
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    await loadExpenses();
  }

  Future<void> saveExpenses() async {
    final List<String> expensesJson = expenses
        .map((expense) => jsonEncode(expense.toMap()))
        .toList();
    await prefs.setStringList('expenses_${widget.month}', expensesJson);
  }

  Future<void> loadExpenses() async {
    final List<String>? expensesJson = prefs.getStringList('expenses_${widget.month}');
    if (expensesJson != null) {
      setState(() {
        expenses.clear();
        causeControllers.clear();
        amountControllers.clear();
        for (String json in expensesJson) {
          final expense = Expense.fromMap(jsonDecode(json));
          expenses.add(expense);
          causeControllers.add(TextEditingController(text: expense.cause));
          amountControllers.add(TextEditingController(text: expense.amount == 0 ? '' : expense.amount.toString()));
        }
        filteredExpenses.clear();
        filteredExpenses.addAll(expenses);
      });
    }
  }

  void addExpense() {
    setState(() {
      expenses.add(Expense(cause: '', amount: 0));
      causeControllers.add(TextEditingController());
      amountControllers.add(TextEditingController());
      if (!isSearching) {
        filteredExpenses.add(expenses.last);
      }
    });
    saveExpenses();
  }

  void removeExpense(int index) {
    setState(() {
      final expenseToRemove = filteredExpenses[index];
      final expenseIndex = expenses.indexOf(expenseToRemove);
      expenses.remove(expenseToRemove);
      causeControllers.removeAt(expenseIndex);
      amountControllers.removeAt(expenseIndex);
      filteredExpenses.removeAt(index);
    });
    saveExpenses();
  }

  double getTotalAmount() {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  void filterExpenses(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredExpenses.clear();
        filteredExpenses.addAll(expenses);
      } else {
        filteredExpenses.clear();
        filteredExpenses.addAll(
          expenses.where((expense) =>
              expense.cause.toLowerCase().contains(query.toLowerCase())),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search expenses...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: filterExpenses,
              )
            : Text('${widget.month} Expenses'),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredExpenses.clear();
                  filteredExpenses.addAll(expenses);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Text(
                      isSearching && searchController.text.isNotEmpty
                          ? 'No expenses found'
                          : 'No expenses added yet.\nTap + to add expenses.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expenseIndex = expenses.indexOf(filteredExpenses[index]);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: causeControllers[expenseIndex],
                                  decoration: const InputDecoration(
                                    labelText: 'Expense Cause',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    expenses[expenseIndex].cause = value;
                                    saveExpenses();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: amountControllers[expenseIndex],
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    expenses[expenseIndex].amount =
                                        double.tryParse(value) ?? 0;
                                    setState(() {});
                                    saveExpenses();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeExpense(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '৳${getTotalAmount().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: addExpense,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    for (var controller in causeControllers) {
      controller.dispose();
    }
    for (var controller in amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
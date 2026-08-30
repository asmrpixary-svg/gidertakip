import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class FinanceProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  double _initialBankBalance = 0.0;
  double _currentBankBalance = 0.0;
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];

  bool _isLoading = false;

  // Filter properties
  String? _selectedCategoryFilter;
  String? _selectedPaymentMethodFilter; // 'Banka', 'Nakit', or null (All)

  double get initialBankBalance => _initialBankBalance;
  double get currentBankBalance => _currentBankBalance;
  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String? get selectedPaymentMethodFilter => _selectedPaymentMethodFilter;

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      if (_selectedCategoryFilter != null &&
          _selectedCategoryFilter!.isNotEmpty &&
          _selectedCategoryFilter != 'Tümü') {
        if (tx.category != _selectedCategoryFilter) return false;
      }
      if (_selectedPaymentMethodFilter != null &&
          _selectedPaymentMethodFilter!.isNotEmpty &&
          _selectedPaymentMethodFilter != 'Tümü') {
        if (tx.paymentMethod != _selectedPaymentMethodFilter) return false;
      }
      return true;
    }).toList();
  }

  // Monthly summary metrics (current month)
  double get thisMonthIncome {
    final now = DateTime.now();
    return _transactions.where((tx) {
      return tx.isIncome && tx.date.year == now.year && tx.date.month == now.month;
    }).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get thisMonthExpense {
    final now = DateTime.now();
    return _transactions.where((tx) {
      return tx.isExpense && tx.date.year == now.year && tx.date.month == now.month;
    }).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _initialBankBalance = await _dbHelper.getInitialBankBalance();
    _transactions = await _dbHelper.getAllTransactions();
    _currentBankBalance = _calculateCurrentBalanceFromList();

    _expenseCategories = await _dbHelper.getCategories(type: 'gider');
    _incomeCategories = await _dbHelper.getCategories(type: 'gelir');

    _isLoading = false;
    notifyListeners();
  }

  double _calculateCurrentBalanceFromList() {
    double balance = _initialBankBalance;
    for (var tx in _transactions) {
      if (tx.isBank) {
        if (tx.isIncome) {
          balance += tx.amount;
        } else if (tx.isExpense) {
          balance -= tx.amount;
        }
      }
    }
    return balance;
  }

  Future<void> updateInitialBankBalance(double newBalance) async {
    await _dbHelper.updateInitialBankBalance(newBalance);
    _initialBankBalance = newBalance;
    _currentBankBalance = _calculateCurrentBalanceFromList();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbHelper.insertTransaction(transaction);
    await loadData();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _dbHelper.updateTransaction(transaction);
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await loadData();
  }

  // Filters setup
  void setFilters({String? category, String? paymentMethod}) {
    _selectedCategoryFilter = category;
    _selectedPaymentMethodFilter = paymentMethod;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryFilter = null;
    _selectedPaymentMethodFilter = null;
    notifyListeners();
  }

  // Custom Categories
  Future<void> addCategory(String name, String type) async {
    final category = CategoryModel(name: name, type: type, isDefault: false);
    await _dbHelper.addCategory(category);
    if (type == 'gider') {
      _expenseCategories = await _dbHelper.getCategories(type: 'gider');
    } else {
      _incomeCategories = await _dbHelper.getCategories(type: 'gelir');
    }
    notifyListeners();
  }

  Future<void> deleteCategory(int id, String type) async {
    await _dbHelper.deleteCategory(id);
    if (type == 'gider') {
      _expenseCategories = await _dbHelper.getCategories(type: 'gider');
    } else {
      _incomeCategories = await _dbHelper.getCategories(type: 'gelir');
    }
    notifyListeners();
  }
}

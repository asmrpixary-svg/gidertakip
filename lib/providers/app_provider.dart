import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/fuel_log_model.dart';
import '../models/category_model.dart';
import '../models/settings_model.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  AppSettings _settings = AppSettings(bankBalance: 0.0, initialBalance: 0.0);
  List<TransactionItem> _transactions = [];
  List<FuelLog> _fuelLogs = [];
  List<CategoryItem> _categories = [];
  bool _isLoading = true;

  AppProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  AppSettings get settings => _settings;
  double get bankBalance => _settings.bankBalance;
  List<TransactionItem> get transactions => _transactions;
  List<FuelLog> get fuelLogs => _fuelLogs;
  List<CategoryItem> get categories => _categories;
  bool get isLoading => _isLoading;

  List<CategoryItem> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();

  List<CategoryItem> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();

  // Monthly summary metrics for current month
  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'income' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Fuel summary metrics
  double get totalFuelCost {
    return _fuelLogs.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  double get totalKmTraveled {
    if (_fuelLogs.length < 2) return 0.0;
    return _fuelLogs.last.odometerKm - _fuelLogs.first.odometerKm;
  }

  double? get avgCostPerKm {
    final logsWithCost = _fuelLogs.where((l) => l.costPerKm != null).toList();
    if (logsWithCost.isEmpty) return null;
    final total = logsWithCost.fold(0.0, (sum, item) => sum + item.costPerKm!);
    return total / logsWithCost.length;
  }

  double? get avgConsumptionPer100km {
    final logsWithCons =
        _fuelLogs.where((l) => l.consumptionPer100km != null).toList();
    if (logsWithCons.isEmpty) return null;
    final total =
        logsWithCons.fold(0.0, (sum, item) => sum + item.consumptionPer100km!);
    return total / logsWithCons.length;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _dbHelper.getSettings();
    _transactions = await _dbHelper.getTransactions();
    _fuelLogs = await _dbHelper.getFuelLogs();
    _categories = await _dbHelper.getCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionItem item) async {
    await _dbHelper.insertTransaction(item);
    await loadData();
  }

  Future<void> updateTransaction(
      TransactionItem oldItem, TransactionItem newItem) async {
    await _dbHelper.updateTransaction(oldItem, newItem);
    await loadData();
  }

  Future<void> deleteTransaction(TransactionItem item) async {
    await _dbHelper.deleteTransaction(item);
    await loadData();
  }

  Future<void> addFuelLog(FuelLog fuelLog, {String paymentMethod = 'bank'}) async {
    await _dbHelper.insertFuelLog(fuelLog, paymentMethod: paymentMethod);
    await loadData();
  }

  Future<void> deleteFuelLog(int id) async {
    await _dbHelper.deleteFuelLog(id);
    await loadData();
  }

  Future<void> addCategory(String name, String type) async {
    final cat = CategoryItem(name: name, type: type, isCustom: true);
    await _dbHelper.insertCategory(cat);
    await loadData();
  }

  Future<void> deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
    await loadData();
  }

  Future<void> updateInitialBalance(double balance) async {
    await _dbHelper.setInitialBalance(balance);
    await loadData();
  }

  Future<void> updateBankBalance(double balance) async {
    await _dbHelper.updateBankBalance(balance);
    await loadData();
  }
}

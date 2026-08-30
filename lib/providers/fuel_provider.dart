import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/fuel_entry_model.dart';
import 'finance_provider.dart';

class FuelProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<FuelEntryModel> _fuelEntries = []; // Reverse chronological order (newest first)
  bool _isLoading = false;

  List<FuelEntryModel> get fuelEntries => _fuelEntries;
  bool get isLoading => _isLoading;

  // Summary Metrics
  double get totalFuelExpense {
    return _fuelEntries.fold(0.0, (sum, entry) => sum + entry.totalCost);
  }

  double get averagePricePerLiter {
    if (_fuelEntries.isEmpty) return 0.0;
    double totalLiters = _fuelEntries.fold(0.0, (sum, e) => sum + e.liters);
    if (totalLiters == 0) return 0.0;
    return totalFuelExpense / totalLiters;
  }

  double get averageConsumptionPer100Km {
    final computedEntries = _fuelEntries.where((e) => e.consumptionPer100Km != null).toList();
    if (computedEntries.isEmpty) return 0.0;
    double totalConsumption = computedEntries.fold(0.0, (sum, e) => sum + e.consumptionPer100Km!);
    return totalConsumption / computedEntries.length;
  }

  double get averageCostPerKm {
    final computedEntries = _fuelEntries.where((e) => e.costPerKm != null).toList();
    if (computedEntries.isEmpty) return 0.0;
    double totalCostKm = computedEntries.fold(0.0, (sum, e) => sum + e.costPerKm!);
    return totalCostKm / computedEntries.length;
  }

  double get distanceSinceLastFill {
    if (_fuelEntries.length < 2) return 0.0;
    // _fuelEntries is ordered newest first, so index 0 is most recent, index 1 is previous
    final latest = _fuelEntries.first;
    final previous = _fuelEntries[1];
    return (latest.odometerKm - previous.odometerKm).clamp(0.0, double.infinity);
  }

  Future<void> loadFuelData() async {
    _isLoading = true;
    notifyListeners();

    _fuelEntries = await _dbHelper.getAllFuelEntries();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFuelEntry(FuelEntryModel fuelEntry, FinanceProvider financeProvider) async {
    await _dbHelper.insertFuelEntry(fuelEntry);
    await loadFuelData();
    await financeProvider.loadData();
  }

  Future<void> updateFuelEntry(FuelEntryModel fuelEntry, FinanceProvider financeProvider) async {
    await _dbHelper.updateFuelEntry(fuelEntry);
    await loadFuelData();
    await financeProvider.loadData();
  }

  Future<void> deleteFuelEntry(int id, FinanceProvider financeProvider) async {
    await _dbHelper.deleteFuelEntry(id);
    await loadFuelData();
    await financeProvider.loadData();
  }
}

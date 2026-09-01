import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/fuel_log_model.dart';
import '../models/category_model.dart';
import '../models/settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // For testing with sqflite_common_ffi or custom db instance
  DatabaseHelper.forTest(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gidertakip.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        bank_balance REAL NOT NULL DEFAULT 0.0,
        initial_balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      INSERT INTO settings (id, bank_balance, initial_balance)
      VALUES (1, 0.0, 0.0)
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed default expense categories
    final defaultExpenseCategories = [
      'Market',
      'Fatura',
      'Kira',
      'Ulaşım',
      'Yakıt',
      'Eğlence',
      'Sağlık',
      'Yatırım',
      'Diğer'
    ];
    for (var cat in defaultExpenseCategories) {
      await db.insert('categories', {
        'name': cat,
        'type': 'expense',
        'is_custom': 0,
      });
    }

    // Seed default income categories
    final defaultIncomeCategories = ['Maaş', 'Ek Gelir', 'Diğer'];
    for (var cat in defaultIncomeCategories) {
      await db.insert('categories', {
        'name': cat,
        'type': 'income',
        'is_custom': 0,
      });
    }

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        fuel_log_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE fuel_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        odometer_km REAL NOT NULL,
        liters REAL NOT NULL,
        total_cost REAL NOT NULL,
        station_note TEXT,
        cost_per_km REAL,
        consumption_per_100km REAL,
        transaction_id INTEGER
      )
    ''');
  }

  // --- Settings CRUD ---
  Future<AppSettings> getSettings() async {
    final db = await instance.database;
    final result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) {
      return AppSettings.fromMap(result.first);
    }
    return AppSettings(bankBalance: 0.0, initialBalance: 0.0);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await instance.database;
    await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateBankBalance(double newBalance) async {
    final db = await instance.database;
    await db.update(
      'settings',
      {'bank_balance': newBalance},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> setInitialBalance(double initialBalance) async {
    final db = await instance.database;
    // Calculate new current balance relative to diff or set initial balance
    final current = await getSettings();
    final diff = initialBalance - current.initialBalance;
    final newBankBalance = current.bankBalance + diff;

    await db.update(
      'settings',
      {
        'initial_balance': initialBalance,
        'bank_balance': newBankBalance,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // --- Categories CRUD ---
  Future<List<CategoryItem>> getCategories({String? type}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps;
    if (type != null) {
      maps = await db.query('categories', where: 'type = ?', whereArgs: [type]);
    } else {
      maps = await db.query('categories');
    }
    return maps.map((map) => CategoryItem.fromMap(map)).toList();
  }

  Future<int> insertCategory(CategoryItem category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ? AND is_custom = 1', whereArgs: [id]);
  }

  // --- Transactions CRUD ---
  Future<int> insertTransaction(TransactionItem item) async {
    final db = await instance.database;
    final id = await db.insert('transactions', item.toMap());

    // Update bank balance if payment method is bank
    if (item.paymentMethod == 'bank') {
      final settings = await getSettings();
      double newBalance = settings.bankBalance;
      if (item.type == 'income') {
        newBalance += item.amount;
      } else {
        newBalance -= item.amount;
      }
      await updateBankBalance(newBalance);
    }

    return id;
  }

  Future<List<TransactionItem>> getTransactions() async {
    final db = await instance.database;
    final maps = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return maps.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<int> updateTransaction(TransactionItem oldItem, TransactionItem newItem) async {
    final db = await instance.database;

    // Revert old transaction bank balance effect
    final settings = await getSettings();
    double newBalance = settings.bankBalance;
    if (oldItem.paymentMethod == 'bank') {
      if (oldItem.type == 'income') {
        newBalance -= oldItem.amount;
      } else {
        newBalance += oldItem.amount;
      }
    }

    // Apply new transaction bank balance effect
    if (newItem.paymentMethod == 'bank') {
      if (newItem.type == 'income') {
        newBalance += newItem.amount;
      } else {
        newBalance -= newItem.amount;
      }
    }

    await updateBankBalance(newBalance);

    return await db.update(
      'transactions',
      newItem.toMap(),
      where: 'id = ?',
      whereArgs: [newItem.id],
    );
  }

  Future<int> deleteTransaction(TransactionItem item) async {
    final db = await instance.database;

    // Revert bank balance effect
    if (item.paymentMethod == 'bank') {
      final settings = await getSettings();
      double newBalance = settings.bankBalance;
      if (item.type == 'income') {
        newBalance -= item.amount;
      } else {
        newBalance += item.amount;
      }
      await updateBankBalance(newBalance);
    }

    // If linked to a fuel log, delete fuel log as well if needed
    if (item.fuelLogId != null) {
      await db.delete('fuel_logs', where: 'id = ?', whereArgs: [item.fuelLogId]);
    }

    return await db.delete('transactions', where: 'id = ?', whereArgs: [item.id]);
  }

  // --- Fuel Logs CRUD ---
  Future<int> insertFuelLog(FuelLog fuelLog, {String paymentMethod = 'bank'}) async {
    final db = await instance.database;

    // Get previous log ordered by odometer
    final logs = await getFuelLogs();
    FuelLog? prevLog;
    for (var l in logs) {
      if (l.odometerKm < fuelLog.odometerKm) {
        if (prevLog == null || l.odometerKm > prevLog.odometerKm) {
          prevLog = l;
        }
      }
    }

    double? costPerKm;
    double? consumptionPer100km;

    if (prevLog != null) {
      final distance = fuelLog.odometerKm - prevLog.odometerKm;
      if (distance > 0) {
        costPerKm = fuelLog.totalCost / distance;
        consumptionPer100km = (fuelLog.liters / distance) * 100;
      }
    }

    final calculatedLog = fuelLog.copyWith(
      costPerKm: costPerKm,
      consumptionPer100km: consumptionPer100km,
    );

    // 1. Insert transaction into transactions list under "Yakıt" category
    final transactionId = await insertTransaction(
      TransactionItem(
        type: 'expense',
        amount: calculatedLog.totalCost,
        category: 'Yakıt',
        paymentMethod: paymentMethod,
        date: calculatedLog.date,
        note: calculatedLog.stationNote ?? 'Yakıt Alımı (${calculatedLog.odometerKm} km)',
      ),
    );

    final finalLog = calculatedLog.copyWith(transactionId: transactionId);
    final fuelLogId = await db.insert('fuel_logs', finalLog.toMap());

    // Update transaction with fuelLogId
    await db.update(
      'transactions',
      {'fuel_log_id': fuelLogId},
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    // Recalculate subsequent fuel logs metrics
    await recalculateFuelLogMetrics();

    return fuelLogId;
  }

  Future<List<FuelLog>> getFuelLogs() async {
    final db = await instance.database;
    final maps = await db.query('fuel_logs', orderBy: 'odometer_km ASC');
    return maps.map((map) => FuelLog.fromMap(map)).toList();
  }

  Future<void> recalculateFuelLogMetrics() async {
    final db = await instance.database;
    final logs = await getFuelLogs(); // sorted by odometer_km ASC

    for (int i = 0; i < logs.length; i++) {
      final current = logs[i];
      double? costPerKm;
      double? consumptionPer100km;

      if (i > 0) {
        final prev = logs[i - 1];
        final distance = current.odometerKm - prev.odometerKm;
        if (distance > 0) {
          costPerKm = current.totalCost / distance;
          consumptionPer100km = (current.liters / distance) * 100;
        }
      }

      await db.update(
        'fuel_logs',
        {
          'cost_per_km': costPerKm,
          'consumption_per_100km': consumptionPer100km,
        },
        where: 'id = ?',
        whereArgs: [current.id],
      );
    }
  }

  Future<int> deleteFuelLog(int id) async {
    final db = await instance.database;
    final maps = await db.query('fuel_logs', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final log = FuelLog.fromMap(maps.first);
      if (log.transactionId != null) {
        final txMaps = await db.query('transactions', where: 'id = ?', whereArgs: [log.transactionId]);
        if (txMaps.isNotEmpty) {
          final tx = TransactionItem.fromMap(txMaps.first);
          // Delete transaction (which handles bank balance revert)
          await db.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);
          if (tx.paymentMethod == 'bank') {
            final settings = await getSettings();
            await updateBankBalance(settings.bankBalance + tx.amount);
          }
        }
      }
    }
    final result = await db.delete('fuel_logs', where: 'id = ?', whereArgs: [id]);
    await recalculateFuelLogMetrics();
    return result;
  }
}

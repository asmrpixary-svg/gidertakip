import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import '../models/fuel_entry_model.dart';
import '../models/category_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gidertakip.db');
    return _database!;
  }

  // Factory constructor or method for test overrides (e.g., FFI SQLite in unit tests)
  static void setMockDatabase(Database db) {
    _database = db;
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
    // 1. Settings Table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Default starting balance = 0.0
    await db.insert('settings', {'key': 'initial_bank_balance', 'value': '0.0'});

    // 2. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Default expense categories
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
        'type': 'gider',
        'is_default': 1,
      });
    }

    // Default income categories
    final defaultIncomeCategories = ['Maaş', 'Ek Gelir', 'Diğer'];
    for (var cat in defaultIncomeCategories) {
      await db.insert('categories', {
        'name': cat,
        'type': 'gelir',
        'is_default': 1,
      });
    }

    // 3. Fuel Entries Table
    await db.execute('''
      CREATE TABLE fuel_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        odometer_km REAL NOT NULL,
        liters REAL NOT NULL,
        total_cost REAL NOT NULL,
        station_note TEXT,
        payment_method TEXT NOT NULL
      )
    ''');

    // 4. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        fuel_entry_id INTEGER,
        FOREIGN KEY (fuel_entry_id) REFERENCES fuel_entries (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- SETTINGS / BALANCE METHODS ---

  Future<double> getInitialBankBalance() async {
    final db = await instance.database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: ['initial_bank_balance']);
    if (res.isNotEmpty) {
      return double.tryParse(res.first['value'] as String) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> updateInitialBankBalance(double newBalance) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': 'initial_bank_balance', 'value': newBalance.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> calculateCurrentBankBalance() async {
    final initialBalance = await getInitialBankBalance();
    final db = await instance.database;

    final res = await db.query('transactions');
    final transactions = res.map((map) => TransactionModel.fromMap(map)).toList();

    double balance = initialBalance;
    for (var tx in transactions) {
      // Only transactions with payment method 'Banka' affect the bank balance
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

  // --- CATEGORIES METHODS ---

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> res;
    if (type != null) {
      res = await db.query('categories', where: 'type = ?', whereArgs: [type], orderBy: 'name ASC');
    } else {
      res = await db.query('categories', orderBy: 'name ASC');
    }
    return res.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<int> addCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ? AND is_default = 0', whereArgs: [id]);
  }

  // --- TRANSACTIONS METHODS ---

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final res = await db.query('transactions', orderBy: 'date DESC');
    return res.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;

    // Check if linked to a fuel entry
    final res = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      final tx = TransactionModel.fromMap(res.first);
      if (tx.fuelEntryId != null) {
        // Also delete the fuel entry to keep sync
        await db.delete('fuel_entries', where: 'id = ?', whereArgs: [tx.fuelEntryId]);
      }
    }

    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- FUEL ENTRIES METHODS ---

  Future<int> insertFuelEntry(FuelEntryModel fuelEntry) async {
    final db = await instance.database;
    int fuelId = 0;

    await db.transaction((txn) async {
      fuelId = await txn.insert('fuel_entries', fuelEntry.toMap());

      // Automatically create corresponding "Yakıt" expense transaction
      final tx = TransactionModel(
        type: 'gider',
        amount: fuelEntry.totalCost,
        category: 'Yakıt',
        paymentMethod: fuelEntry.paymentMethod,
        date: fuelEntry.date,
        note: fuelEntry.stationNote != null && fuelEntry.stationNote!.isNotEmpty
            ? '${fuelEntry.odometerKm.toStringAsFixed(0)} km - ${fuelEntry.stationNote}'
            : '${fuelEntry.odometerKm.toStringAsFixed(0)} km',
        fuelEntryId: fuelId,
      );

      await txn.insert('transactions', tx.toMap());
    });

    return fuelId;
  }

  Future<List<FuelEntryModel>> getAllFuelEntries() async {
    final db = await instance.database;
    // Order by odometer reading ascending to calculate consecutive fuel metrics
    final res = await db.query('fuel_entries', orderBy: 'odometer_km ASC, date ASC');
    final rawEntries = res.map((e) => FuelEntryModel.fromMap(e)).toList();

    List<FuelEntryModel> computed = [];
    for (int i = 0; i < rawEntries.length; i++) {
      final current = rawEntries[i];
      if (i == 0) {
        computed.add(current);
      } else {
        final previous = rawEntries[i - 1];
        final distance = current.odometerKm - previous.odometerKm;

        double? costPerKm;
        double? consumptionPer100Km;

        if (distance > 0) {
          costPerKm = current.totalCost / distance; // TL/km
          consumptionPer100Km = (current.liters / distance) * 100; // L/100km
        }

        computed.add(current.copyWith(
          costPerKm: costPerKm,
          consumptionPer100Km: consumptionPer100Km,
        ));
      }
    }

    // Return in reverse chronological order (newest first) for UI list
    return computed.reversed.toList();
  }

  Future<void> updateFuelEntry(FuelEntryModel fuelEntry) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'fuel_entries',
        fuelEntry.toMap(),
        where: 'id = ?',
        whereArgs: [fuelEntry.id],
      );

      // Update linked transaction
      final res = await txn.query('transactions', where: 'fuel_entry_id = ?', whereArgs: [fuelEntry.id]);
      if (res.isNotEmpty) {
        final existingTx = TransactionModel.fromMap(res.first);
        final updatedTx = existingTx.copyWith(
          amount: fuelEntry.totalCost,
          paymentMethod: fuelEntry.paymentMethod,
          date: fuelEntry.date,
          note: fuelEntry.stationNote != null && fuelEntry.stationNote!.isNotEmpty
              ? '${fuelEntry.odometerKm.toStringAsFixed(0)} km - ${fuelEntry.stationNote}'
              : '${fuelEntry.odometerKm.toStringAsFixed(0)} km',
        );
        await txn.update(
          'transactions',
          updatedTx.toMap(),
          where: 'id = ?',
          whereArgs: [updatedTx.id],
        );
      }
    });
  }

  Future<void> deleteFuelEntry(int id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'fuel_entry_id = ?', whereArgs: [id]);
      await txn.delete('fuel_entries', where: 'id = ?', whereArgs: [id]);
    });
  }
}

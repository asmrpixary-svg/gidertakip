import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gidertakip/database/database_helper.dart';
import 'package:gidertakip/models/transaction_model.dart';
import 'package:gidertakip/models/fuel_log_model.dart';
import 'package:gidertakip/models/category_model.dart';
import 'package:gidertakip/models/settings_model.dart';
import 'package:gidertakip/providers/app_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('App Tests & Database Helper', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late AppProvider provider;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE settings (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              bank_balance REAL NOT NULL DEFAULT 0.0,
              initial_balance REAL NOT NULL DEFAULT 0.0
            )
          ''');
          await db.execute('''
            INSERT INTO settings (id, bank_balance, initial_balance)
            VALUES (1, 1000.0, 1000.0)
          ''');

          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              is_custom INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.insert('categories', {'name': 'Market', 'type': 'expense', 'is_custom': 0});
          await db.insert('categories', {'name': 'Yakıt', 'type': 'expense', 'is_custom': 0});
          await db.insert('categories', {'name': 'Maaş', 'type': 'income', 'is_custom': 0});

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
        },
      );

      dbHelper = DatabaseHelper.forTest(db);
      provider = AppProvider(dbHelper: dbHelper);
      await provider.loadData();
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial settings load correctly', () async {
      expect(provider.bankBalance, equals(1000.0));
      expect(provider.categories.length, equals(3));
    });

    test('Bank income transaction increases bank balance', () async {
      final tx = TransactionItem(
        type: 'income',
        amount: 500.0,
        category: 'Maaş',
        paymentMethod: 'bank',
        date: DateTime.now(),
      );

      await provider.addTransaction(tx);
      expect(provider.bankBalance, equals(1500.0));
      expect(provider.transactions.length, equals(1));
    });

    test('Cash transaction does NOT alter bank balance', () async {
      final tx = TransactionItem(
        type: 'expense',
        amount: 200.0,
        category: 'Market',
        paymentMethod: 'cash',
        date: DateTime.now(),
      );

      await provider.addTransaction(tx);
      expect(provider.bankBalance, equals(1000.0));
      expect(provider.transactions.length, equals(1));
    });

    test('Bank expense transaction decreases bank balance', () async {
      final tx = TransactionItem(
        type: 'expense',
        amount: 300.0,
        category: 'Market',
        paymentMethod: 'bank',
        date: DateTime.now(),
      );

      await provider.addTransaction(tx);
      expect(provider.bankBalance, equals(700.0));
    });

    test('Fuel log insertion calculates TL/km, L/100km and syncs expense', () async {
      // First fuel log at 10,000 km
      final log1 = FuelLog(
        date: DateTime.now().subtract(const Duration(days: 7)),
        odometerKm: 10000.0,
        liters: 40.0,
        totalCost: 1200.0,
      );
      await provider.addFuelLog(log1, paymentMethod: 'bank');

      // First log won't have distance metrics since no previous log
      expect(provider.fuelLogs.first.costPerKm, isNull);
      expect(provider.bankBalance, equals(1000.0 - 1200.0)); // -200

      // Second fuel log at 10,500 km (500 km distance) with 30 Liters for 1000 TL
      final log2 = FuelLog(
        date: DateTime.now(),
        odometerKm: 10500.0,
        liters: 30.0,
        totalCost: 1000.0,
      );
      await provider.addFuelLog(log2, paymentMethod: 'bank');

      final updatedLogs = provider.fuelLogs;
      expect(updatedLogs.length, equals(2));

      final secondLog = updatedLogs[1];
      // distance = 500 km
      // costPerKm = 1000 TL / 500 km = 2.0 TL/km
      expect(secondLog.costPerKm, equals(2.0));
      // consumptionPer100km = (30 L / 500 km) * 100 = 6.0 L/100km
      expect(secondLog.consumptionPer100km, equals(6.0));

      // Auto expense created in transactions
      final fuelTransactions = provider.transactions.where((t) => t.category == 'Yakıt').toList();
      expect(fuelTransactions.length, equals(2));
    });

    test('Adding and deleting custom categories', () async {
      await provider.addCategory('Spor', 'expense');
      expect(provider.expenseCategories.any((c) => c.name == 'Spor'), isTrue);

      final customCat = provider.expenseCategories.firstWhere((c) => c.name == 'Spor');
      await provider.deleteCategory(customCat.id!);
      expect(provider.expenseCategories.any((c) => c.name == 'Spor'), isFalse);
    });
  });
}

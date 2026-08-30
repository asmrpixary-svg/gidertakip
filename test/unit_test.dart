import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gidertakip/database/database_helper.dart';
import 'package:gidertakip/models/transaction_model.dart';
import 'package:gidertakip/models/fuel_entry_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
        await db.insert('settings', {'key': 'initial_bank_balance', 'value': '1000.0'});

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0
          )
        ''');

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
      },
    );

    DatabaseHelper.setMockDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Bank Balance Calculation Tests', () {
    test('Initial balance is correctly returned', () async {
      final initial = await DatabaseHelper.instance.getInitialBankBalance();
      expect(initial, equals(1000.0));
    });

    test('Banka income increases balance, Nakit income does not', () async {
      // Add 500 Banka income
      await DatabaseHelper.instance.insertTransaction(TransactionModel(
        type: 'gelir',
        amount: 500.0,
        category: 'Maaş',
        paymentMethod: 'Banka',
        date: DateTime.now(),
      ));

      // Add 200 Nakit income
      await DatabaseHelper.instance.insertTransaction(TransactionModel(
        type: 'gelir',
        amount: 200.0,
        category: 'Ek Gelir',
        paymentMethod: 'Nakit',
        date: DateTime.now(),
      ));

      final balance = await DatabaseHelper.instance.calculateCurrentBankBalance();
      expect(balance, equals(1500.0)); // 1000 + 500
    });

    test('Banka expense and Yatırım deducts balance, Nakit expense does not', () async {
      // Add 300 Banka expense (Market)
      await DatabaseHelper.instance.insertTransaction(TransactionModel(
        type: 'gider',
        amount: 300.0,
        category: 'Market',
        paymentMethod: 'Banka',
        date: DateTime.now(),
      ));

      // Add 200 Banka Yatırım expense
      await DatabaseHelper.instance.insertTransaction(TransactionModel(
        type: 'gider',
        amount: 200.0,
        category: 'Yatırım',
        paymentMethod: 'Banka',
        date: DateTime.now(),
      ));

      // Add 150 Nakit expense
      await DatabaseHelper.instance.insertTransaction(TransactionModel(
        type: 'gider',
        amount: 150.0,
        category: 'Fatura',
        paymentMethod: 'Nakit',
        date: DateTime.now(),
      ));

      final balance = await DatabaseHelper.instance.calculateCurrentBankBalance();
      expect(balance, equals(500.0)); // 1000 - 300 - 200
    });
  });

  group('Fuel Entry & Sync Tests', () {
    test('Adding fuel entry automatically creates a transaction and calculates efficiency metrics', () async {
      final entry1 = FuelEntryModel(
        date: DateTime.now().subtract(const Duration(days: 5)),
        odometerKm: 50000,
        liters: 40.0,
        totalCost: 1600.0,
        stationNote: 'Shell',
        paymentMethod: 'Banka',
      );

      await DatabaseHelper.instance.insertFuelEntry(entry1);

      // Check transaction created
      final txs = await DatabaseHelper.instance.getAllTransactions();
      expect(txs.length, equals(1));
      expect(txs.first.category, equals('Yakıt'));
      expect(txs.first.amount, equals(1600.0));
      expect(txs.first.paymentMethod, equals('Banka'));

      // Check balance updated (1000 - 1600 = -600)
      final balance1 = await DatabaseHelper.instance.calculateCurrentBankBalance();
      expect(balance1, equals(-600.0));

      // Add second fuel entry
      final entry2 = FuelEntryModel(
        date: DateTime.now(),
        odometerKm: 50500, // 500 km driven
        liters: 30.0,
        totalCost: 1200.0,
        stationNote: 'Opet',
        paymentMethod: 'Banka',
      );

      await DatabaseHelper.instance.insertFuelEntry(entry2);

      final fuelList = await DatabaseHelper.instance.getAllFuelEntries();
      expect(fuelList.length, equals(2));

      // Most recent entry is index 0
      final latest = fuelList.first;
      expect(latest.odometerKm, equals(50500));

      // Distance = 500 km, Liters = 30 L
      // Consumption = (30 / 500) * 100 = 6.0 L/100km
      // Cost per km = 1200 / 500 = 2.40 TL/km
      expect(latest.consumptionPer100Km, closeTo(6.0, 0.01));
      expect(latest.costPerKm, closeTo(2.40, 0.01));
    });
  });
}

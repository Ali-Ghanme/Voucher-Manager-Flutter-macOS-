import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/app_constants.dart';

/// Owns the single SQLite database connection for the app and defines
/// the schema. Uses `sqflite_common_ffi` so it works natively on macOS
/// desktop (the standard `sqflite` package is mobile-only).
///
/// This is intentionally a thin wrapper around raw SQL - the Repository
/// layer above it is where business rules (atomic dispense, undo, etc.)
/// live. Keeping SQL isolated here makes it easy to swap to Isar later
/// if desired, without touching business logic.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Required bootstrap for sqflite_common_ffi on desktop platforms.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String dbDir = p.join(appSupportDir.path, 'voucher_manager');
    await Directory(dbDir).create(recursive: true);
    final String dbPath = p.join(dbDir, AppConstants.dbName);

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onConfigure: (db) async {
          // Enforce FK constraints and enable WAL for better concurrent
          // read/write behaviour during bulk dispense transactions.
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
        },
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBatches} (
        id TEXT PRIMARY KEY,
        fileName TEXT NOT NULL,
        totalVouchers INTEGER NOT NULL DEFAULT 0,
        soldVouchers INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        isCurrentActive INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableVouchers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchId TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusAvailable}',
        soldAt TEXT,
        transactionId TEXT,
        FOREIGN KEY (batchId) REFERENCES ${AppConstants.tableBatches} (id) ON DELETE CASCADE
      )
    ''');

    // Speeds up the hot-path query: "next N available vouchers in batch X"
    await db.execute('''
      CREATE INDEX idx_vouchers_batch_status
      ON ${AppConstants.tableVouchers} (batchId, status)
    ''');

    await db.execute('''
      CREATE INDEX idx_vouchers_transaction
      ON ${AppConstants.tableVouchers} (transactionId)
    ''');

    // Prevents accidentally importing the exact same username twice
    // within the same batch (duplicate PDF rows / OCR artifacts).
    await db.execute('''
      CREATE UNIQUE INDEX idx_vouchers_unique_in_batch
      ON ${AppConstants.tableVouchers} (batchId, username, password)
    ''');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

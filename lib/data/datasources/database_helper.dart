import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/app_constants.dart';

/// Owns the single SQLite database connection for the app and defines
/// the schema. Uses `sqflite_common_ffi` on desktop (macOS/Windows/Linux)
/// and standard `sqflite` on mobile (Android/iOS).
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
    final bool isDesktop =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    final String dbPath;
    if (Platform.isAndroid || Platform.isIOS) {
      String basePath;
      try {
        basePath = await sqflite.getDatabasesPath();
      } catch (_) {
        final dir = await getApplicationDocumentsDirectory();
        basePath = dir.path;
      }
      dbPath = p.join(basePath, AppConstants.dbName);
    } else {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final String dbDir = p.join(appSupportDir.path, 'voucher_manager');
      await Directory(dbDir).create(recursive: true);
      dbPath = p.join(dbDir, AppConstants.dbName);
    }

    if (isDesktop) {
      // Required bootstrap for sqflite_common_ffi on desktop platforms.
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      return databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
        ),
      );
    } else {
      // Standard mobile openDatabase without FFI invocation
      return sqflite.openDatabase(
        dbPath,
        version: AppConstants.dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    // استخدام rawQuery بدلاً من execute عند تنفيذ أمر PRAGMA journal_mode
    await db.rawQuery('PRAGMA journal_mode = WAL;');

    // تفعيل الـ Foreign Keys
    await db.execute('PRAGMA foreign_keys = ON;');
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

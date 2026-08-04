import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<void> Function()? onDataChanged;

  Future<void> notifyDataChanged() async {
    final callback = onDataChanged;
    if (callback != null) {
      try {
        await callback();
      } catch (_) {
        // ignore sync errors
      }
    }
  }

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<String> get dbPath async {
    final dir = await getDatabasesPath();
    return p.join(dir, AppConstants.dbFileName);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbFileName);
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE points_transactions ADD COLUMN source TEXT NOT NULL DEFAULT 'user'");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        points INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        points_cost INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        emoji TEXT NOT NULL DEFAULT '🎁',
        color INTEGER NOT NULL DEFAULT 4280189157,
        status TEXT NOT NULL DEFAULT 'active',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE points_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        source TEXT NOT NULL DEFAULT 'user',
        note TEXT,
        operator_id INTEGER,
        created_at INTEGER NOT NULL,
        reviewed_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE redemption_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        total_cost INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        note TEXT,
        operator_id INTEGER,
        created_at INTEGER NOT NULL,
        reviewed_at INTEGER,
        points_tx_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (item_id) REFERENCES items(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_pts_user ON points_transactions(user_id)');
    await db.execute('CREATE INDEX idx_pts_status ON points_transactions(status)');
    await db.execute('CREATE INDEX idx_red_user ON redemption_requests(user_id)');
    await db.execute('CREATE INDEX idx_red_status ON redemption_requests(status)');
  }
}

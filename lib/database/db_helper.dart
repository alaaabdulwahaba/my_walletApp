import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/card_model.dart';
import '../models/user_model.dart';

class DbHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), 'wallet_app.db');
    return await openDatabase(
      path,
      version: 3, // Increment version for card balance, cardType, and transaction updates
      onCreate: (db, version) async {
        // جدول المعاملات
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            amount REAL,
            note TEXT,
            date TEXT,
            type TEXT,
            cardId INTEGER,
            paymentMethod TEXT
          )
        ''');

        // جدول الكروت
        await db.execute('''
          CREATE TABLE cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cardNumber TEXT,
            pin TEXT,
            holderName TEXT,
            balance REAL DEFAULT 0.0,
            cardType TEXT
          )
        ''');

        // جدول المستخدمين
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            profileImage TEXT,
            password TEXT
          )
        ''');

        // Insert default user for testing
        await db.insert('users', {
          'name': 'Enjelin Morgeana',
          'email': 'enjelin@mail.com',
          'profileImage': '',
          'password': 'password123',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              email TEXT,
              profileImage TEXT,
              password TEXT
            )
          ''');
          await db.insert('users', {
            'name': 'Enjelin Morgeana',
            'email': 'enjelin@mail.com',
            'profileImage': '',
            'password': 'password123',
          });
        }
        if (oldVersion < 3) {
          // Add new columns to cards table
          try {
            await db.execute('ALTER TABLE cards ADD COLUMN balance REAL DEFAULT 0.0');
            await db.execute('ALTER TABLE cards ADD COLUMN cardType TEXT DEFAULT "Normal Bank Card"');
          } catch (e) {
            // Column might already exist
          }
          // Add new columns to transactions table
          try {
            await db.execute('ALTER TABLE transactions ADD COLUMN cardId INTEGER');
            await db.execute('ALTER TABLE transactions ADD COLUMN paymentMethod TEXT DEFAULT "Cash"');
          } catch (e) {
            // Column might already exist
          }
        }
      },
    );
  }

  // --- دوال التعامل مع المعاملات (موجودة سابقاً) ---
  Future<int> insertTransaction(TransactionModel transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  // --- دوال التعامل مع الكروت (الجديدة) ---
  Future<int> insertCard(CardModel card) async {
    Database db = await database;
    return await db.insert('cards', card.toMap());
  }

  Future<List<CardModel>> getAllCards() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('cards');
    return List.generate(maps.length, (i) => CardModel.fromMap(maps[i]));
  }

  Future<CardModel?> getCardById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CardModel.fromMap(maps.first);
  }

  Future<int> updateCard(CardModel card) async {
    Database db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<List<TransactionModel>> getTransactionsByCardId(int cardId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'cardId = ?',
      whereArgs: [cardId],
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> deleteCard(int id) async {
    Database db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- دوال التعامل مع المستخدمين ---
  Future<int> insertUser(UserModel user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUser(UserModel user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  // Delete transaction
  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
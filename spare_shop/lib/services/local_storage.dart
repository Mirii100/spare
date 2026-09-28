import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  Database? _db;
  Directory? directory;

  Future<Database> initDb() async {
    if (_db != null) return _db!;
    directory = await getApplicationDocumentsDirectory();
    final path = join(directory!.path, 'spares.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        cost REAL NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 5,
        quantity INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        customer_id INTEGER,
        profit REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_lines (
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY(sale_id) REFERENCES sales(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        vehicle_reg TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        reason TEXT,
        date TEXT NOT NULL,
        user TEXT NOT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO products (name, code, cost, price, min_stock, quantity)
      VALUES ('Fielder brake pad set', 'FP-001', 2000, 4500, 5, 10)
    ''');
    await db.execute('''
      INSERT INTO products (name, code, cost, price, min_stock, quantity)
      VALUES ('Oil filter', 'OF-002', 800, 1500, 10, 25)
    ''');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) {}

  Future<List<Product>> getProducts() async {
    final List<Map<String, dynamic>> maps = await _db!.query('products');
    return maps.map((m) => Product(
      id: m['id'] as int,
      name: m['name'] as String,
      code: m['code'] as String?,
      cost: (m['cost'] as num).toDouble(),
      price: (m['price'] as num).toDouble(),
      minStock: m['min_stock'] as int,
      quantity: m['quantity'] as int,
    )).toList();
  }

  Future<void> upsertProduct(Product p) async {
    final db = await initDb();
    await db.insertOrReplace('products', {
      'id': p.id,
      'name': p.name,
      'code': p.code,
      'cost': p.cost,
      'price': p.price,
      'min_stock': p.minStock,
      'quantity': p.quantity,
    });
  }

  Future<int> insertSale(Sale s) async {
    final db = await initDb();
    final profit = s.profit;
    final id = await db.insert('sales', {
      'date': s.date.toIso8601String(),
      'customer_id': s.customer.id,
      'profit': profit,
    });

    for (final line in s.lines) {
      await db.insert('sale_lines', {
        'sale_id': id,
        'product_id': line.product.id,
        'quantity': line.quantity,
        'price': line.priceAtSale,
      });

      final prod = await db.query('products', where: 'id = ?', whereArgs: [line.product.id]);
      if (prod.isNotEmpty) {
        final p = Product(
          id: prod.first['id'] as int,
          name: prod.first['name'] as String,
          code: prod.first['code'] as String?,
          cost: (prod.first['cost'] as num).toDouble(),
          price: (prod.first['price'] as num).toDouble(),
          minStock: prod.first['min_stock'] as int,
          quantity: (prod.first['quantity'] as int) - line.quantity,
        );
        await upsertProduct(p);
      }
    }
    return id;
  }

  Future<List<Customer>> getCustomers() async {
    final List<Map<String, dynamic>> maps = await _db!.query('customers');
    return maps.map((m) => Customer(
      id: m['id'] as int,
      name: m['name'] as String,
      vehicleReg: m['vehicle_reg'] as String?,
    )).toList();
  }

  Future<void> upsertCustomer(Customer c) async {
    final db = await initDb();
    await db.insert('customers', {
      'name': c.name,
      'vehicle_reg': c.vehicleReg,
    });
  }

  Future<void> addMovement(StockMovement m) async {
    final db = await initDb();
    await db.insert('stock_movements', {
      'type': m.type.toString().split('.').last,
      'product_id': m.product.id,
      'qty': m.quantity,
      'reason': m.reason,
      'date': m.date.toIso8601String(),
      'user': m.user,
    });
  }

  Future<void> markSynced(int recordId, String table) async {
    final db = await initDb();
    await db.rawUpdate('UPDATE $table SET synced = 1 WHERE id = ?', [recordId]);
  }
}
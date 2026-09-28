import 'package:flutter/material.dart';
import 'package:spares_app/models.dart';
import 'package:spares_app/services/local_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late LocalStorage _storage;
  List<Product> _products = [];
  double _totalProfit = 0;
  int _totalSales = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorage();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await _storage.getProducts();
    setState(() {
      _products = products;
      _lowStockCount = products.where((p) => p.quantity <= p.minStock).length;
    });

    // Compute total sales and profit from DB
    final List<Map<String, dynamic>> sales = await _storage.getSalesRecords();
    setState(() {
      _totalSales = sales.length;
      for (final s in sales) {
        _totalProfit += (s['profit'] as num).toDouble();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKPICard(
                title: 'Total Sales',
                value: _totalSales.toString(),
                icon: Icons.shopping_cart,
                color: Colors.indigo,
              ),
              const SizedBox(height: 12),
              _buildKPICard(
                title: 'Total Profit',
                value: 'KSh ${_totalProfit.toStringAsFix(0)}',
                icon: Icons.money,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildKPICard(
                title: 'Low Stock Items',
                value: _lowStockCount.toString(),
                icon: Icons.warning_amber,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._products.map((p) => _productTile(p)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children[
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productTile(Product p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(p.name),
        subtitle: Text('Code: ${p.code} | Stock: ${p.quantity} (min: ${p.minStock})'),
        trailing: p.quantity <= p.minStock
            ? const Icon(Icons.warning_amber, color: Colors.red)
            : null,
      ),
    );
  }
}
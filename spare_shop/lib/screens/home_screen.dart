import 'package:flutter/material.dart';
import 'package:spares_app/models.dart';
import 'package:spares_app/services/local_storage.dart';
import 'package:spares_app/services/voice_service.dart';
import 'sale_screen.dart';
import 'statement_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocalStorage _storage;
  late VoiceService _voice;
  List<Product> _products = [];
  Customer? _customer;
  double _todaySales = 0;
  int _syncBadge = 0;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorage();
    _voice = VoiceService();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await _storage.getProducts();
    setState(() => _products = products);
    final custs = await _storage.getCustomers();
    setState(() => _customer = custs.isNotEmpty ? custs.first : null);
  }

  void _startVoice() async {
    _voice.startListening((result) {
      // Simple parser: expect "Customer Name item qty price"
      // For demo we just show a snack and navigate to sale screen with placeholder
      final text = result.trim();
      if (text.isNotEmpty) {
        // Very naive extraction
        final parts = text.split(' ');
        if (parts.length >= 4) {
          final name = parts.sublist(0, parts.length - 3).join(' ');
          final itemName = parts[parts.length - 3];
          final qty = int.tryParse(parts[parts.length - 2]) ?? 1;
          final price = double.tryParse(parts.last) ?? 0.0;
          // Find product
          final prod = _products.firstWhere((p) => p.name == itemName || p.code == itemName, orElse: () => Product(id: 0, name: itemName, code: '', cost: 0, price: 0, minStock: 5, quantity: 0));
          // Create a simple sale
          final sale = Sale(
            id: DateTime.now().millisecondsSinceEpoch,
            date: DateTime.now(),
            customer: Customer(id: _customer?.id ?? 0, name: name),
            lines: [SaleLine(product: prod, quantity: qty, priceAtSale: price)],
            payments: {'cash': 0, 'mpesa': 0, 'credit': 0},
            profit: (price - prod.cost) * qty,
          );
          _navigateToSale(sale);
        }
      }
    });
  }

  void _navigateToSale(Sale sale) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SaleScreen(sale: sale, products: _products, onSave: _handleSave)),
    );
    if (result == true) _loadData();
  }

  void _handleSave() {
    // sync pending, etc.
    setState(() => _syncBadge = (_syncBadge + 1) % 10);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved. Sync pending.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spare Shop')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Today sales: KSh $_todaySales', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.voice_off),
              label: const Text('Voice Sale Entry'),
              onPressed: _startVoice,
            ),
            const SizedBox(height: 24),
            const Text('Quick actions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToSale(Sale(
                    id: DateTime.now().millisecondsSinceEpoch,
                    date: DateTime.now(),
                    customer: _customer ?? Customer(id: 0, name: ''),
                    lines: [],
                    payments: {},
                    profit: 0,
                  )),
                  child: const Text('Sell'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatementScreen()))),
                  child: const Text('Statement'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startVoice,
        tooltip: 'Voice entry',
        child: const Icon(Icons.mic),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Statement'),
        ],
        currentIndex: 0,
        onTap: (idx) {
          // simple navigation placeholder
        },
      ),
    );
  }
}
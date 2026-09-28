import 'package:flutter/material.dart';
import 'package:spares_app/models.dart';
import 'package:spares_app/services/local_storage.dart';

class StatementScreen extends StatefulWidget {
  const StatementStatement({Key? key}) : super(key: key);
  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  late LocalStorage _storage;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  Map<String, double> _ledger = {};
  String? _balanceText;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorage();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final custs = await _storage.getCustomers();
    setState(() {
      _customers = custs;
      _selectedCustomer = custs.isNotEmpty ? custs.first : null;
      _refreshLedger();
    });
  }

  void _refreshLedger() {
    setState(() {
      _ledger = _selectedCustomer?.ledger ?? {};
      final bal = _selectedCustomer?.getBalance() ?? 0;
      _balanceText = 'KSh $bal';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Statement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer selector
            DropdownButtonFormField<Customer>(
              value: _selectedCustomer,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: _customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (c) {
                setState(() {
                  _selectedCustomer = c;
                  _refreshLedger();
                });
              },
            ),
            const SizedBox(height: 24),
            // Balance
            Text(
              _balanceText ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            // Transaction list
            const Text('Transaction history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: _ledger.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.builder(
                      itemCount: _ledger.length,
                      itemBuilder: (ctx, i) {
                        final (date, change) = _ledger.entries.elementAt(i);
                        final isCredit = change > 0;
                        return ListTile(
                          title: Text(date),
                          subtitle: Text(isCredit ? 'Owed +KSh ${change.toStringAsFixed(0)}' : 'Paid -KSh ${change.toStringAsFixed(0)}'),
                          trailing: Icon(isCredit ? Icons.arrow_upward : Icons.arrow_downward),
                        );
                      },
                    ),
            ),
            const Spacer(),
            // Record payment button
            ElevatedButton(
              onPressed: () {
                // Navigate to payment recording (placeholder)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record payment feature coming soon')));
              },
              child: const Text('Record payment'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
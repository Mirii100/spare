import 'package:flutter/material.dart';
import 'package:spares_app/models.dart';
import 'package:spares_app/services/local_storage.dart';

class SaleScreen extends StatefulWidget {
  final Sale sale;
  final List<Product> products;
  final VoidCallback onSave;

  const SaleScreen({
    required this.sale,
    required this.products,
    required this.onSave,
    super.key,
  });

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  late TextEditingController _customerNameCtrl;
  late TextEditingController _vehicleCtrl;
  List<SaleLine> _lines = List.from(widget.sale.lines);
  Map<String, double> _payments = Map.from(widget.sale.payments);
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.sale.customer;
    _customerNameCtrl = TextEditingController(text: _customer?.name ?? '');
    _vehicleCtrl = TextEditingController(text: _customer?.vehicleReg ?? '');
  }

  void _addLine() {
    // simple picker for product
    showDialog(
      context: context,
      builder: (_) => _ProductPicker(
        products: widget.products,
        selected: _lines.isNotEmpty ? _lines.last.product : widget.products.first,
        onSelect: (p) {
          setState(() {
            _lines.add(SaleLine(product: p, quantity: 1, priceAtSale: p.price));
          });
          Navigator.of(_).pop();
        },
      ),
    );
  }

  void _removeLine(int idx) {
    setState(() => _lines.removeAt(idx));
  }

  double _calculateProfit() {
    double totalCost = 0;
    for (final l in _lines) {
      totalCost += l.product.cost * l.quantity;
    }
    double totalRevenue = 0;
    for (final l in _lines) {
      totalRevenue += l.priceAtSale * l.quantity;
    }
    return totalRevenue - totalCost;
  }

  double _calculateTotal() {
    double total = 0;
    for (final l in _lines) total += l.priceAtSale * l.quantity;
    return total;
  }

  void _saveSale() async {
    final updatedSale = widget.sale.copyWith(
      customer: _customer ?? Customer(id: 0, name: _customerNameCtrl.text),
      lines: _lines,
      payments: _payments,
    );
    await LocalStorage().insertSale(updatedSale);
    // update product stocks already done in insertSale
    widget.onSave();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSale,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info
            TextField(
              controller: _customerNameCtrl,
              decoration: const InputDecoration(labelText: 'Customer name / garage'),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _vehicleCtrl,
              decoration: const InputDecoration(labelText: 'Vehicle reg (optional)'),
            ),
            const SizedBox(height: 16),
            // Lines list
            ..._lines.asMap().entries.map((e) => _buildLine(e.key, e.value)).toList(),
            const SizedBox(height: 12),
            // Add line button
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
              onPressed: _addLine,
            ),
            const SizedBox(height: 24),
            // Payments section
            const Text('Payments', style: TextStyle(fontWeight: FontWeight.w600)),
            _buildPaymentRow('Cash', Icons.money),
            _buildPaymentRow('M-Pesa', Icons.phone),
            _buildPaymentRow('Credit', Icons.credit_card),
            const SizedBox(height: 16),
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 16)),
                Text('KSh ${_calculateTotal().toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('KSh ${_calculateProfit().toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 32),
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSale,
                child: const Text('Confirm & Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(int idx, SaleLine line) {
    final prod = line.product;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('${prod.name} (${prod.code})'),
        subtitle: Text('Qty: ${line.quantity} @ KSh ${prod.price.toStringAsFixed(0)} each'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: () => _removeLine(idx),
        ),
      ),
    );
  }

  Widget _buildLine(int idx, SaleLine line) {
    final prod = line.product;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('${prod.name} (${prod.code})'),
        subtitle: Text('Qty: ${line.quantity} @ KSh ${prod.price.toStringAsFixed(0)} each'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: () => _removeLine(idx),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              setState(() {
                _payments[label] = double.tryParse(val) ?? 0.0;
              });
            },
          )),
          Text(
            'KSh ${_payments[label].toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

// Dummy copyWith for Sale to avoid too much code
extension SaleExt on Sale {
  Sale copyWith({Customer? customer, List<SaleLine>? lines, Map<String, double>? payments}) {
    return Sale(
      id: id,
      date: date,
      customer: customer ?? this.customer,
      lines: lines ?? this.lines,
      payments: payments ?? this.payments,
      profit: _calculateProfit(),
    );
  }

  double _calculateProfit() {
    double totalCost = 0;
    for (final l in lines) totalCost += l.product.cost * l.quantity;
    double totalRev = 0;
    for (final l in lines) totalRev += l.priceAtSale * l.quantity;
    return totalRev - totalCost;
  }
}

// Product picker widget
class _ProductPicker extends StatefulWidget {
  final List<Product> products;
  final Product selected;
  final Function(Product) onSelect;

  const _ProductPicker({required this.products, required this.selected, required this.onSelect});

  @override
  __ProductPickerState createState() => __ProductPickerState();
}

class __ProductPickerState extends State<_ProductPicker> {
  late Product _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Select product,
      size: const Size(double.maxFinite, 300),
      content: SingleChildScrollView(
        child: Column(
          children: widget.products.map((p) => RadioListTile<String>(
            title: Text('${p.name} (${p.code}) – Cost: KSh ${p.cost}, Price: KSh ${p.price}'),
            value: p.code,
            groupValue: _selected.code,
            onChanged: (val) {
              setState(() {
                _selected = widget.products.firstWhere((pr) => pr.code == val);
                widget.onSelect(_selected);
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
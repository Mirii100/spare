class Product {
  final int id;
  final String name;
  final String code;
  final double cost;
  final double price;
  final int minStock;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.code,
    required this.cost,
    required this.price,
    required this.minStock,
    this.quantity = 0,
  });
}

class Sale {
  final int id;
  final DateTime date;
  final Customer customer;
  final List<SaleLine> lines;
  final Map<String, double> payments;
  final double profit;

  Sale({
    required this.id,
    required this.date,
    required this.customer,
    required this.lines,
    required this.payments,
    required this.profit,
  });
}

class SaleLine {
  final Product product;
  final int quantity;
  final double priceAtSale;

  SaleLine({required this.product, required this.quantity, required this.priceAtSale});
}

class Customer {
  final int id;
  final String name;
  final String? vehicleReg;
  final Map<String, double> ledger;

  Customer({
    required this.id,
    required this.name,
    this.vehicleReg,
    this.ledger = const {},
  });

  double getBalance() {
    double total = 0;
    for (final entry in ledger.entries) {
      total += entry.value;
    }
    return total;
  }
}

class StockMovement {
  enum Type { sale, purchase, return_, adjustment, loss, damage }

  final int id;
  final Type type;
  final Product product;
  final int quantity;
  final String reason;
  final DateTime date;
  final String user;

  StockMovement({
    required this.id,
    required this.type,
    required this.product,
    required this.quantity,
    required this.reason,
    required this.date,
    required this.user,
  });
}
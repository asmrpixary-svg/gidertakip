class TransactionItem {
  final int? id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String paymentMethod; // 'bank' or 'cash'
  final DateTime date;
  final String? note;
  final int? fuelLogId;

  TransactionItem({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.note,
    this.fuelLogId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'note': note,
      'fuel_log_id': fuelLogId,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paymentMethod: map['payment_method'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      fuelLogId: map['fuel_log_id'] as int?,
    );
  }

  TransactionItem copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? paymentMethod,
    DateTime? date,
    String? note,
    int? fuelLogId,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      note: note ?? this.note,
      fuelLogId: fuelLogId ?? this.fuelLogId,
    );
  }
}

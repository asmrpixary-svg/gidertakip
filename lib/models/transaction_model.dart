class TransactionModel {
  final int? id;
  final String type; // 'gelir' (income) or 'gider' (expense)
  final double amount;
  final String category;
  final String paymentMethod; // 'Banka' or 'Nakit'
  final DateTime date;
  final String? note;
  final int? fuelEntryId;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.note,
    this.fuelEntryId,
  });

  bool get isIncome => type.toLowerCase() == 'gelir' || type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'gider' || type.toLowerCase() == 'expense';
  bool get isBank => paymentMethod.toLowerCase() == 'banka' || paymentMethod.toLowerCase() == 'bank';
  bool get isCash => paymentMethod.toLowerCase() == 'nakit' || paymentMethod.toLowerCase() == 'cash';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'note': note,
      'fuel_entry_id': fuelEntryId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paymentMethod: map['payment_method'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      fuelEntryId: map['fuel_entry_id'] as int?,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? paymentMethod,
    DateTime? date,
    String? note,
    int? fuelEntryId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      note: note ?? this.note,
      fuelEntryId: fuelEntryId ?? this.fuelEntryId,
    );
  }
}

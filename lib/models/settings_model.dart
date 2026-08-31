class AppSettings {
  final double bankBalance;
  final double initialBalance;

  AppSettings({
    required this.bankBalance,
    required this.initialBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'bank_balance': bankBalance,
      'initial_balance': initialBalance,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      bankBalance: (map['bank_balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

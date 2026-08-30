class FuelEntryModel {
  final int? id;
  final DateTime date;
  final double odometerKm;
  final double liters;
  final double totalCost;
  final String? stationNote;
  final String paymentMethod; // 'Banka' or 'Nakit'

  // Calculated properties (derived or computed from context)
  final double? costPerKm; // TL/km
  final double? consumptionPer100Km; // L/100km

  FuelEntryModel({
    this.id,
    required this.date,
    required this.odometerKm,
    required this.liters,
    required this.totalCost,
    this.stationNote,
    this.paymentMethod = 'Banka',
    this.costPerKm,
    this.consumptionPer100Km,
  });

  double get pricePerLiter => liters > 0 ? totalCost / liters : 0.0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'odometer_km': odometerKm,
      'liters': liters,
      'total_cost': totalCost,
      'station_note': stationNote,
      'payment_method': paymentMethod,
    };
  }

  factory FuelEntryModel.fromMap(
    Map<String, dynamic> map, {
    double? costPerKm,
    double? consumptionPer100Km,
  }) {
    return FuelEntryModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      odometerKm: (map['odometer_km'] as num).toDouble(),
      liters: (map['liters'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      stationNote: map['station_note'] as String?,
      paymentMethod: map['payment_method'] as String? ?? 'Banka',
      costPerKm: costPerKm,
      consumptionPer100Km: consumptionPer100Km,
    );
  }

  FuelEntryModel copyWith({
    int? id,
    DateTime? date,
    double? odometerKm,
    double? liters,
    double? totalCost,
    String? stationNote,
    String? paymentMethod,
    double? costPerKm,
    double? consumptionPer100Km,
  }) {
    return FuelEntryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      odometerKm: odometerKm ?? this.odometerKm,
      liters: liters ?? this.liters,
      totalCost: totalCost ?? this.totalCost,
      stationNote: stationNote ?? this.stationNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      costPerKm: costPerKm ?? this.costPerKm,
      consumptionPer100Km: consumptionPer100Km ?? this.consumptionPer100Km,
    );
  }
}

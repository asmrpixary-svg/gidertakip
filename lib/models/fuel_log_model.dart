class FuelLog {
  final int? id;
  final DateTime date;
  final double odometerKm;
  final double liters;
  final double totalCost;
  final String? stationNote;
  final double? costPerKm; // Calculated: TL / km
  final double? consumptionPer100km; // Calculated: L / 100km
  final int? transactionId;

  FuelLog({
    this.id,
    required this.date,
    required this.odometerKm,
    required this.liters,
    required this.totalCost,
    this.stationNote,
    this.costPerKm,
    this.consumptionPer100km,
    this.transactionId,
  });

  double get pricePerLiter => liters > 0 ? totalCost / liters : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'odometer_km': odometerKm,
      'liters': liters,
      'total_cost': totalCost,
      'station_note': stationNote,
      'cost_per_km': costPerKm,
      'consumption_per_100km': consumptionPer100km,
      'transaction_id': transactionId,
    };
  }

  factory FuelLog.fromMap(Map<String, dynamic> map) {
    return FuelLog(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      odometerKm: (map['odometer_km'] as num).toDouble(),
      liters: (map['liters'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      stationNote: map['station_note'] as String?,
      costPerKm: map['cost_per_km'] != null ? (map['cost_per_km'] as num).toDouble() : null,
      consumptionPer100km: map['consumption_per_100km'] != null ? (map['consumption_per_100km'] as num).toDouble() : null,
      transactionId: map['transaction_id'] as int?,
    );
  }

  FuelLog copyWith({
    int? id,
    DateTime? date,
    double? odometerKm,
    double? liters,
    double? totalCost,
    String? stationNote,
    double? costPerKm,
    double? consumptionPer100km,
    int? transactionId,
  }) {
    return FuelLog(
      id: id ?? this.id,
      date: date ?? this.date,
      odometerKm: odometerKm ?? this.odometerKm,
      liters: liters ?? this.liters,
      totalCost: totalCost ?? this.totalCost,
      stationNote: stationNote ?? this.stationNote,
      costPerKm: costPerKm ?? this.costPerKm,
      consumptionPer100km: consumptionPer100km ?? this.consumptionPer100km,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

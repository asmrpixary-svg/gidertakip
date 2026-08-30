import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/fuel_provider.dart';
import '../models/fuel_entry_model.dart';
import 'add_edit_fuel_entry_screen.dart';

class FuelTrackerScreen extends StatelessWidget {
  const FuelTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    final DateFormat dateFormat = DateFormat('d MMMM yyyy', 'tr_TR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakıt Takip', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () {
              Provider.of<FuelProvider>(context, listen: false).loadFuelData();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditFuelEntryScreen(),
            ),
          );
        },
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.local_gas_station),
        label: const Text('Yakıt Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<FuelProvider>(
        builder: (context, fuelProvider, child) {
          if (fuelProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = fuelProvider.fuelEntries;

          return RefreshIndicator(
            onRefresh: () => fuelProvider.loadFuelData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Key Metrics Summary Grid
                  _buildSummaryGrid(context, fuelProvider, currencyFormat),
                  const SizedBox(height: 20),

                  // Consumption Trend Chart (fl_chart)
                  if (entries.where((e) => e.consumptionPer100Km != null).length >= 2) ...[
                    _buildConsumptionChart(context, entries),
                    const SizedBox(height: 20),
                  ],

                  // Fuel History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yakıt Alım Geçmişi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${entries.length} Kayıt',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Fuel Entries List
                  entries.isEmpty
                      ? Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Column(
                              children: [
                                Icon(Icons.local_gas_station, size: 56, color: Colors.orange.shade300),
                                const SizedBox(height: 12),
                                const Text(
                                  'Henüz yakıt kaydı yok',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'İki dolum arasında 100 km\'deki tüketim (L/100km) ve km maliyeti (TL/km) otomatik hesaplanır.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _buildFuelEntryTile(context, entry, currencyFormat, dateFormat);
                          },
                        ),
                  const SizedBox(height: 80), // FAB spacing
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, FuelProvider provider, NumberFormat currencyFormat) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Ort. Tüketim',
                value: provider.averageConsumptionPer100Km > 0
                    ? '${provider.averageConsumptionPer100Km.toStringAsFixed(1)} L/100km'
                    : '—',
                subtitle: 'İki dolum arası ortalama',
                icon: Icons.speed,
                color: Colors.orange.shade800,
                bgColor: Colors.orange.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Ort. Km Maliyeti',
                value: provider.averageCostPerKm > 0
                    ? '${provider.averageCostPerKm.toStringAsFixed(2)} ₺/km'
                    : '—',
                subtitle: 'Mesafe başına maliyet',
                icon: Icons.alt_route,
                color: Colors.teal.shade800,
                bgColor: Colors.teal.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Son Dolum Yapılan Km',
                value: provider.distanceSinceLastFill > 0
                    ? '${provider.distanceSinceLastFill.toStringAsFixed(0)} km'
                    : '—',
                subtitle: 'Son 2 alma arası kat edilen',
                icon: Icons.directions_car,
                color: Colors.blue.shade800,
                bgColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Ort. Litre Fiyatı',
                value: provider.averagePricePerLiter > 0
                    ? currencyFormat.format(provider.averagePricePerLiter)
                    : '—',
                subtitle: 'Litre başı birim fiyat',
                icon: Icons.local_offer,
                color: Colors.purple.shade800,
                bgColor: Colors.purple.shade50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionChart(BuildContext context, List<FuelEntryModel> entries) {
    // Reverse entries to chronological order for the x-axis timeline
    final sortedEntries = entries.where((e) => e.consumptionPer100Km != null).toList().reversed.toList();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].consumptionPer100Km!));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Tüketim Değişimi (L/100km)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          int idx = val.toInt();
                          if (idx >= 0 && idx < sortedEntries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${sortedEntries[idx].date.day}/${sortedEntries[idx].date.month}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.orange.shade800,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.shade100.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelEntryTile(
    BuildContext context,
    FuelEntryModel entry,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditFuelEntryScreen(fuelEntry: entry),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.local_gas_station, color: Colors.orange.shade900),
        ),
        title: Row(
          children: [
            Text(
              '${entry.odometerKm.toStringAsFixed(0)} km',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: entry.paymentMethod == 'Banka' ? Colors.blue.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: entry.paymentMethod == 'Banka' ? Colors.blue.shade300 : Colors.amber.shade300,
                ),
              ),
              child: Text(
                entry.paymentMethod,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: entry.paymentMethod == 'Banka' ? Colors.blue.shade800 : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${dateFormat.format(entry.date)} • ${entry.liters.toStringAsFixed(1)} Litre (${currencyFormat.format(entry.pricePerLiter)}/L)',
              style: const TextStyle(fontSize: 12),
            ),
            if (entry.stationNote != null && entry.stationNote!.isNotEmpty)
              Text(
                'İstasyon: ${entry.stationNote}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            if (entry.consumptionPer100Km != null || entry.costPerKm != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    if (entry.consumptionPer100Km != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${entry.consumptionPer100Km!.toStringAsFixed(1)} L/100km',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    if (entry.consumptionPer100Km != null && entry.costPerKm != null)
                      const SizedBox(width: 6),
                    if (entry.costPerKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${entry.costPerKm!.toStringAsFixed(2)} ₺/km',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Text(
          '-${currencyFormat.format(entry.totalCost)}',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';
import 'add_fuel_log_screen.dart';

class FuelTrackingScreen extends StatelessWidget {
  const FuelTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakıt Takibi'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = provider.fuelLogs; // sorted ASC by odometer

          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Ort. Tüketim',
                          value: provider.avgConsumptionPer100km != null
                              ? '${provider.avgConsumptionPer100km!.toStringAsFixed(1)} L/100km'
                              : '—',
                          icon: Icons.local_gas_station,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Km Başı Maliyet',
                          value: provider.avgCostPerKm != null
                              ? '${provider.avgCostPerKm!.toStringAsFixed(2)} ₺/km'
                              : '—',
                          icon: Icons.speed,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Toplam Harcama',
                          value: Formatters.formatCurrency(provider.totalFuelCost),
                          icon: Icons.account_balance_wallet,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Katedilen Mesafe',
                          value: '${provider.totalKmTraveled.toStringAsFixed(0)} km',
                          icon: Icons.add_road,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Consumption Chart (fl_chart)
                  const Text(
                    'Ortalama Tüketim Değişimi (L/100km)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildConsumptionChart(logs),

                  const SizedBox(height: 24),

                  // Logs List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yakıt Dolum Geçmişi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${logs.length} Kayıt',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (logs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: Center(
                        child: Text(
                          'Henüz yakıt kaydı eklenmedi.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        // Display newest first
                        final log = logs[logs.length - 1 - index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.speed, size: 18, color: Colors.indigo),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${log.odometerKm.toStringAsFixed(0)} km',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      Formatters.formatDate(log.date),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${log.liters.toStringAsFixed(1)} L • ${log.pricePerLiter.toStringAsFixed(2)} ₺/L',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        if (log.stationNote != null && log.stationNote!.isNotEmpty)
                                          Text(
                                            log.stationNote!,
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      Formatters.formatCurrency(log.totalCost),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                if (log.costPerKm != null || log.consumptionPer100km != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        if (log.costPerKm != null)
                                          Text(
                                            'Km Maliyeti: ${log.costPerKm!.toStringAsFixed(2)} ₺/km',
                                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                          ),
                                        if (log.consumptionPer100km != null)
                                          Text(
                                            '100 km Tüketim: ${log.consumptionPer100km!.toStringAsFixed(1)} L',
                                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Yakıt Kaydını Sil'),
                                            content: const Text(
                                                'Bu yakıt kaydı ve buna bağlı gider işlemi silinecektir. Onaylıyor musunuz?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('İptal'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true && log.id != null) {
                                          provider.deleteFuelLog(log.id!);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFuelLogScreen()),
          );
        },
        icon: const Icon(Icons.local_gas_station),
        label: const Text('Yakıt Alımı Ekle'),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionChart(List logs) {
    final logsWithData = logs.where((l) => l.consumptionPer100km != null).toList();

    if (logsWithData.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Grafik için en az 2 dolum kaydı gereklidir.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < logsWithData.length; i++) {
      spots.add(FlSpot(i.toDouble(), logsWithData[i].consumptionPer100km!));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < logsWithData.length) {
                    final date = logsWithData[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${date.day}/${date.month}',
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
              color: Colors.amber.shade800,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.amber.shade100.withAlpha(128),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider & Gelir Takip', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => onNavigateToTab(3), // Navigate to Settings
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentTransactions = provider.transactions.take(5).toList();

          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Bank Balance Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance, color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Güncel Banka Bakiyesi',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            Formatters.formatCurrency(provider.bankBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Monthly Income & Expense Summary Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Monthly Income
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Bu Ay Gelir',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.formatCurrency(provider.monthlyIncome),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          // Monthly Expense
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Bu Ay Gider',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    Formatters.formatCurrency(provider.monthlyExpense),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Fuel Shortcut Card
                  InkWell(
                    onTap: () => onNavigateToTab(2), // Fuel Tab
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      color: Colors.amber.shade50,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_gas_station, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Yakıt Takibi Modülü',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    provider.fuelLogs.isNotEmpty
                                        ? 'Son km: ${provider.fuelLogs.last.odometerKm.toStringAsFixed(0)} km'
                                        : 'Henüz yakıt kaydı bulunmuyor',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Son İşlemler',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => onNavigateToTab(1), // History Tab
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),

                  // Recent Transactions List
                  if (recentTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: Center(
                        child: Text(
                          'Henüz bir işlem eklenmedi.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = recentTransactions[index];
                        final isIncome = tx.type == 'income';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              tx.category,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${Formatters.formatDate(tx.date)} • ${tx.paymentMethod == 'bank' ? 'Banka' : 'Nakit'}${tx.note != null && tx.note!.isNotEmpty ? ' (${tx.note})' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}${Formatters.formatCurrency(tx.amount)}',
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
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
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('İşlem Ekle'),
      ),
    );
  }
}

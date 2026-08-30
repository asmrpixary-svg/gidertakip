import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import 'add_edit_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToFuelTab;

  const DashboardScreen({super.key, required this.onNavigateToFuelTab});

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
        title: const Text('Bütçe Takip', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).loadData();
            },
          )
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProvider, child) {
          if (financeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentTransactions = financeProvider.transactions.take(5).toList();

          return RefreshIndicator(
            onRefresh: () => financeProvider.loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prominent Bank Balance Card
                  _buildBalanceCard(context, financeProvider, currencyFormat),
                  const SizedBox(height: 16),

                  // Monthly Income / Expense Summary Card
                  _buildMonthlySummaryCard(context, financeProvider, currencyFormat),
                  const SizedBox(height: 16),

                  // Quick Access Banner to Fuel Tracker
                  _buildFuelQuickAccessCard(context),
                  const SizedBox(height: 20),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Son İşlemler',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (recentTransactions.isNotEmpty)
                        Text(
                          'Son ${recentTransactions.length} İşlem',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent Transactions List
                  recentTransactions.isEmpty
                      ? Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text(
                                  'Henüz işlem bulunmuyor',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentTransactions.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = recentTransactions[index];
                            return _buildTransactionTile(context, tx, currencyFormat, dateFormat);
                          },
                        ),
                  const SizedBox(height: 80), // Extra space for FAB
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, FinanceProvider financeProvider, NumberFormat currencyFormat) {
    final balance = financeProvider.currentBankBalance;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'GÜNCEL BANKA BAKİYESİ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Banka',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currencyFormat.format(balance),
              style: TextStyle(
                color: balance >= 0 ? Colors.white : Colors.redAccent.shade100,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Başlangıç bakiyesi: ${currencyFormat.format(financeProvider.initialBankBalance)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(BuildContext context, FinanceProvider financeProvider, NumberFormat currencyFormat) {
    final income = financeProvider.thisMonthIncome;
    final expense = financeProvider.thisMonthExpense;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu Ayın Özeti',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Toplam Gelir', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormat.format(income),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Toplam Gider', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormat.format(expense),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelQuickAccessCard(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: InkWell(
        onTap: onNavigateToFuelTab,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Icon(Icons.local_gas_station, color: Colors.orange.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yakıt Takip Sekmesi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    Text(
                      'Tüketim (L/100km) ve km maliyetlerini inceleyin',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.orange.shade800),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionModel tx,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final bool isIncome = tx.isIncome;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditTransactionScreen(transaction: tx),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Row(
          children: [
            Text(
              tx.category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tx.isBank ? Colors.blue.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: tx.isBank ? Colors.blue.shade300 : Colors.amber.shade300,
                ),
              ),
              child: Text(
                tx.paymentMethod,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tx.isBank ? Colors.blue.shade800 : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${dateFormat.format(tx.date)}${tx.note != null && tx.note!.isNotEmpty ? ' • ${tx.note}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

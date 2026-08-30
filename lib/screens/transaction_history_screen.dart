import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedCategory = 'Tümü';
  String _selectedPaymentMethod = 'Tümü';

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
        title: const Text('İşlem Geçmişi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProvider, child) {
          if (financeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Build list of categories for filter dropdown
          final allCategories = ['Tümü'];
          for (var c in financeProvider.expenseCategories) {
            if (!allCategories.contains(c.name)) allCategories.add(c.name);
          }
          for (var c in financeProvider.incomeCategories) {
            if (!allCategories.contains(c.name)) allCategories.add(c.name);
          }

          final transactions = financeProvider.transactions.where((tx) {
            if (_selectedCategory != 'Tümü' && tx.category != _selectedCategory) {
              return false;
            }
            if (_selectedPaymentMethod != 'Tümü' && tx.paymentMethod != _selectedPaymentMethod) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Filters Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Category Filter Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: allCategories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Payment Method Filter Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Ödeme Yöntemi',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                          DropdownMenuItem(value: 'Banka', child: Text('Banka')),
                          DropdownMenuItem(value: 'Nakit', child: Text('Nakit')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentMethod = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Transactions List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Seçilen filtrelere uygun işlem bulunamadı.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isIncome = tx.isIncome;
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
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

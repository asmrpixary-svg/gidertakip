import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';
import 'add_transaction_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _typeFilter = 'ALL'; // ALL, income, expense
  String _paymentMethodFilter = 'ALL'; // ALL, bank, cash
  String _categoryFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Geçmişi'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          var filtered = provider.transactions;

          // Apply type filter
          if (_typeFilter != 'ALL') {
            filtered = filtered.where((t) => t.type == _typeFilter).toList();
          }

          // Apply payment method filter
          if (_paymentMethodFilter != 'ALL') {
            filtered = filtered.where((t) => t.paymentMethod == _paymentMethodFilter).toList();
          }

          // Apply category filter
          if (_categoryFilter != 'ALL') {
            filtered = filtered.where((t) => t.category == _categoryFilter).toList();
          }

          // Group by date (yyyy-MM-dd)
          final Map<String, List<TransactionItem>> groupedTransactions = {};
          for (var tx in filtered) {
            final dateKey = Formatters.dayMonthFormat.format(tx.date);
            groupedTransactions.putIfAbsent(dateKey, () => []).add(tx);
          }

          final categoriesList = provider.categories.map((c) => c.name).toSet().toList();

          return Column(
            children: [
              // Filters Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Type filter chip
                          FilterChip(
                            label: const Text('Tümü'),
                            selected: _typeFilter == 'ALL',
                            onSelected: (_) => setState(() => _typeFilter = 'ALL'),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Gelirler'),
                            selected: _typeFilter == 'income',
                            selectedColor: Colors.green.shade100,
                            onSelected: (_) => setState(() => _typeFilter = 'income'),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Giderler'),
                            selected: _typeFilter == 'expense',
                            selectedColor: Colors.red.shade100,
                            onSelected: (_) => setState(() => _typeFilter = 'expense'),
                          ),
                          const SizedBox(width: 12),
                          const VerticalDivider(),
                          // Payment method filter chip
                          ChoiceChip(
                            label: const Text('Banka'),
                            selected: _paymentMethodFilter == 'bank',
                            onSelected: (sel) => setState(() => _paymentMethodFilter = sel ? 'bank' : 'ALL'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Nakit'),
                            selected: _paymentMethodFilter == 'cash',
                            onSelected: (sel) => setState(() => _paymentMethodFilter = sel ? 'cash' : 'ALL'),
                          ),
                        ],
                      ),
                    ),
                    if (categoriesList.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Kategori: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            DropdownButton<String>(
                              value: _categoryFilter,
                              isDense: true,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              items: [
                                const DropdownMenuItem(value: 'ALL', child: Text('Tüm Kategoriler')),
                                ...categoriesList.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _categoryFilter = val);
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Transaction List grouped chronologically
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Kriterlere uygun işlem bulunamadı.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: groupedTransactions.keys.length,
                        itemBuilder: (context, dateIndex) {
                          final dateGroupKey = groupedTransactions.keys.elementAt(dateIndex);
                          final groupItems = groupedTransactions[dateGroupKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  dateGroupKey.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              ...groupItems.map((tx) {
                                final isIncome = tx.type == 'income';

                                return Dismissible(
                                  key: Key('tx_${tx.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (_) async {
                                    return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('İşlemi Sil'),
                                        content: const Text('Bu işlemi silmek istediğinize emin misiniz?'),
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
                                  },
                                  onDismissed: (_) {
                                    provider.deleteTransaction(tx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('İşlem silindi.')),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                        '${tx.paymentMethod == 'bank' ? 'Banka' : 'Nakit'}${tx.note != null && tx.note!.isNotEmpty ? ' • ${tx.note}' : ''}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${isIncome ? '+' : '-'}${Formatters.formatCurrency(tx.amount)}',
                                            style: TextStyle(
                                              color: isIncome ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (action) {
                                              if (action == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AddTransactionScreen(existingTransaction: tx),
                                                  ),
                                                );
                                              } else if (action == 'delete') {
                                                provider.deleteTransaction(tx);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Düzenle'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Sil', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _balanceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _showEditInitialBalanceDialog(FinanceProvider provider) {
    _balanceController.text = provider.initialBankBalance.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Başlangıç Banka Bakiyesi'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Bakiye (₺)',
              suffixText: '₺',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Bakiye giriniz';
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null) return 'Geçerli bir bakiye giriniz';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newBal = double.parse(_balanceController.text.replaceAll(',', '.'));
                await provider.updateInitialBankBalance(newBal);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(FinanceProvider provider, String type) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yeni ${type == 'gider' ? 'Gider' : 'Gelir'} Kategorisi Ekle'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(
            labelText: 'Kategori Adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = catController.text.trim();
              if (name.isNotEmpty) {
                await provider.addCategory(name, type);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProvider, child) {
          final expenseCategories = financeProvider.expenseCategories;
          final incomeCategories = financeProvider.incomeCategories;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Initial Bank Balance
                const Text(
                  'Banka Bakiyesi Yönetimi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Icon(Icons.account_balance, color: Colors.teal.shade900),
                    ),
                    title: const Text('Başlangıç Banka Bakiyesi'),
                    subtitle: Text(
                      currencyFormat.format(financeProvider.initialBankBalance),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showEditInitialBalanceDialog(financeProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Düzenle'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Expense Categories Management
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gider Kategorileri',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      tooltip: 'Gider Kategorisi Ekle',
                      onPressed: () => _showAddCategoryDialog(financeProvider, 'gider'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenseCategories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = expenseCategories[index];
                      return ListTile(
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: cat.isDefault
                            ? const Text('Varsayılan', style: TextStyle(fontSize: 11, color: Colors.grey))
                            : const Text('Özel Kategori', style: TextStyle(fontSize: 11, color: Colors.teal)),
                        trailing: cat.isDefault
                            ? const Icon(Icons.lock_outline, size: 20, color: Colors.grey)
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Kategoriyi Sil',
                                onPressed: () => financeProvider.deleteCategory(cat.id!, 'gider'),
                              ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Income Categories Management
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gelir Kategorileri',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      tooltip: 'Gelir Kategorisi Ekle',
                      onPressed: () => _showAddCategoryDialog(financeProvider, 'gelir'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: incomeCategories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = incomeCategories[index];
                      return ListTile(
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: cat.isDefault
                            ? const Text('Varsayılan', style: TextStyle(fontSize: 11, color: Colors.grey))
                            : const Text('Özel Kategori', style: TextStyle(fontSize: 11, color: Colors.teal)),
                        trailing: cat.isDefault
                            ? const Icon(Icons.lock_outline, size: 20, color: Colors.grey)
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Kategoriyi Sil',
                                onPressed: () => financeProvider.deleteCategory(cat.id!, 'gelir'),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

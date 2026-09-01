import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showEditBalanceDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(
      text: provider.bankBalance.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Banka Bakiyesini Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Güncel banka bakiyenizi doğrudan güncellemek için yeni tutarı girin.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Mevcut Bakiye (₺)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null) {
                provider.updateBankBalance(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Banka bakiyesi güncellendi.')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    String type = 'expense';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Yeni Kategori Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Gider')),
                  ButtonSegment(value: 'income', label: Text('Gelir')),
                ],
                selected: {type},
                onSelectionChanged: (set) {
                  setStateDialog(() => type = set.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  provider.addCategory(name, type);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori eklendi.')),
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & Kategori Yönetimi'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Management Section
                const Text(
                  'Bakiye Yönetimi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance, color: Colors.blue),
                    title: const Text('Mevcut Banka Bakiyesi'),
                    subtitle: Text(Formatters.formatCurrency(provider.bankBalance)),
                    trailing: ElevatedButton(
                      onPressed: () => _showEditBalanceDialog(context, provider),
                      child: const Text('Düzenle'),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Category Management Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kategori Yönetimi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: () => _showAddCategoryDialog(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Expense Categories List
                const Text(
                  'Gider Kategorileri',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Card(
                  child: Column(
                    children: provider.expenseCategories.map((cat) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.label, color: Colors.red, size: 20),
                        title: Text(cat.name),
                        trailing: cat.isCustom
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () {
                                  if (cat.id != null) {
                                    provider.deleteCategory(cat.id!);
                                  }
                                },
                              )
                            : const Text('Varsayılan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Income Categories List
                const Text(
                  'Gelir Kategorileri',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Card(
                  child: Column(
                    children: provider.incomeCategories.map((cat) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.label, color: Colors.green, size: 20),
                        title: Text(cat.name),
                        trailing: cat.isCustom
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () {
                                  if (cat.id != null) {
                                    provider.deleteCategory(cat.id!);
                                  }
                                },
                              )
                            : const Text('Varsayılan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      );
                    }).toList(),
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

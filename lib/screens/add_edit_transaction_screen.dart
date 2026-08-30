import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type; // 'gider' or 'gelir'
  late String _category;
  late String _paymentMethod; // 'Banka' or 'Nakit'
  late DateTime _selectedDate;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      _type = tx.type;
      _amountController.text = tx.amount.toString();
      _category = tx.category;
      _paymentMethod = tx.paymentMethod;
      _selectedDate = tx.date;
      _noteController.text = tx.note ?? '';
    } else {
      _type = 'gider';
      _category = '';
      _paymentMethod = 'Banka';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _showAddCategoryDialog(FinanceProvider provider) async {
    final newCatController = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yeni ${_type == 'gider' ? 'Gider' : 'Gelir'} Kategorisi Ekle'),
        content: TextField(
          controller: newCatController,
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
            onPressed: () {
              if (newCatController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, newCatController.text.trim());
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (added != null && added.isNotEmpty) {
      await provider.addCategory(added, _type);
      setState(() {
        _category = added;
      });
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    if (_category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin.')),
      );
      return;
    }

    final newTx = TransactionModel(
      id: widget.transaction?.id,
      type: _type,
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      category: _category,
      paymentMethod: _paymentMethod,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      fuelEntryId: widget.transaction?.fuelEntryId,
    );

    if (isEditing) {
      await financeProvider.updateTransaction(newTx);
    } else {
      await financeProvider.addTransaction(newTx);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final categories = _type == 'gider'
        ? financeProvider.expenseCategories
        : financeProvider.incomeCategories;

    // Ensure category selection remains valid when changing type toggle
    if (_category.isEmpty || !categories.any((c) => c.name == _category)) {
      if (categories.isNotEmpty) {
        _category = categories.first.name;
      }
    }

    final dateFormat = DateFormat('d MMMM yyyy', 'tr_TR');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'İşlemi Düzenle' : 'Yeni İşlem Ekle'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'İşlemi Sil',
              onPressed: () async {
                final txId = widget.transaction!.id!;
                final confirm = await showDialog<bool>(
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
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final provider = Provider.of<FinanceProvider>(context, listen: false);
                  await provider.deleteTransaction(txId);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Segmented Button (Gelir / Gider)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'gider',
                    label: Text('Gider (-)', style: TextStyle(fontWeight: FontWeight.bold)),
                    icon: Icon(Icons.arrow_upward, color: Colors.red),
                  ),
                  ButtonSegment<String>(
                    value: 'gelir',
                    label: Text('Gelir (+)', style: TextStyle(fontWeight: FontWeight.bold)),
                    icon: Icon(Icons.arrow_downward, color: Colors.green),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                    _category = '';
                  });
                },
              ),
              const SizedBox(height: 20),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tutar (₺)',
                  prefixIcon: const Icon(Icons.money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: '₺',
                ),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen tutar giriniz';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Geçerli bir pozitif tutar giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment Method Choice (Banka / Nakit)
              const Text('Ödeme Yöntemi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('Banka (Bakiye Etkiler)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      selected: _paymentMethod == 'Banka',
                      selectedColor: Colors.teal.shade100,
                      onSelected: (selected) {
                        if (selected) setState(() => _paymentMethod = 'Banka');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('Nakit', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      selected: _paymentMethod == 'Nakit',
                      selectedColor: Colors.amber.shade100,
                      onSelected: (selected) {
                        if (selected) setState(() => _paymentMethod = 'Nakit');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selection Dropdown + Add New
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: categories.any((c) => c.name == _category) ? _category : null,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.name,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _category = val);
                        }
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Kategori seçiniz' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    tooltip: 'Yeni Kategori Ekle',
                    onPressed: () => _showAddCategoryDialog(financeProvider),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Selector
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tarih',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    dateFormat.format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note Input
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Not (İsteğe Bağlı)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'gider' ? Colors.red.shade700 : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  isEditing ? 'Değişiklikleri Kaydet' : 'İşlemi Kaydet',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/fuel_entry_model.dart';
import '../providers/fuel_provider.dart';
import '../providers/finance_provider.dart';

class AddEditFuelEntryScreen extends StatefulWidget {
  final FuelEntryModel? fuelEntry;

  const AddEditFuelEntryScreen({super.key, this.fuelEntry});

  @override
  State<AddEditFuelEntryScreen> createState() => _AddEditFuelEntryScreenState();
}

class _AddEditFuelEntryScreenState extends State<AddEditFuelEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late String _paymentMethod;

  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _stationNoteController = TextEditingController();

  bool get isEditing => widget.fuelEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.fuelEntry;
    if (entry != null) {
      _selectedDate = entry.date;
      _paymentMethod = entry.paymentMethod;
      _odometerController.text = entry.odometerKm.toString();
      _litersController.text = entry.liters.toString();
      _totalCostController.text = entry.totalCost.toString();
      _stationNoteController.text = entry.stationNote ?? '';
    } else {
      _selectedDate = DateTime.now();
      _paymentMethod = 'Banka';
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _litersController.dispose();
    _totalCostController.dispose();
    _stationNoteController.dispose();
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

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    final newEntry = FuelEntryModel(
      id: widget.fuelEntry?.id,
      date: _selectedDate,
      odometerKm: double.parse(_odometerController.text.replaceAll(',', '.')),
      liters: double.parse(_litersController.text.replaceAll(',', '.')),
      totalCost: double.parse(_totalCostController.text.replaceAll(',', '.')),
      stationNote: _stationNoteController.text.trim().isEmpty ? null : _stationNoteController.text.trim(),
      paymentMethod: _paymentMethod,
    );

    if (isEditing) {
      await fuelProvider.updateFuelEntry(newEntry, financeProvider);
    } else {
      await fuelProvider.addFuelEntry(newEntry, financeProvider);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy', 'tr_TR');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Yakıt Kaydını Düzenle' : 'Yeni Yakıt Kaydı'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Kaydı Sil',
              onPressed: () async {
                final entryId = widget.fuelEntry!.id!;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Yakıt Kaydını Sil'),
                    content: const Text('Bu yakıt kaydını ve bağlı harcamayı silmek istediğinize emin misiniz?'),
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
                  final fProvider = Provider.of<FuelProvider>(context, listen: false);
                  final finProvider = Provider.of<FinanceProvider>(context, listen: false);
                  await fProvider.deleteFuelEntry(entryId, finProvider);
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
              // Kilometre (Odometer Reading) Input
              TextFormField(
                controller: _odometerController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Araç Kilometresi (km)',
                  prefixIcon: const Icon(Icons.speed),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: 'km',
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Kilometre giriniz';
                  final p = double.tryParse(value.replaceAll(',', '.'));
                  if (p == null || p < 0) return 'Geçerli bir kilometre giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Liters Input
              TextFormField(
                controller: _litersController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Alınan Yakıt (Litre)',
                  prefixIcon: const Icon(Icons.local_gas_station),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: 'L',
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Litre miktarını giriniz';
                  final p = double.tryParse(value.replaceAll(',', '.'));
                  if (p == null || p <= 0) return 'Geçerli bir litre giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total Cost Input
              TextFormField(
                controller: _totalCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Toplam Ödenen Tutar (₺)',
                  prefixIcon: const Icon(Icons.payments),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: '₺',
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Toplam tutarı giriniz';
                  final p = double.tryParse(value.replaceAll(',', '.'));
                  if (p == null || p <= 0) return 'Geçerli bir tutar giriniz';
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
                        child: Text('Banka (Bakiye Düşer)', style: TextStyle(fontWeight: FontWeight.bold)),
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

              // Date Picker
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

              // Station / Note Input
              TextFormField(
                controller: _stationNoteController,
                decoration: InputDecoration(
                  labelText: 'İstasyon / Not (İsteğe Bağlı)',
                  prefixIcon: const Icon(Icons.location_on),
                  hintText: 'Örn. Shell, Opet vb.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.local_gas_station),
                label: Text(
                  isEditing ? 'Kaydı Güncelle' : 'Yakıt Kaydını Ekle',
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

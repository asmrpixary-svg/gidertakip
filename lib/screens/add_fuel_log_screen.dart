import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fuel_log_model.dart';
import '../providers/app_provider.dart';
import '../utils/formatters.dart';

class AddFuelLogScreen extends StatefulWidget {
  const AddFuelLogScreen({super.key});

  @override
  State<AddFuelLogScreen> createState() => _AddFuelLogScreenState();
}

class _AddFuelLogScreenState extends State<AddFuelLogScreen> {
  final _formKey = GlobalKey<FormState>();

  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _stationNoteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'bank'; // 'bank' or 'cash'

  @override
  void initState() {
    super.initState();
    // Pre-fill odometer from latest fuel log if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.fuelLogs.isNotEmpty) {
        final lastOdometer = provider.fuelLogs.last.odometerKm;
        _odometerController.text = (lastOdometer + 500).toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _litersController.dispose();
    _totalCostController.dispose();
    _stationNoteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final odometer = double.parse(_odometerController.text.replaceAll(',', '.'));
    final liters = double.parse(_litersController.text.replaceAll(',', '.'));
    final totalCost = double.parse(_totalCostController.text.replaceAll(',', '.'));
    final stationNote = _stationNoteController.text.trim().isEmpty ? null : _stationNoteController.text.trim();

    final provider = Provider.of<AppProvider>(context, listen: false);

    final fuelLog = FuelLog(
      date: _selectedDate,
      odometerKm: odometer,
      liters: liters,
      totalCost: totalCost,
      stationNote: stationNote,
    );

    provider.addFuelLog(fuelLog, paymentMethod: _paymentMethod);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yakıt kaydı ve ilgili gider başarıyla eklendi.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakıt Alımı Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tarih',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(Formatters.formatDate(_selectedDate)),
                ),
              ),

              const SizedBox(height: 16),

              // Odometer (Km)
              TextFormField(
                controller: _odometerController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Mevcut Kilometre (km)',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                  hintText: 'Örn: 125000',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Kilometre giriniz';
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Geçerli kilometre giriniz';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Liters (Litre)
              TextFormField(
                controller: _litersController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Alınan Yakıt (Litre)',
                  prefixIcon: Icon(Icons.local_gas_station),
                  border: OutlineInputBorder(),
                  hintText: 'Örn: 45.5',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Litre giriniz';
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Geçerli litre giriniz';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Total Cost (Toplam Tutar TL)
              TextFormField(
                controller: _totalCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Toplam Tutar (TL)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  hintText: 'Örn: 1850.00',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Tutar giriniz';
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Geçerli tutar giriniz';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Payment Method Choice
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ödeme Yöntemi (Banka ise bakiyeden düşer)',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Banka'),
                              value: 'bank',
                              groupValue: _paymentMethod,
                              onChanged: (val) {
                                if (val != null) setState(() => _paymentMethod = val);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Nakit'),
                              value: 'cash',
                              groupValue: _paymentMethod,
                              onChanged: (val) {
                                if (val != null) setState(() => _paymentMethod = val);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Station / Note
              TextFormField(
                controller: _stationNoteController,
                decoration: const InputDecoration(
                  labelText: 'İstasyon / Not (İsteğe bağlı)',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  hintText: 'Örn: Opet / Uzun Yol',
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Yakıt Kaydını Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

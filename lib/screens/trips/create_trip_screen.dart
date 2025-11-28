import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/models/trips/trip.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/providers/trips/trip_provider.dart';
import 'package:smart_travel_app/screens/trips/trip_detail/trip_detail_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _startingLocationController = TextEditingController();
  final _budgetLimitController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 10));
  TripBudgetLevel _budgetLevel = TripBudgetLevel.moderate;
  int _travelers = 2;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _startingLocationController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime.now() : _startDate;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (newDate == null) return;
    setState(() {
      if (isStart) {
        _startDate = newDate;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = newDate.isBefore(_startDate)
            ? _startDate.add(const Duration(days: 1))
            : newDate;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<UserProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để tạo kế hoạch')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final tripProvider = context.read<TripProvider>();
    final now = DateTime.now();
    final newTrip = Trip(
      userId: user.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      startingLocation: _startingLocationController.text.trim().isEmpty
          ? null
          : _startingLocationController.text.trim(),
      numberOfTravelers: _travelers,
      budgetLevel: _budgetLevel,
      budgetLimit: _budgetLimitController.text.trim().isEmpty
          ? null
          : double.tryParse(_budgetLimitController.text.trim()),
      createdAt: now,
      updatedAt: now,
    );

    try {
      final tripId = await tripProvider.createTrip(newTrip);
      if (!mounted) return;
      if (tripId != null) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(tripId: tripId),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo kế hoạch mới')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên kế hoạch *',
                    hintText: 'Ví dụ: Khám phá Đà Nẵng 4 ngày',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên kế hoạch';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Thông tin ngắn gọn về chuyến đi',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateSelector(
                        label: 'Ngày bắt đầu',
                        value: dateFormat.format(_startDate),
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateSelector(
                        label: 'Ngày kết thúc',
                        value: dateFormat.format(_endDate),
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Địa điểm chính',
                    hintText: 'Ví dụ: Đà Nẵng - Hội An',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startingLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Điểm xuất phát',
                    hintText: 'Ví dụ: Hà Nội',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _travelers,
                        decoration:
                            const InputDecoration(labelText: 'Số người tham gia'),
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1} người'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _travelers = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TripBudgetLevel>(
                        value: _budgetLevel,
                        decoration:
                            const InputDecoration(labelText: 'Mức chi tiêu'),
                        items: TripBudgetLevel.values
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(level.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _budgetLevel = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budgetLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Ngân sách tối đa (VND)',
                    hintText: 'Ví dụ: 15000000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Đang lưu...' : 'Tạo kế hoạch'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}


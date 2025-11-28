import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/models/trips/trip.dart';
import 'package:smart_travel_app/providers/trips/trip_provider.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';

class EditTripScreen extends StatefulWidget {
  final String tripId;
  final Trip trip;

  const EditTripScreen({super.key, required this.tripId, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _startingLocationController;
  late final TextEditingController _budgetLimitController;

  late DateTime _startDate;
  late DateTime _endDate;
  late TripBudgetLevel _budgetLevel;
  late int _numberOfTravelers;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _nameController = TextEditingController(text: trip.name);
    _descriptionController = TextEditingController(
      text: trip.description ?? '',
    );
    _locationController = TextEditingController(text: trip.location ?? '');
    _startingLocationController = TextEditingController(
      text: trip.startingLocation ?? '',
    );
    _budgetLimitController = TextEditingController(
      text: trip.budgetLimit != null
          ? trip.budgetLimit!.toStringAsFixed(0)
          : '',
    );
    _startDate = trip.startDate;
    _endDate = trip.endDate;
    _budgetLevel = trip.budgetLevel;
    _numberOfTravelers = trip.numberOfTravelers;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _startingLocationController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc phải sau hoặc bằng ngày bắt đầu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final tripProvider = context.read<TripProvider>();

    if (!userProvider.isLoggedIn || userProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập lại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final startingLocation = _startingLocationController.text.trim();
    final budgetLimitRaw = _budgetLimitController.text.trim();
    final budgetLimit = budgetLimitRaw.isNotEmpty
        ? double.tryParse(budgetLimitRaw.replaceAll(',', ''))
        : null;

    final updates = <String, dynamic>{
      'name': name,
      'description': description.isEmpty ? null : description,
      'location': location.isEmpty ? null : location,
      'startingLocation': startingLocation,
      'startDate': Timestamp.fromDate(_startDate),
      'endDate': Timestamp.fromDate(_endDate),
      'numberOfTravelers': _numberOfTravelers,
      'budgetLevel': _budgetLevel.toValue(),
      'budgetLimit': budgetLimit,
    };

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = userProvider.user!.uid;
      await tripProvider.updateTrip(userId, widget.tripId, updates);
      await tripProvider.setCurrentTrip(userId, widget.tripId);
      tripProvider.resetCostMultiplier();
      await tripProvider.estimateCost(userId, widget.tripId);
      await tripProvider.loadWeatherForecasts(userId, widget.tripId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật chuyến đi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa kế hoạch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên chuyến đi *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên chuyến đi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm chính',
                  hintText: 'VD: Hà Nội, Đà Nẵng...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startingLocationController,
                decoration: const InputDecoration(
                  labelText: 'Điểm xuất phát *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập điểm xuất phát';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày bắt đầu',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(dateFormat.format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày kết thúc',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(dateFormat.format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Số ngày: ${_endDate.difference(_startDate).inDays + 1}',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Số người tham gia:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _numberOfTravelers > 1
                        ? () {
                            setState(() {
                              _numberOfTravelers--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_numberOfTravelers',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _numberOfTravelers++;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Loại hình du lịch:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ...TripBudgetLevel.values.map(
                (level) => RadioListTile<TripBudgetLevel>(
                  title: Text(level.displayName),
                  value: level,
                  groupValue: _budgetLevel,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _budgetLevel = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget giới hạn (VND)',
                  prefixText: '₫ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

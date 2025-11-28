import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../providers/user_provider.dart';
import '../models/trip.dart';
import 'add_destinations_to_trip_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetLimitController = TextEditingController();
  final _startingLocationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _numberOfTravelers = 1;
  TripBudgetLevel _budgetLevel = TripBudgetLevel.moderate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetLimitController.dispose();
    _startingLocationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Nếu endDate < startDate, reset endDate
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu trước')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final tripProvider = context.read<TripProvider>();

    if (!userProvider.isLoggedIn || userProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    final trip = Trip(
      userId: userProvider.user!.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      startingLocation: _startingLocationController.text.trim(),
      numberOfTravelers: _numberOfTravelers,
      budgetLevel: _budgetLevel,
      budgetLimit: _budgetLimitController.text.trim().isNotEmpty
          ? double.tryParse(_budgetLimitController.text.trim().replaceAll(',', ''))
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final tripId = await tripProvider.createTrip(trip);

    if (tripId != null && mounted) {
      // Navigate to add destinations screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddDestinationsToTripScreen(
            tripId: tripId,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo kế hoạch mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên kế hoạch
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên kế hoạch *',
                  hintText: 'VD: Du lịch Hà Nội 3 ngày',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên kế hoạch';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Mô tả
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả về chuyến đi của bạn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Ngày bắt đầu
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày bắt đầu *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? dateFormat.format(_startDate!)
                        : 'Chọn ngày',
                    style: TextStyle(
                      color: _startDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Ngày kết thúc
              InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày kết thúc *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endDate != null
                        ? dateFormat.format(_endDate!)
                        : 'Chọn ngày',
                    style: TextStyle(
                      color: _endDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Số ngày: ${_endDate!.difference(_startDate!).inDays + 1} ngày',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Điểm xuất phát
              TextFormField(
                controller: _startingLocationController,
                decoration: const InputDecoration(
                  labelText: 'Điểm xuất phát *',
                  hintText: 'VD: Hà Nội, TP. Hồ Chí Minh, Đà Nẵng...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'Thành phố/địa điểm bạn sẽ bắt đầu chuyến đi',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập điểm xuất phát để tính chi phí di chuyển';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Số người tham gia
              Row(
                children: [
                  const Text(
                    'Số người tham gia:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (_numberOfTravelers > 1) {
                        setState(() {
                          _numberOfTravelers--;
                        });
                      }
                    },
                  ),
                  Text(
                    '$_numberOfTravelers',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _numberOfTravelers++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Loại du lịch
              const Text(
                'Loại du lịch:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...TripBudgetLevel.values.map((level) {
                return RadioListTile<TripBudgetLevel>(
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
                );
              }),
              const SizedBox(height: 16),
              // Budget giới hạn (optional)
              TextFormField(
                controller: _budgetLimitController,
                decoration: const InputDecoration(
                  labelText: 'Budget giới hạn (VND)',
                  hintText: 'VD: 5000000',
                  border: OutlineInputBorder(),
                  prefixText: '₫ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              // Nút tạo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tiếp theo: Thêm điểm đến',
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


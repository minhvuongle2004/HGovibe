import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../providers/user_provider.dart';
import '../models/trip_item.dart';

class EditTripItemScreen extends StatefulWidget {
  final String tripId;
  final TripItem item;

  const EditTripItemScreen({
    super.key,
    required this.tripId,
    required this.item,
  });

  @override
  State<EditTripItemScreen> createState() => _EditTripItemScreenState();
}

class _EditTripItemScreenState extends State<EditTripItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime? _plannedDate;
  TimeOfDay? _plannedTime;
  int _durationHours = 2;

  @override
  void initState() {
    super.initState();
    _plannedDate = widget.item.plannedDate;
    _plannedTime = widget.item.plannedTime;
    _durationHours = widget.item.durationHours ?? 2;
    _notesController.text = widget.item.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _plannedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _plannedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _plannedTime = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_plannedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày')),
      );
      return;
    }

    if (_plannedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ dự kiến')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final tripProvider = context.read<TripProvider>();

    if (!userProvider.isLoggedIn || userProvider.user == null) {
      return;
    }

    final conflict = tripProvider.findScheduleConflict(
      plannedDate: _plannedDate!,
      plannedTime: _plannedTime!,
      durationHours: _durationHours,
      excludeItemId: widget.item.id,
    );

    if (conflict != null) {
      final conflictDestination = conflict.destination?.name ?? 'điểm đến khác';
      final conflictTime = conflict.plannedTime != null
          ? _formatTime(conflict.plannedTime!)
          : '';
      final conflictDuration = conflict.durationHours ?? 2;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Khoảng thời gian đã trùng với "$conflictDestination" '
            'lúc $conflictTime (dự kiến $conflictDuration giờ). '
            'Vui lòng chọn thời gian khác.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await tripProvider.updateTripItem(
        userProvider.user!.uid,
        widget.tripId,
        widget.item.id!,
        {
          'plannedDate': _plannedDate,
          'plannedTime': _plannedTime != null
              ? '${_plannedTime!.hour.toString().padLeft(2, '0')}:${_plannedTime!.minute.toString().padLeft(2, '0')}'
              : null,
          'durationHours': _durationHours,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa điểm đến?'),
        content: Text(
          'Bạn có chắc muốn xóa "${widget.item.destination?.name ?? 'điểm đến này'}" khỏi kế hoạch?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userProvider = context.read<UserProvider>();
      final tripProvider = context.read<TripProvider>();

      if (userProvider.user != null && widget.item.id != null) {
        try {
          await tripProvider.removeDestinationFromTrip(
            userProvider.user!.uid,
            widget.tripId,
            widget.item.id!,
          );

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa điểm đến')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final destination = widget.item.destination;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa điểm đến'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteItem,
            tooltip: 'Xóa điểm đến',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination info card
              if (destination != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        if (destination.thumbnail.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              destination.thumbnail,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image, size: 60),
                            ),
                          )
                        else
                          const Icon(Icons.place, size: 60),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                destination.location.city,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Ngày dự kiến
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày dự kiến *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _plannedDate != null
                        ? dateFormat.format(_plannedDate!)
                        : 'Chọn ngày',
                    style: TextStyle(
                      color: _plannedDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Giờ dự kiến (optional)
              InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Giờ dự kiến (tùy chọn)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _plannedTime != null
                        ? '${_plannedTime!.hour.toString().padLeft(2, '0')}:${_plannedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Chọn giờ',
                    style: TextStyle(
                      color: _plannedTime != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Thời gian dự kiến (giờ)
              Row(
                children: [
                  const Text(
                    'Thời gian dự kiến:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (_durationHours > 1) {
                        setState(() {
                          _durationHours--;
                        });
                      }
                    },
                  ),
                  Text(
                    '$_durationHours giờ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _durationHours++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Ghi chú
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Thêm ghi chú cho điểm đến này...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              // Nút lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
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

  String _formatTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}


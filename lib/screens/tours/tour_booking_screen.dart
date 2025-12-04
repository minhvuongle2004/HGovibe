import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/models/tours/participant_info.dart';
import 'package:smart_travel_app/models/tours/contact_info.dart';
import 'package:smart_travel_app/screens/tours/tour_booking_confirm_screen.dart';

/// Screen đặt tour với form đầy đủ
class TourBookingScreen extends StatefulWidget {
  final TourPackage tour;

  const TourBookingScreen({
    super.key,
    required this.tour,
  });

  @override
  State<TourBookingScreen> createState() => _TourBookingScreenState();
}

class _TourBookingScreenState extends State<TourBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Ngày khởi hành
  DateTime? _selectedDepartureDate;

  // Số người
  int _numberOfAdults = 1;
  int _numberOfChildren = 0;
  int _numberOfInfants = 0;

  // Thông tin người tham gia
  final List<ParticipantInfo> _participants = [];

  // Thông tin liên hệ
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactAddressController = TextEditingController();

  // Yêu cầu đặc biệt
  final _specialRequestsController = TextEditingController();

  // Tính giá
  double _subtotal = 0.0;
  double _totalAmount = 0.0;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Lấy thông tin user hiện tại nếu đã đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _contactEmailController.text = user.email ?? '';
    }
    // Khởi tạo participants list
    _updateParticipantsList();
    // Tính giá ban đầu
    _calculatePrice();
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactAddressController.dispose();
    _specialRequestsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Tính giá tự động
  void _calculatePrice() {
    final totalPeople = _numberOfAdults + _numberOfChildren + _numberOfInfants;
    
    if (totalPeople == 0) {
      setState(() {
        _subtotal = 0.0;
        _totalAmount = 0.0;
      });
      return;
    }

    double adultPrice = widget.tour.basePrice;
    double childPrice = widget.tour.childPrice ?? widget.tour.basePrice;
    double infantPrice = widget.tour.infantPrice ?? 0.0;

    // Kiểm tra price tiers
    if (widget.tour.priceTiers.isNotEmpty) {
      for (var tier in widget.tour.priceTiers) {
        if (tier.matches(totalPeople)) {
          adultPrice = tier.pricePerPerson;
          // Giả sử child price = 80% adult price nếu không có childPrice trong tier
          childPrice = widget.tour.childPrice ?? (adultPrice * 0.8);
          break;
        }
      }
    }

    // Tính tổng
    final adultTotal = adultPrice * _numberOfAdults;
    final childTotal = childPrice * _numberOfChildren;
    final infantTotal = infantPrice * _numberOfInfants;

    setState(() {
      _subtotal = adultTotal + childTotal + infantTotal;
      _totalAmount = _subtotal; // Chưa có discount
    });
  }

  /// Chọn ngày khởi hành
  Future<void> _selectDepartureDate() async {
    // Kiểm tra availableDates có rỗng không
    if (widget.tour.availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tour này chưa có ngày khởi hành khả dụng')),
      );
      return;
    }

    final now = DateTime.now();
    final availableDatesOnly = widget.tour.availableDates
        .where((date) => date.isAfter(now.subtract(const Duration(days: 1))))
        .toList();

    if (availableDatesOnly.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có ngày khởi hành khả dụng')),
      );
      return;
    }

    final firstDate = now.isAfter(availableDatesOnly.first)
        ? now
        : availableDatesOnly.first;
    final lastDate = availableDatesOnly.last.add(const Duration(days: 365));

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDepartureDate ?? availableDatesOnly.first,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) {
        // Chỉ cho phép chọn các ngày có sẵn
        return availableDatesOnly.any((availableDate) =>
            date.year == availableDate.year &&
            date.month == availableDate.month &&
            date.day == availableDate.day);
      },
      helpText: 'Chọn ngày khởi hành',
      locale: const Locale('vi', 'VN'),
    );

    if (selected != null) {
      setState(() {
        _selectedDepartureDate = selected;
      });
    }
  }

  /// Cập nhật số người và tính lại giá
  void _updatePeopleCount(String type, int delta) {
    setState(() {
      switch (type) {
        case 'adults':
          _numberOfAdults = (_numberOfAdults + delta).clamp(1, widget.tour.maxGroupSize);
          break;
        case 'children':
          _numberOfChildren = (_numberOfChildren + delta).clamp(0, widget.tour.maxGroupSize);
          break;
        case 'infants':
          _numberOfInfants = (_numberOfInfants + delta).clamp(0, widget.tour.maxGroupSize);
          break;
      }
      
      // Kiểm tra tổng số người không vượt quá maxGroupSize
      final total = _numberOfAdults + _numberOfChildren + _numberOfInfants;
      if (total > widget.tour.maxGroupSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số người tối đa là ${widget.tour.maxGroupSize}'),
          ),
        );
        return;
      }
      
      // Cập nhật danh sách participants
      _updateParticipantsList();
      _calculatePrice();
    });
  }

  /// Cập nhật danh sách participants theo số người
  void _updateParticipantsList() {
    final totalPeople = _numberOfAdults + _numberOfChildren + _numberOfInfants;
    
    // Thêm participants nếu thiếu
    while (_participants.length < totalPeople) {
      _participants.add(ParticipantInfo(fullName: ''));
    }
    
    // Xóa participants thừa
    while (_participants.length > totalPeople) {
      _participants.removeLast();
    }
  }

  /// Validate form
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedDepartureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày khởi hành')),
      );
      return false;
    }

    if (_numberOfAdults + _numberOfChildren + _numberOfInfants == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 người')),
      );
      return false;
    }

    // Validate participants
    for (var i = 0; i < _participants.length; i++) {
      if (_participants[i].fullName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng nhập tên người tham gia ${i + 1}')),
        );
        return false;
      }
    }

    return true;
  }

  /// Tiếp tục đến màn hình xác nhận
  void _continueToConfirm() {
    if (!_validateForm()) {
      return;
    }

    final contactInfo = ContactInfo(
      fullName: _contactNameController.text.trim(),
      email: _contactEmailController.text.trim(),
      phoneNumber: _contactPhoneController.text.trim(),
      address: _contactAddressController.text.trim().isEmpty
          ? null
          : _contactAddressController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourBookingConfirmScreen(
          tour: widget.tour,
          departureDate: _selectedDepartureDate!,
          numberOfAdults: _numberOfAdults,
          numberOfChildren: _numberOfChildren,
          numberOfInfants: _numberOfInfants,
          participants: List.from(_participants),
          contactInfo: contactInfo,
          specialRequests: _specialRequestsController.text.trim().isEmpty
              ? null
              : _specialRequestsController.text.trim(),
          subtotal: _subtotal,
          totalAmount: _totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPeople = _numberOfAdults + _numberOfChildren + _numberOfInfants;
    final canProceed = _selectedDepartureDate != null && totalPeople > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt tour'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tour info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tour.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.tour.destination,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.tour.durationDays} ngày ${widget.tour.durationNights} đêm',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Chọn ngày khởi hành
                    _buildSectionTitle('Chọn ngày khởi hành'),
                    const SizedBox(height: 8),
                    Card(
                      child: InkWell(
                        onTap: _selectDepartureDate,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.orange),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _selectedDepartureDate != null
                                      ? _dateFormat.format(_selectedDepartureDate!)
                                      : 'Chọn ngày khởi hành',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDepartureDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Chọn số người
                    _buildSectionTitle('Số người tham gia'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildPeopleSelector(
                              'Người lớn',
                              _numberOfAdults,
                              (delta) => _updatePeopleCount('adults', delta),
                              required: true,
                            ),
                            if (widget.tour.childPrice != null) ...[
                              const Divider(),
                              _buildPeopleSelector(
                                'Trẻ em',
                                _numberOfChildren,
                                (delta) => _updatePeopleCount('children', delta),
                              ),
                            ],
                            if (widget.tour.infantPrice != null) ...[
                              const Divider(),
                              _buildPeopleSelector(
                                'Em bé',
                                _numberOfInfants,
                                (delta) => _updatePeopleCount('infants', delta),
                              ),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng số người:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$totalPeople người',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Giá ước tính
                    if (canProceed) ...[
                      _buildSectionTitle('Giá ước tính'),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildPriceRow('Người lớn', _numberOfAdults, widget.tour.basePrice),
                              if (_numberOfChildren > 0 && widget.tour.childPrice != null)
                                _buildPriceRow(
                                  'Trẻ em',
                                  _numberOfChildren,
                                  widget.tour.childPrice!,
                                ),
                              if (_numberOfInfants > 0 && widget.tour.infantPrice != null)
                                _buildPriceRow(
                                  'Em bé',
                                  _numberOfInfants,
                                  widget.tour.infantPrice!,
                                ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tổng tiền:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###').format(_totalAmount)} ${widget.tour.currency}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Thông tin người tham gia
                    if (totalPeople > 0) ...[
                      _buildSectionTitle('Thông tin người tham gia'),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // Đảm bảo participants list được cập nhật
                          if (_participants.length != totalPeople) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _updateParticipantsList();
                            });
                          }
                          // Đảm bảo có đủ participants trước khi render
                          if (_participants.length < totalPeople) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Column(
                            children: List.generate(totalPeople, (index) {
                              // Kiểm tra index hợp lệ
                              if (index >= _participants.length) {
                                return const SizedBox.shrink();
                              }
                              return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Người ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Họ tên *',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: _participants[index].fullName,
                                  onChanged: (value) {
                                    _participants[index] = ParticipantInfo(
                                      fullName: value,
                                      dateOfBirth: _participants[index].dateOfBirth,
                                      gender: _participants[index].gender,
                                      nationality: _participants[index].nationality,
                                      passportNumber: _participants[index].passportNumber,
                                      phoneNumber: _participants[index].phoneNumber,
                                      email: _participants[index].email,
                                    );
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập họ tên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Ngày sinh',
                                          border: OutlineInputBorder(),
                                          suffixIcon: Icon(Icons.calendar_today),
                                        ),
                                        readOnly: true,
                                        controller: TextEditingController(
                                          text: _participants[index].dateOfBirth != null
                                              ? _dateFormat.format(_participants[index].dateOfBirth!)
                                              : '',
                                        ),
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _participants[index].dateOfBirth ??
                                                DateTime.now().subtract(const Duration(days: 365 * 25)),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                            locale: const Locale('vi', 'VN'),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              _participants[index] = ParticipantInfo(
                                                fullName: _participants[index].fullName,
                                                dateOfBirth: date,
                                                gender: _participants[index].gender,
                                                nationality: _participants[index].nationality,
                                                passportNumber: _participants[index].passportNumber,
                                                phoneNumber: _participants[index].phoneNumber,
                                                email: _participants[index].email,
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Giới tính',
                                          border: OutlineInputBorder(),
                                        ),
                                        value: _participants[index].gender,
                                        items: const [
                                          DropdownMenuItem(value: 'male', child: Text('Nam')),
                                          DropdownMenuItem(value: 'female', child: Text('Nữ')),
                                          DropdownMenuItem(value: 'other', child: Text('Khác')),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _participants[index] = ParticipantInfo(
                                              fullName: _participants[index].fullName,
                                              dateOfBirth: _participants[index].dateOfBirth,
                                              gender: value,
                                              nationality: _participants[index].nationality,
                                              passportNumber: _participants[index].passportNumber,
                                              phoneNumber: _participants[index].phoneNumber,
                                              email: _participants[index].email,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Số điện thoại',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  initialValue: _participants[index].phoneNumber,
                                  onChanged: (value) {
                                    _participants[index] = ParticipantInfo(
                                      fullName: _participants[index].fullName,
                                      dateOfBirth: _participants[index].dateOfBirth,
                                      gender: _participants[index].gender,
                                      nationality: _participants[index].nationality,
                                      passportNumber: _participants[index].passportNumber,
                                      phoneNumber: value,
                                      email: _participants[index].email,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Thông tin liên hệ
                    _buildSectionTitle('Thông tin liên hệ'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _contactNameController,
                              decoration: const InputDecoration(
                                labelText: 'Họ tên người đặt *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập họ tên';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _contactEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!value.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _contactPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _contactAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Địa chỉ',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Yêu cầu đặc biệt
                    _buildSectionTitle('Yêu cầu đặc biệt (tùy chọn)'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _specialRequestsController,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú, yêu cầu đặc biệt...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom bar với nút tiếp tục
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canProceed)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tổng tiền:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###').format(_totalAmount)} ${widget.tour.currency}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _continueToConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Tiếp tục',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Vui lòng chọn ngày khởi hành và số người',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPeopleSelector(
    String label,
    int count,
    Function(int) onChanged, {
    bool required = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: const TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: count > (required ? 1 : 0) ? () => onChanged(-1) : null,
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int quantity, double price) {
    if (quantity == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label x $quantity'),
          Text(
            '${NumberFormat('#,###').format(price * quantity)} ${widget.tour.currency}',
          ),
        ],
      ),
    );
  }
}

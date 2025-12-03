import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/tours/cancellation_policy.dart';
import '../../models/tours/price_tier.dart';
import '../../models/tours/tour_activity.dart';
import '../../models/tours/tour_exclusions.dart';
import '../../models/tours/tour_inclusions.dart';
import '../../models/tours/tour_itinerary_day.dart';
import '../../models/tours/tour_package.dart';
import '../../services/storage/imgbb_upload_service.dart';
import '../../services/tours/admin_tour_service.dart';

class TourFormScreen extends StatefulWidget {
  final String? tourId;

  const TourFormScreen({super.key, this.tourId});

  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends State<TourFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tourService = AdminTourService.instance;
  final _imageService = ImgBBUploadService.instance;

  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationController = TextEditingController();
  final _destinationsController = TextEditingController();
  final _languageController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _providerIdController = TextEditingController();
  final _providerNameController = TextEditingController(text: 'In-house');
  final _providerTypeController = TextEditingController(text: 'app');

  final _basePriceController = TextEditingController();
  final _childPriceController = TextEditingController();
  final _infantPriceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'VND');
  final _minGroupController = TextEditingController(text: '1');
  final _maxGroupController = TextEditingController(text: '20');

  final _notesController = TextEditingController();

  int _durationDays = 1;
  int _durationNights = 0;

  TourStatus _status = TourStatus.active;
  TourType _tourType = TourType.group;
  PriceType _priceType = PriceType.perPerson;
  bool _featured = false;

  List<String> _images = [];
  String? _thumbnail;
  bool _isUploadingImages = false;
  final Map<int, double> _uploadProgress = {};

  List<DateTime> _availableDates = [];
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  List<PriceTierFormData> _priceTiers = [];
  List<ItineraryDayFormData> _itineraryDays = [];
  List<CancellationRuleFormData> _cancellationRules = [];

  bool _isLoading = false;
  bool _isSaving = false;
  DateTime? _createdAt;
  double _rating = 0;
  int _reviewCount = 0;
  int _bookingCount = 0;
  int _viewCount = 0;

  @override
  void initState() {
    super.initState();
    _initDefaults();

    if (widget.tourId != null) {
      _loadTour();
    }
  }

  void _initDefaults() {
    _priceTiers = [
      PriceTierFormData(),
    ];

    _itineraryDays = [
      ItineraryDayFormData(dayNumber: 1),
    ];

    _cancellationRules = [
      CancellationRuleFormData(),
    ];

    _availableDates = [];
  }

  Future<void> _loadTour() async {
    setState(() => _isLoading = true);
    try {
      final tour = await _tourService.getTourById(widget.tourId!);
      if (tour == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy tour')),
          );
          context.pop();
        }
        return;
      }

      _titleController.text = tour.title;
      _shortDescriptionController.text = tour.shortDescription;
      _descriptionController.text = tour.description;
      _destinationController.text = tour.destination;
      _destinationsController.text = tour.destinations.join(', ');
      _languageController.text = tour.language ?? '';
      _pickupController.text = tour.pickupLocation ?? '';
      _dropoffController.text = tour.dropoffLocation ?? '';
      _providerIdController.text = tour.providerId;
      _providerNameController.text = tour.providerName;
      _providerTypeController.text = tour.providerType;
      _durationDays = tour.durationDays;
      _durationNights = tour.durationNights;

      _basePriceController.text = tour.basePrice.toString();
      _childPriceController.text =
          tour.childPrice != null ? tour.childPrice.toString() : '';
      _infantPriceController.text =
          tour.infantPrice != null ? tour.infantPrice.toString() : '';
      _currencyController.text = tour.currency;
      _minGroupController.text = tour.minGroupSize.toString();
      _maxGroupController.text = tour.maxGroupSize.toString();

      _status = tour.status;
      _tourType = tour.type;
      _priceType = tour.priceType;
      _featured = tour.featured;

      _images = List<String>.from(tour.images);
      _thumbnail = tour.thumbnail;

      _availableDates = List<DateTime>.from(tour.availableDates);
      _createdAt = tour.createdAt;
      _rating = tour.rating;
      _reviewCount = tour.reviewCount;
      _bookingCount = tour.bookingCount;
      _viewCount = tour.viewCount;

      _priceTiers = tour.priceTiers
          .map((tier) => PriceTierFormData(
                minPeople: tier.minPeople.toString(),
                maxPeople: tier.maxPeople?.toString() ?? '',
                price: tier.pricePerPerson.toString(),
              ))
          .toList();
      if (_priceTiers.isEmpty) {
        _priceTiers.add(PriceTierFormData());
      }

      _itineraryDays = tour.itinerary
          .map((day) => ItineraryDayFormData.fromModel(day))
          .toList();
      if (_itineraryDays.isEmpty) {
        _itineraryDays.add(ItineraryDayFormData(dayNumber: 1));
      }

      _cancellationRules = tour.cancellationPolicy.rules
          .map((rule) => CancellationRuleFormData.fromModel(rule))
          .toList();
      if (_cancellationRules.isEmpty) {
        _cancellationRules.add(CancellationRuleFormData());
      }
      _notesController.text = tour.cancellationPolicy.notes ?? '';
      _inclusionControllers.populate(tour.inclusions);
      _exclusionControllers.populate(tour.exclusions);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải tour: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _destinationController.dispose();
    _destinationsController.dispose();
    _languageController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _providerIdController.dispose();
    _providerNameController.dispose();
    _providerTypeController.dispose();
    _basePriceController.dispose();
    _childPriceController.dispose();
    _infantPriceController.dispose();
    _currencyController.dispose();
    _minGroupController.dispose();
    _maxGroupController.dispose();
    _notesController.dispose();

    for (final tier in _priceTiers) {
      tier.dispose();
    }
    for (final day in _itineraryDays) {
      day.dispose();
    }
    for (final rule in _cancellationRules) {
      rule.dispose();
    }
    _inclusionControllers.dispose();
    _exclusionControllers.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) return;

    final files = result.files.where((file) => file.bytes != null).toList();
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy dữ liệu ảnh')),
      );
      return;
    }

    setState(() {
      _isUploadingImages = true;
      _uploadProgress.clear();
    });

    try {
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final Uint8List bytes = file.bytes!;

        final url = await _imageService.uploadImage(
          imageBytes: bytes,
          fileName: file.name,
          folder: widget.tourId ?? 'temp',
          onProgress: (progress) {
            setState(() {
              _uploadProgress[i] = progress;
            });
          },
        );

        _images.add(url);
        _thumbnail ??= url;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi upload ảnh: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImages = false;
        _uploadProgress.clear();
      });
    }
  }

  void _removeImage(String imageUrl) {
    setState(() {
      _images.remove(imageUrl);
      if (_thumbnail == imageUrl) {
        _thumbnail = _images.isNotEmpty ? _images.first : null;
      }
    });
  }

  void _setThumbnail(String imageUrl) {
    setState(() {
      _thumbnail = imageUrl;
    });
  }

  void _addAvailableDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _availableDates.add(picked);
        _availableDates.sort();
      });
    }
  }

  void _removeAvailableDate(DateTime date) {
    setState(() {
      _availableDates.remove(date);
    });
  }

  void _addPriceTier() {
    setState(() {
      _priceTiers.add(PriceTierFormData());
    });
  }

  void _removePriceTier(int index) {
    setState(() {
      if (_priceTiers.length > 1) {
        final tier = _priceTiers.removeAt(index);
        tier.dispose();
      }
    });
  }

  void _addItineraryDay() {
    setState(() {
      _itineraryDays.add(
        ItineraryDayFormData(dayNumber: _itineraryDays.length + 1),
      );
    });
  }

  void _removeItineraryDay(int index) {
    setState(() {
      if (_itineraryDays.length > 1) {
        final day = _itineraryDays.removeAt(index);
        day.dispose();
      }
    });
  }

  void _addCancellationRule() {
    setState(() {
      _cancellationRules.add(CancellationRuleFormData());
    });
  }

  void _removeCancellationRule(int index) {
    setState(() {
      if (_cancellationRules.length > 1) {
        final rule = _cancellationRules.removeAt(index);
        rule.dispose();
      }
    });
  }

  Future<void> _saveTour() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra lại thông tin')),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng upload ít nhất 1 hình ảnh')),
      );
      return;
    }

    if (_availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ngày khởi hành')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final tour = _buildTourFromForm();

      if (widget.tourId == null) {
        final newId = await _tourService.createTour(tour);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo tour mới (ID: $newId)')),
        );
      } else {
        await _tourService.updateTour(tour);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tour')),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu tour thất bại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  TourPackage _buildTourFromForm() {
    final now = DateTime.now();
    final destinations = _destinationsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (destinations.isEmpty) {
      destinations.add(_destinationController.text.trim());
    }

    final priceTiers = _priceTiers
        .where((tier) => tier.isValid)
        .map((tier) => PriceTier(
              minPeople: int.parse(tier.minPeopleController.text),
              maxPeople: tier.maxPeopleController.text.isEmpty
                  ? null
                  : int.tryParse(tier.maxPeopleController.text),
              pricePerPerson: double.parse(tier.priceController.text),
            ))
        .toList();

    final itinerary = _itineraryDays.map((day) => day.toModel()).toList();

    final cancellationPolicy = CancellationPolicy(
      type: 'custom',
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      rules: _cancellationRules
          .where((rule) => rule.isValid)
          .map((rule) => rule.toModel())
          .toList(),
    );

    return TourPackage(
      id: widget.tourId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      shortDescription: _shortDescriptionController.text.trim(),
      images: _images,
      thumbnail: _thumbnail ?? _images.first,
      destination: _destinationController.text.trim(),
      destinations: destinations,
      durationDays: _durationDays,
      durationNights: _durationNights,
      availableDates: _availableDates,
      basePrice: double.parse(_basePriceController.text),
      childPrice: _childPriceController.text.isEmpty
          ? null
          : double.parse(_childPriceController.text),
      infantPrice: _infantPriceController.text.isEmpty
          ? null
          : double.parse(_infantPriceController.text),
      priceType: _priceType,
      priceTiers: priceTiers,
      currency: _currencyController.text.trim(),
      itinerary: itinerary,
      inclusions: _buildInclusions(),
      exclusions: _buildExclusions(),
      cancellationPolicy: cancellationPolicy,
      termsAndConditions: null,
      type: _tourType,
      maxGroupSize: int.tryParse(_maxGroupController.text) ?? 20,
      minGroupSize: int.tryParse(_minGroupController.text) ?? 1,
      language:
          _languageController.text.trim().isEmpty ? null : _languageController.text.trim(),
      pickupLocation: _pickupController.text.trim().isEmpty
          ? null
          : _pickupController.text.trim(),
      dropoffLocation: _dropoffController.text.trim().isEmpty
          ? null
          : _dropoffController.text.trim(),
      rating: _rating,
      reviewCount: _reviewCount,
      bookingCount: _bookingCount,
      viewCount: _viewCount,
      status: _status,
      featured: _featured,
      createdAt: _createdAt ?? now,
      updatedAt: now,
      providerId: _providerIdController.text.trim().isEmpty
          ? 'admin'
          : _providerIdController.text.trim(),
      providerName: _providerNameController.text.trim().isEmpty
          ? 'Admin'
          : _providerNameController.text.trim(),
      providerType: _providerTypeController.text.trim().isEmpty
          ? 'app'
          : _providerTypeController.text.trim(),
    );
  }

  TourInclusions _buildInclusions() {
    return TourInclusions(
      transportation: _splitInput(
        _inclusionControllers.transportationController.text,
      ),
      accommodation: _splitInput(
        _inclusionControllers.accommodationController.text,
      ),
      meals: _splitInput(_inclusionControllers.mealsController.text),
      activities: _splitInput(_inclusionControllers.activitiesController.text),
      other: _splitInput(_inclusionControllers.otherController.text),
    );
  }

  TourExclusions _buildExclusions() {
    return TourExclusions(
      meals: _splitInput(_exclusionControllers.mealsController.text),
      activities: _splitInput(_exclusionControllers.activitiesController.text),
      other: _splitInput(_exclusionControllers.otherController.text),
    );
  }

  List<String> _splitInput(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
  }

  final _inclusionControllers = InclusionFormControllers();
  final _exclusionControllers = ExclusionFormControllers();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tourId == null ? 'Tạo tour mới' : 'Chỉnh sửa tour'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Thông tin chính'),
                  Tab(text: 'Hình ảnh'),
                  Tab(text: 'Giá & nhóm'),
                  Tab(text: 'Lịch trình'),
                  Tab(text: 'Chính sách'),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: TabBarView(
                  children: [
                    _buildBasicInfoTab(),
                    _buildImagesTab(),
                    _buildPricingTab(),
                    _buildItineraryTab(),
                    _buildPolicyTab(),
                  ],
                ),
              ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTour,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu tour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cơ bản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tên tour *',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên tour';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shortDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô tả ngắn *',
            ),
            maxLines: 2,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô tả chi tiết *',
            ),
            maxLines: 5,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Điểm đến chính *',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _destinationsController,
                  decoration: const InputDecoration(
                    labelText: 'Các điểm đến khác (phân tách bằng dấu phẩy)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TourType>(
                  value: _tourType,
                  decoration: const InputDecoration(labelText: 'Loại tour'),
                  items: const [
                    DropdownMenuItem(
                      value: TourType.group,
                      child: Text('Tour nhóm'),
                    ),
                    DropdownMenuItem(
                      value: TourType.private,
                      child: Text('Tour riêng'),
                    ),
                    DropdownMenuItem(
                      value: TourType.selfGuided,
                      child: Text('Tự túc'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _tourType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<TourStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const [
                    DropdownMenuItem(
                      value: TourStatus.active,
                      child: Text('Đang hoạt động'),
                    ),
                    DropdownMenuItem(
                      value: TourStatus.inactive,
                      child: Text('Tạm dừng'),
                    ),
                    DropdownMenuItem(
                      value: TourStatus.soldOut,
                      child: Text('Hết chỗ'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Số ngày *',
                  value: _durationDays,
                  onChanged: (value) =>
                      setState(() => _durationDays = value.clamp(1, 60)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  label: 'Số đêm *',
                  value: _durationNights,
                  onChanged: (value) =>
                      setState(() => _durationNights = value.clamp(0, 59)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _languageController,
                  decoration: const InputDecoration(labelText: 'Ngôn ngữ'),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Đánh dấu nổi bật'),
                  const SizedBox(width: 8),
                  Switch(
                    value: _featured,
                    onChanged: (value) {
                      setState(() => _featured = value);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pickupController,
                  decoration: const InputDecoration(labelText: 'Điểm đón'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _dropoffController,
                  decoration: const InputDecoration(labelText: 'Điểm trả'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Thông tin đối tác',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _providerIdController,
                  decoration: const InputDecoration(labelText: 'Provider ID'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _providerNameController,
                  decoration: const InputDecoration(labelText: 'Tên đối tác'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _providerTypeController,
                  decoration: const InputDecoration(labelText: 'Loại đối tác'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hình ảnh tour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: _isUploadingImages ? null : _pickImages,
                icon: const Icon(Icons.upload),
                label: Text(_isUploadingImages ? 'Đang upload...' : 'Upload ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_images.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Chưa có hình ảnh nào. Vui lòng upload tối thiểu 1 ảnh.',
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _images.map((img) => _buildImageCard(img)).toList(),
            ),
          if (_isUploadingImages) ...[
            const SizedBox(height: 16),
            ..._uploadProgress.entries.map(
              (entry) => LinearProgressIndicator(value: entry.value),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Ngày khởi hành',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._availableDates.map(
                (date) => Chip(
                  label: Text(_dateFormat.format(date)),
                  onDeleted: () => _removeAvailableDate(date),
                ),
              ),
              ActionChip(
                label: const Text('Thêm ngày'),
                avatar: const Icon(Icons.add),
                onPressed: _addAvailableDate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    final isThumbnail = _thumbnail == imageUrl;
    return Stack(
      children: [
        Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Row(
            children: [
              if (!isThumbnail)
                IconButton(
                  onPressed: () => _setThumbnail(imageUrl),
                  icon: const Icon(Icons.star_outline, color: Colors.white),
                  tooltip: 'Đặt làm thumbnail',
                )
              else
                const Icon(Icons.star, color: Colors.amber),
              IconButton(
                onPressed: () => _removeImage(imageUrl),
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Xóa ảnh',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin giá',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _basePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá cơ bản *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bắt buộc';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Giá không hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _childPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá trẻ em'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _infantPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá em bé'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PriceType>(
                  value: _priceType,
                  decoration: const InputDecoration(labelText: 'Loại giá'),
                  items: const [
                    DropdownMenuItem(
                      value: PriceType.perPerson,
                      child: Text('Theo người'),
                    ),
                    DropdownMenuItem(
                      value: PriceType.perRoom,
                      child: Text('Theo phòng'),
                    ),
                    DropdownMenuItem(
                      value: PriceType.perGroup,
                      child: Text('Theo nhóm'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priceType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Đơn vị tiền tệ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minGroupController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min group size'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _maxGroupController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max group size'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price tiers',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _addPriceTier,
                icon: const Icon(Icons.add),
                label: const Text('Thêm tier'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              for (int i = 0; i < _priceTiers.length; i++)
                _buildPriceTierCard(i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTierCard(int index) {
    final tier = _priceTiers[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: tier.minPeopleController,
                    decoration:
                        const InputDecoration(labelText: 'Số người tối thiểu'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: tier.maxPeopleController,
                    decoration: const InputDecoration(
                        labelText: 'Số người tối đa (optional)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: tier.priceController,
                    decoration:
                        const InputDecoration(labelText: 'Giá mỗi người'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _removePriceTier(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch trình tour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _addItineraryDay,
                icon: const Icon(Icons.add),
                label: const Text('Thêm ngày'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (int i = 0; i < _itineraryDays.length; i++)
                _buildItineraryDayCard(i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryDayCard(int index) {
    final day = _itineraryDays[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Ngày ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeItineraryDay(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: day.titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: day.descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: day.accommodationController,
              decoration:
                  const InputDecoration(labelText: 'Chỗ ở (nếu có)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: day.mealsController,
              decoration: const InputDecoration(
                  labelText: 'Các bữa ăn (phân tách dấu phẩy)'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      day.activities.add(ActivityFormData());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm hoạt động'),
                ),
              ],
            ),
            Column(
              children: [
                for (int i = 0; i < day.activities.length; i++)
                  _buildActivityRow(day, i),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(ItineraryDayFormData day, int index) {
    final activity = day.activities[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: activity.timeController,
              decoration: const InputDecoration(labelText: 'Thời gian'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: activity.nameController,
              decoration: const InputDecoration(labelText: 'Hoạt động'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: activity.descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                final removed = day.activities.removeAt(index);
                removed.dispose();
                if (day.activities.isEmpty) {
                  day.activities.add(ActivityFormData());
                }
              });
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bao gồm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildMultiLineField(
            controller: _inclusionControllers.transportationController,
            label: 'Vận chuyển',
          ),
          const SizedBox(height: 8),
          _buildMultiLineField(
            controller: _inclusionControllers.accommodationController,
            label: 'Chỗ ở',
          ),
          const SizedBox(height: 8),
          _buildMultiLineField(
            controller: _inclusionControllers.mealsController,
            label: 'Bữa ăn',
          ),
          const SizedBox(height: 8),
          _buildMultiLineField(
            controller: _inclusionControllers.activitiesController,
            label: 'Hoạt động',
          ),
          const SizedBox(height: 8),
          _buildMultiLineField(
            controller: _inclusionControllers.otherController,
            label: 'Khác',
          ),
          const SizedBox(height: 24),
          const Text(
            'Không bao gồm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildMultiLineField(
            controller: _exclusionControllers.mealsController,
            label: 'Bữa ăn',
          ),
          const SizedBox(height: 8),
          _buildMultiLineField(
            controller: _exclusionControllers.activitiesController,
            label: 'Hoạt động',
          ),
          const SizedBox(height: 8),
          _buildMultiLineField(
            controller: _exclusionControllers.otherController,
            label: 'Khác',
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chính sách hủy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _addCancellationRule,
                icon: const Icon(Icons.add),
                label: const Text('Thêm quy tắc'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (int i = 0; i < _cancellationRules.length; i++)
                _buildCancellationRuleCard(i),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Ghi chú'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationRuleCard(int index) {
    final rule = _cancellationRules[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: rule.daysBeforeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số ngày trước khởi hành',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: rule.refundController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '% hoàn tiền'),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeCancellationRule(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: rule.descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiLineField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: 2,
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              onPressed: value > 0
                  ? () => onChanged(value - 1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}

class PriceTierFormData {
  final TextEditingController minPeopleController;
  final TextEditingController maxPeopleController;
  final TextEditingController priceController;

  PriceTierFormData({
    String minPeople = '',
    String maxPeople = '',
    String price = '',
  })  : minPeopleController = TextEditingController(text: minPeople),
        maxPeopleController = TextEditingController(text: maxPeople),
        priceController = TextEditingController(text: price);

  bool get isValid =>
      minPeopleController.text.isNotEmpty && priceController.text.isNotEmpty;

  void dispose() {
    minPeopleController.dispose();
    maxPeopleController.dispose();
    priceController.dispose();
  }
}

class ItineraryDayFormData {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController accommodationController;
  final TextEditingController mealsController;
  final List<ActivityFormData> activities;
  int dayNumber;

  ItineraryDayFormData({
    required this.dayNumber,
    String title = '',
    String description = '',
    String accommodation = '',
    String meals = '',
    List<ActivityFormData>? activities,
  })  : titleController = TextEditingController(text: title),
        descriptionController = TextEditingController(text: description),
        accommodationController = TextEditingController(text: accommodation),
        mealsController = TextEditingController(text: meals),
        activities = activities ?? [ActivityFormData()];

  factory ItineraryDayFormData.fromModel(TourItineraryDay day) {
    final activities = day.activities
        .map((activity) => ActivityFormData.fromModel(activity))
        .toList();
    if (activities.isEmpty) {
      activities.add(ActivityFormData());
    }
    return ItineraryDayFormData(
      dayNumber: day.dayNumber,
      title: day.title,
      description: day.description,
      accommodation: day.accommodation ?? '',
      meals: day.meals.join(', '),
      activities: activities,
    );
  }

  TourItineraryDay toModel() {
    final meals = mealsController.text
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();

    final activityModels = activities
        .where((activity) => activity.nameController.text.isNotEmpty)
        .map((activity) => activity.toModel())
        .toList();

    return TourItineraryDay(
      dayNumber: dayNumber,
      title: titleController.text.trim().isEmpty
          ? 'Ngày $dayNumber'
          : titleController.text.trim(),
      description: descriptionController.text.trim(),
      activities: activityModels,
      meals: meals,
      accommodation: accommodationController.text.trim().isEmpty
          ? null
          : accommodationController.text.trim(),
    );
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    accommodationController.dispose();
    mealsController.dispose();
    for (final activity in activities) {
      activity.dispose();
    }
  }
}

class ActivityFormData {
  final TextEditingController timeController;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  ActivityFormData({
    String time = '',
    String name = '',
    String description = '',
  })  : timeController = TextEditingController(text: time),
        nameController = TextEditingController(text: name),
        descriptionController = TextEditingController(text: description);

  factory ActivityFormData.fromModel(TourActivity activity) {
    return ActivityFormData(
      time: activity.time,
      name: activity.name,
      description: activity.description ?? '',
    );
  }

  TourActivity toModel() {
    return TourActivity(
      time: timeController.text.trim(),
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
    );
  }

  void dispose() {
    timeController.dispose();
    nameController.dispose();
    descriptionController.dispose();
  }
}

class CancellationRuleFormData {
  final TextEditingController daysBeforeController;
  final TextEditingController refundController;
  final TextEditingController descriptionController;

  CancellationRuleFormData({
    String daysBefore = '',
    String refund = '',
    String description = '',
  })  : daysBeforeController = TextEditingController(text: daysBefore),
        refundController = TextEditingController(text: refund),
        descriptionController = TextEditingController(text: description);

  factory CancellationRuleFormData.fromModel(CancellationRule rule) {
    return CancellationRuleFormData(
      daysBefore: rule.daysBeforeDeparture.toString(),
      refund: rule.refundPercentage.toString(),
      description: rule.description,
    );
  }

  bool get isValid =>
      daysBeforeController.text.isNotEmpty &&
      refundController.text.isNotEmpty &&
      descriptionController.text.isNotEmpty;

  CancellationRule toModel() {
    return CancellationRule(
      daysBeforeDeparture: int.tryParse(daysBeforeController.text) ?? 0,
      refundPercentage: int.tryParse(refundController.text) ?? 0,
      description: descriptionController.text.trim(),
    );
  }

  void dispose() {
    daysBeforeController.dispose();
    refundController.dispose();
    descriptionController.dispose();
  }
}

class InclusionFormControllers {
  final transportationController = TextEditingController();
  final accommodationController = TextEditingController();
  final mealsController = TextEditingController();
  final activitiesController = TextEditingController();
  final otherController = TextEditingController();

  void populate(TourInclusions inclusions) {
    transportationController.text = inclusions.transportation.join(', ');
    accommodationController.text = inclusions.accommodation.join(', ');
    mealsController.text = inclusions.meals.join(', ');
    activitiesController.text = inclusions.activities.join(', ');
    otherController.text = inclusions.other.join(', ');
  }

  void dispose() {
    transportationController.dispose();
    accommodationController.dispose();
    mealsController.dispose();
    activitiesController.dispose();
    otherController.dispose();
  }
}

class ExclusionFormControllers {
  final mealsController = TextEditingController();
  final activitiesController = TextEditingController();
  final otherController = TextEditingController();

  void populate(TourExclusions exclusions) {
    mealsController.text = exclusions.meals.join(', ');
    activitiesController.text = exclusions.activities.join(', ');
    otherController.text = exclusions.other.join(', ');
  }

  void dispose() {
    mealsController.dispose();
    activitiesController.dispose();
    otherController.dispose();
  }
}


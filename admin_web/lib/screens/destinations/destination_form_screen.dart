import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/destinations/destination.dart';
import '../../services/destinations/admin_destination_service.dart';
import '../../services/storage/imgbb_upload_service.dart';

/// Screen tạo/sửa destination
class DestinationFormScreen extends StatefulWidget {
  final String? destinationId;

  const DestinationFormScreen({
    super.key,
    this.destinationId,
  });

  @override
  State<DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationService = AdminDestinationService.instance;
  final _imageUploadService = ImgBBUploadService.instance;
  
  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _isUploadingImages = false;
  Map<int, double> _uploadProgress = {}; // Index -> progress (0.0 to 1.0)

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _entranceFeeController = TextEditingController();
  final _suggestedDurationController = TextEditingController();
  
  String _selectedCategory = 'attraction';
  String _status = 'active';
  List<String> _images = [];
  String? _thumbnail;
  List<String> _tags = [];
  List<String> _tips = [];
  List<String> _suitableFor = [];
  double _rating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.destinationId != null) {
      _loadDestination();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shortDescriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _entranceFeeController.dispose();
    _suggestedDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadDestination() async {
    if (widget.destinationId == null) return;
    
    setState(() => _isLoadingData = true);
    try {
      print('🔍 Loading destination: ${widget.destinationId}');
      final destination = await _destinationService.getDestinationById(widget.destinationId!);
      
      if (destination == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy destination')),
          );
          context.pop();
        }
        return;
      }

      print('✅ Destination loaded: ${destination.name}');
      
      // Validate category - nếu không có trong danh sách, fallback về 'attraction'
      final validCategories = const [
        'attraction', 'restaurant', 'hotel', 'entertainment', 'shopping',
        'nature', 'culture', 'adventure', 'heritage', 'architecture',
        'museum', 'history', 'island', 'ecotourism', 'eco-tourism',
        'spiritual', 'temple',
      ];
      final category = validCategories.contains(destination.category)
          ? destination.category
          : 'attraction';
      
      setState(() {
        _nameController.text = destination.name;
        _descriptionController.text = destination.description;
        _shortDescriptionController.text = destination.shortDescription;
        _addressController.text = destination.location.address;
        _cityController.text = destination.location.city;
        _districtController.text = destination.location.district;
        _latitudeController.text = destination.location.latitude.toString();
        _longitudeController.text = destination.location.longitude.toString();
        _entranceFeeController.text = destination.entranceFee?.toString() ?? '';
        _suggestedDurationController.text = destination.suggestedDuration;
        _selectedCategory = category;
        _status = destination.status;
        _images = List.from(destination.images);
        _thumbnail = destination.thumbnail.isNotEmpty ? destination.thumbnail : (destination.images.isNotEmpty ? destination.images.first : '');
        _tags = List.from(destination.tags);
        _tips = List.from(destination.tips);
        _suitableFor = List.from(destination.suitableFor);
        _rating = destination.rating;
        _reviewCount = destination.reviewCount;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading destination: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải destination: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveDestination() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse coordinates (đã validate ở form nên sẽ không null)
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      
      final location = Location(
        latitude: latitude,
        longitude: longitude,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        country: 'Vietnam',
      );

      final destination = Destination(
        id: widget.destinationId,
        name: _nameController.text.trim(),
        nameLowercase: _nameController.text.trim().toLowerCase(),
        slug: _nameController.text.trim().toLowerCase().replaceAll(' ', '-'),
        category: _selectedCategory,
        tags: _tags,
        location: location,
        description: _descriptionController.text.trim(),
        shortDescription: _shortDescriptionController.text.trim(),
        images: _images,
        thumbnail: _thumbnail ?? (_images.isNotEmpty ? _images.first : ''),
        rating: _rating,
        reviewCount: _reviewCount,
        popularityScore: 0,
        bestMonths: [],
        seasonalEvents: [],
        specialties: [],
        activities: [],
        tips: _tips,
        nearbyPlaces: [],
        entranceFee: _entranceFeeController.text.trim().isNotEmpty 
            ? int.parse(_entranceFeeController.text.trim()) 
            : null,
        suggestedDuration: _suggestedDurationController.text.trim(),
        suggestedDurationHours: 2, // Default
        weatherDependent: false,
        suitableFor: _suitableFor,
        status: _status,
        verified: false,
        visitCount: 0,
        trendingScore: 0,
        userPreferenceTags: [],
      );

      final data = destination.toMap();
      
      if (widget.destinationId == null) {
        await _destinationService.createDestination(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo destination thành công!')),
          );
        }
      } else {
        await _destinationService.updateDestination(widget.destinationId!, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật destination thành công!')),
          );
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu destination: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destinationId == null ? 'Thêm điểm đến mới' : 'Sửa điểm đến'),
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveDestination,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              _buildSectionTitle('Thông tin cơ bản'),
              _buildTextField(
                controller: _nameController,
                label: 'Tên điểm đến *',
                hint: 'Nhập tên điểm đến',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên điểm đến';
                  }
                  if (value.trim().length < 3) {
                    return 'Tên điểm đến phải có ít nhất 3 ký tự';
                  }
                  if (value.trim().length > 200) {
                    return 'Tên điểm đến không được vượt quá 200 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _shortDescriptionController,
                label: 'Mô tả ngắn *',
                hint: 'Mô tả ngắn gọn về điểm đến (50-200 ký tự)',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả ngắn';
                  }
                  if (value.trim().length < 50) {
                    return 'Mô tả ngắn phải có ít nhất 50 ký tự';
                  }
                  if (value.trim().length > 200) {
                    return 'Mô tả ngắn không được vượt quá 200 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả chi tiết *',
                hint: 'Mô tả chi tiết về điểm đến (tối thiểu 100 ký tự)',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả chi tiết';
                  }
                  if (value.trim().length < 100) {
                    return 'Mô tả chi tiết phải có ít nhất 100 ký tự';
                  }
                  if (value.trim().length > 5000) {
                    return 'Mô tả chi tiết không được vượt quá 5000 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Category & Status
              Row(
                children: [
                  Expanded(
                    child:                     _buildDropdown<String>(
                      label: 'Danh mục *',
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'attraction', child: Text('Điểm tham quan')),
                        DropdownMenuItem(value: 'restaurant', child: Text('Nhà hàng')),
                        DropdownMenuItem(value: 'hotel', child: Text('Khách sạn')),
                        DropdownMenuItem(value: 'entertainment', child: Text('Giải trí')),
                        DropdownMenuItem(value: 'shopping', child: Text('Mua sắm')),
                        DropdownMenuItem(value: 'nature', child: Text('Thiên nhiên')),
                        DropdownMenuItem(value: 'culture', child: Text('Văn hóa')),
                        DropdownMenuItem(value: 'adventure', child: Text('Phiêu lưu')),
                        DropdownMenuItem(value: 'heritage', child: Text('Di sản')),
                        DropdownMenuItem(value: 'architecture', child: Text('Kiến trúc')),
                        DropdownMenuItem(value: 'museum', child: Text('Bảo tàng')),
                        DropdownMenuItem(value: 'history', child: Text('Lịch sử')),
                        DropdownMenuItem(value: 'island', child: Text('Đảo')),
                        DropdownMenuItem(value: 'ecotourism', child: Text('Du lịch sinh thái')),
                        DropdownMenuItem(value: 'eco-tourism', child: Text('Du lịch sinh thái (alt)')),
                        DropdownMenuItem(value: 'spiritual', child: Text('Tâm linh')),
                        DropdownMenuItem(value: 'temple', child: Text('Đền chùa')),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown<String>(
                      label: 'Trạng thái',
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Location Section
              _buildSectionTitle('Vị trí'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'Thành phố *',
                      hint: 'Nhập thành phố',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập thành phố';
                        }
                        if (value.trim().length < 2) {
                          return 'Tên thành phố phải có ít nhất 2 ký tự';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _districtController,
                      label: 'Quận/Huyện',
                      hint: 'Nhập quận/huyện',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ *',
                hint: 'Nhập địa chỉ chi tiết',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  if (value.trim().length < 10) {
                    return 'Địa chỉ phải có ít nhất 10 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latitudeController,
                      label: 'Vĩ độ (Latitude) *',
                      hint: 'Ví dụ: 10.772461',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập vĩ độ';
                        }
                        final lat = double.tryParse(value.trim());
                        if (lat == null) {
                          return 'Vĩ độ phải là số';
                        }
                        if (lat < -90 || lat > 90) {
                          return 'Vĩ độ phải nằm trong khoảng -90 đến 90';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _longitudeController,
                      label: 'Kinh độ (Longitude) *',
                      hint: 'Ví dụ: 106.698055',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập kinh độ';
                        }
                        final lng = double.tryParse(value.trim());
                        if (lng == null) {
                          return 'Kinh độ phải là số';
                        }
                        if (lng < -180 || lng > 180) {
                          return 'Kinh độ phải nằm trong khoảng -180 đến 180';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Additional Info
              _buildSectionTitle('Thông tin bổ sung'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _entranceFeeController,
                      label: 'Phí vào cửa (VNĐ)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final fee = int.tryParse(value.trim());
                          if (fee == null) {
                            return 'Phí vào cửa phải là số';
                          }
                          if (fee < 0) {
                            return 'Phí vào cửa không được âm';
                          }
                          if (fee > 100000000) {
                            return 'Phí vào cửa không được vượt quá 100,000,000 VNĐ';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _suggestedDurationController,
                      label: 'Thời gian gợi ý',
                      hint: 'Ví dụ: 2-3 giờ',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Images Section
              _buildSectionTitle('Hình ảnh'),
              _buildImagesSection(),
              SizedBox(height: 24),

              // Tags Section
              _buildSectionTitle('Tags'),
              _buildTagInput(
                label: 'Tags',
                tags: _tags,
                onChanged: (tags) => setState(() => _tags = tags),
              ),
              SizedBox(height: 16),
              _buildTagInput(
                label: 'Suitable For',
                tags: _suitableFor,
                onChanged: (tags) => setState(() => _suitableFor = tags),
              ),
              SizedBox(height: 16),
              _buildTagInput(
                label: 'Tips',
                tags: _tips,
                onChanged: (tags) => setState(() => _tips = tags),
              ),
              SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDestination,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildTagInput({
    required String label,
    required List<String> tags,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () => onChanged(tags.where((t) => t != tag).toList()),
            )),
            ActionChip(
              label: Text('+ Thêm'),
              onPressed: () {
                final controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Thêm $label'),
                    content: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Nhập $label',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !tags.contains(value)) {
                          onChanged([...tags, value]);
                        }
                        Navigator.pop(context);
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          final value = controller.text.trim();
                          if (value.isNotEmpty && !tags.contains(value)) {
                            onChanged([...tags, value]);
                          }
                          Navigator.pop(context);
                        },
                        child: Text('Thêm'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        ElevatedButton.icon(
          onPressed: _isUploadingImages ? null : _pickAndUploadImages,
          icon: _isUploadingImages
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.upload),
          label: Text(_isUploadingImages ? 'Đang tải lên...' : 'Chọn hình ảnh'),
        ),
        SizedBox(height: 16),
        
        // Images grid
        if (_images.isEmpty)
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Chưa có hình ảnh nào. Nhấn "Chọn hình ảnh" để thêm.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final imageUrl = _images[index];
              final isThumbnail = _thumbnail == imageUrl;
              final uploadProgress = _uploadProgress[index];
              
              return Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.error),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),
                  
                  // Upload progress overlay
                  if (uploadProgress != null && uploadProgress < 1.0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: uploadProgress,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  
                  // Thumbnail badge
                  if (isThumbnail)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Thumbnail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Actions overlay
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showImageActions(context, index),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isThumbnail
                                ? Border.all(color: Colors.orange, width: 3)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Delete button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.all(4),
                        minimumSize: Size(24, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _deleteImage(index),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploadingImages = true;
        _uploadProgress = {};
      });

      final imageBytesList = <Uint8List>[];
      for (var file in result.files) {
        if (file.bytes != null) {
          imageBytesList.add(file.bytes!);
        }
      }

      if (imageBytesList.isEmpty) {
        setState(() => _isUploadingImages = false);
        return;
      }

      // Generate base file name từ destination name hoặc ID
      final baseFileName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim().toLowerCase().replaceAll(' ', '_')
          : widget.destinationId ?? 'destination';

      // Upload images
      final urls = await _imageUploadService.uploadImages(
        imageBytesList: imageBytesList,
        baseFileName: baseFileName,
        folder: widget.destinationId,
        onProgress: (index, progress) {
          setState(() {
            _uploadProgress[_images.length + index] = progress;
          });
        },
      );

      setState(() {
        _images.addAll(urls);
        // Set first image as thumbnail nếu chưa có
        if (_thumbnail == null || _thumbnail!.isEmpty) {
          _thumbnail = urls.first;
        }
        _isUploadingImages = false;
        _uploadProgress = {};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tải lên ${urls.length} hình ảnh thành công')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
        _uploadProgress = {};
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lên hình ảnh: $e')),
        );
      }
    }
  }

  void _deleteImage(int index) {
    if (index < 0 || index >= _images.length) return;

    final imageUrl = _images[index];
    final wasThumbnail = _thumbnail == imageUrl;

    setState(() {
      _images.removeAt(index);
      if (wasThumbnail) {
        _thumbnail = _images.isNotEmpty ? _images.first : null;
      }
    });

    // Delete from Firebase Storage (async, không block UI)
    _imageUploadService.deleteImage(imageUrl).catchError((e) {
      print('Error deleting image from storage: $e');
    });
  }

  void _showImageActions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Đặt làm thumbnail'),
              onTap: () {
                setState(() {
                  _thumbnail = _images[index];
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã đặt làm thumbnail')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Xóa hình ảnh', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteImage(index);
              },
            ),
          ],
        ),
      ),
    );
  }
}
